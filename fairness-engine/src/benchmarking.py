"""
FairTerms Fairness Engine - Benchmarking pipeline.

Peer comparison engine that finds similar SMEs and computes benchmark
statistics. Supports both local CSV and BigQuery modes.
"""

from __future__ import annotations

import os
from typing import Optional

import numpy as np
import pandas as pd

from src.models import BenchmarkResult, SMEProfile, TermsDistribution
from src.utils import (
    compute_fairness_score,
    get_state_code,
    is_bigquery_enabled,
    is_metro_pincode,
    logger,
)

_dataset: Optional[pd.DataFrame] = None

REVENUE_TOLERANCE = 0.5

# Validate BigQuery env vars at module load; fall back to CSV mode if any
# are missing.
_BIGQUERY_VARS = ("GCP_PROJECT_ID", "BIGQUERY_DATASET", "BIGQUERY_TABLE")
_bigquery_ready: bool = False
if is_bigquery_enabled():
    _missing = [v for v in _BIGQUERY_VARS if not os.getenv(v)]
    if _missing:
        logger.warning(
            "BigQuery env vars missing: %s. Falling back to CSV peer data.",
            ", ".join(_missing),
        )
    else:
        _bigquery_ready = True
EMPLOYEE_TOLERANCE = 0.6


def normalize_dataset_schema(df: pd.DataFrame) -> pd.DataFrame:
    """Upgrade older seed CSVs in memory to the stage-2 schema."""
    normalized = df.copy()

    if "pincode" in normalized.columns:
        normalized["pincode"] = normalized["pincode"].astype(str).str.zfill(6)

    if "is_metro" not in normalized.columns:
        if "pincode" in normalized.columns:
            normalized["is_metro"] = normalized["pincode"].apply(
                is_metro_pincode
            )
        else:
            normalized["is_metro"] = False
    else:
        normalized["is_metro"] = (
            normalized["is_metro"]
            .astype(str)
            .str.lower()
            .isin(["true", "1", "yes"])
        )

    if (
        "state_code" not in normalized.columns
        and "state" in normalized.columns
    ):
        normalized["state_code"] = (
            normalized["state"].fillna("").apply(get_state_code)
        )

    if "buyer_name" not in normalized.columns:
        if "buyer_type" in normalized.columns:
            normalized["buyer_name"] = normalized["buyer_type"].fillna(
                "Unknown Buyer"
            )
        else:
            normalized["buyer_name"] = "Unknown Buyer"

    if (
        "fairness_score" not in normalized.columns
        and "payment_terms_days" in normalized.columns
    ):
        normalized["fairness_score"] = normalized["payment_terms_days"].apply(
            lambda value: compute_fairness_score(int(value))
        )

    return normalized


def load_dataset(path: str | None = None) -> pd.DataFrame:
    """Load and cache the benchmark dataset."""
    global _dataset

    if _dataset is not None:
        return _dataset

    csv_path = path or os.getenv("SEED_DATA_PATH", "data/seed_data.csv")
    logger.info("Loading benchmark dataset from: %s", csv_path)

    if not os.path.exists(csv_path):
        logger.warning(
            "Dataset not found at %s - generating seed data...", csv_path
        )
        from src.seed_data import generate_seed_data, save_seed_data

        record_count = int(os.getenv("SEED_RECORD_COUNT", "1000"))
        dataframe = generate_seed_data(record_count)
        save_seed_data(dataframe, csv_path)
        _dataset = normalize_dataset_schema(dataframe)
    else:
        _dataset = normalize_dataset_schema(pd.read_csv(csv_path))
        logger.info("Loaded %s records from CSV", len(_dataset))

    return _dataset


def get_dataset() -> pd.DataFrame:
    """Get the cached dataset, loading it if necessary."""
    if _dataset is None:
        return load_dataset()
    return _dataset


def find_peers(
    sme_profile: SMEProfile,
    dataset: pd.DataFrame | None = None,
    min_peers: int = 20,
) -> pd.DataFrame:
    """Find similar SME peers using progressively relaxed matching."""
    df = dataset if dataset is not None else get_dataset()

    revenue = sme_profile.annual_revenue_inr
    employees = sme_profile.employee_count
    industry = sme_profile.industry

    rev_low = revenue * (1 - REVENUE_TOLERANCE)
    rev_high = revenue * (1 + REVENUE_TOLERANCE)
    emp_low = max(1, int(employees * (1 - EMPLOYEE_TOLERANCE)))
    emp_high = int(employees * (1 + EMPLOYEE_TOLERANCE))

    peers = df[
        (df["industry"] == industry)
        & (df["annual_revenue_inr"] >= rev_low)
        & (df["annual_revenue_inr"] <= rev_high)
        & (df["employee_count"] >= emp_low)
        & (df["employee_count"] <= emp_high)
    ]
    if len(peers) >= min_peers:
        logger.info(
            "L1 match: %s peers (industry + revenue + employees)", len(peers)
        )
        return peers

    peers = df[
        (df["industry"] == industry)
        & (df["annual_revenue_inr"] >= rev_low)
        & (df["annual_revenue_inr"] <= rev_high)
    ]
    if len(peers) >= min_peers:
        logger.info("L2 match: %s peers (industry + revenue)", len(peers))
        return peers

    peers = df[df["industry"] == industry]
    if len(peers) >= min_peers:
        logger.info("L3 match: %s peers (industry only)", len(peers))
        return peers

    logger.warning("Fallback: using all %s records as peers", len(df))
    return df


def find_peers_bigquery(sme_profile: SMEProfile) -> pd.DataFrame:
    """Query BigQuery for peer SMEs. Falls back to CSV if not ready."""
    if not _bigquery_ready:
        logger.warning("BigQuery not ready — falling back to CSV peer data.")
        return find_peers(sme_profile)

    from google.cloud import bigquery

    project = os.getenv("GCP_PROJECT_ID")
    dataset_id = os.getenv("BIGQUERY_DATASET", "fairterms")
    table_id = os.getenv("BIGQUERY_TABLE", "benchmarks")
    full_table = f"{project}.{dataset_id}.{table_id}"

    client = bigquery.Client(project=project)
    revenue = sme_profile.annual_revenue_inr
    rev_low = revenue * (1 - REVENUE_TOLERANCE)
    rev_high = revenue * (1 + REVENUE_TOLERANCE)

    query = f"""
        SELECT *
        FROM `{full_table}`
        WHERE industry = @industry
          AND annual_revenue_inr BETWEEN @rev_low AND @rev_high
        LIMIT 500
    """

    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter(
                "industry", "STRING", sme_profile.industry
            ),
            bigquery.ScalarQueryParameter("rev_low", "FLOAT64", rev_low),
            bigquery.ScalarQueryParameter("rev_high", "FLOAT64", rev_high),
        ]
    )

    logger.info("Querying BigQuery: %s", full_table)
    dataframe = client.query(query, job_config=job_config).to_dataframe()
    dataframe = normalize_dataset_schema(dataframe)
    logger.info("BigQuery returned %s peers", len(dataframe))
    return dataframe


def compute_benchmark(
    peers: pd.DataFrame, payment_terms_days: int
) -> BenchmarkResult:
    """Compute benchmark statistics from peer payment-term values."""
    terms = peers["payment_terms_days"].values

    if len(terms) == 0:
        return BenchmarkResult(
            peers_found=0,
            average_terms_days=0.0,
            median_terms_days=0.0,
            std_dev=0.0,
            percentile=0.0,
            distribution=TermsDistribution(),
        )

    percentile = float(np.sum(terms <= payment_terms_days) / len(terms) * 100)
    distribution = TermsDistribution.model_validate(
        {
            "0-30": int(np.sum(terms <= 30)),
            "31-45": int(np.sum((terms > 30) & (terms <= 45))),
            "46-60": int(np.sum((terms > 45) & (terms <= 60))),
            "61-90": int(np.sum((terms > 60) & (terms <= 90))),
            "90+": int(np.sum(terms > 90)),
        }
    )

    return BenchmarkResult(
        peers_found=len(terms),
        average_terms_days=round(float(np.mean(terms)), 1),
        median_terms_days=round(float(np.median(terms)), 1),
        std_dev=round(
            float(np.std(terms, ddof=1)) if len(terms) > 1 else 0.0, 1
        ),
        percentile=round(percentile, 1),
        distribution=distribution,
    )
