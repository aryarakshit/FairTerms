"""
FairTerms Fairness Engine - Stage-2 aggregate queries.

Provides local CSV and BigQuery-backed aggregate datasets for the
national heatmap and buyer leaderboard.
"""

from __future__ import annotations

import os
from datetime import datetime, timezone

import pandas as pd

from src.benchmarking import get_dataset
from src.models import (
    HeatmapAggregateResponse,
    HeatmapStateAggregate,
    LeaderboardAggregateResponse,
    LeaderboardBuyerAggregate,
)
from src.utils import classify_bias_level, get_badge, logger

MAX_LEADERBOARD_LIMIT = 100
ALLOWED_SORT_FIELDS = {
    "fairness_score": "fairness_score",
    "avg_payment_terms_days": "avg_payment_terms_days",
    "total_smes_served": "total_smes_served",
    "buyer_name": "buyer_name",
}


def _utc_now_iso() -> str:
    """Return the current UTC time in ISO-8601 with a Z suffix."""
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _last_updated_from_df(df: pd.DataFrame) -> str:
    """Return the newest timestamp from a DataFrame, or now if unavailable."""
    if df.empty:
        return _utc_now_iso()

    source_column = "last_updated" if "last_updated" in df.columns else "created_at"
    if source_column not in df.columns:
        return _utc_now_iso()

    timestamps = pd.to_datetime(df[source_column], errors="coerce", utc=True)
    latest = timestamps.max()
    if pd.isna(latest):
        return _utc_now_iso()
    return latest.to_pydatetime().replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _filter_by_industry(df: pd.DataFrame, industry: str) -> pd.DataFrame:
    """Apply the optional industry filter."""
    if not industry or industry.lower() == "all":
        return df
    return df[df["industry"] == industry]


def aggregate_heatmap(industry: str = "all") -> HeatmapAggregateResponse:
    """Aggregate heatmap metrics from the local CSV dataset."""
    dataset = _filter_by_industry(get_dataset(), industry)
    last_updated = _last_updated_from_df(dataset)

    if dataset.empty:
        return HeatmapAggregateResponse(states=[], industry_filter=industry, last_updated=last_updated)

    grouped = (
        dataset.groupby(["state", "state_code"], dropna=False)
        .agg(
            avg_payment_terms_days=("payment_terms_days", "mean"),
            avg_fairness_score=("fairness_score", "mean"),
            total_analyses=("sme_id", "count"),
        )
        .reset_index()
        .sort_values(
            by=["avg_fairness_score", "total_analyses", "state"],
            ascending=[True, False, True],
        )
    )

    states = [
        HeatmapStateAggregate(
            state=str(row.state),
            state_code=str(row.state_code),
            avg_payment_terms_days=round(float(row.avg_payment_terms_days), 1),
            avg_fairness_score=round(float(row.avg_fairness_score), 1),
            total_analyses=int(row.total_analyses),
            bias_level=classify_bias_level(float(row.avg_fairness_score)),
        )
        for row in grouped.itertuples(index=False)
    ]

    logger.info("Heatmap aggregate built for industry=%s with %s states", industry, len(states))
    return HeatmapAggregateResponse(
        states=states,
        industry_filter=industry,
        last_updated=last_updated,
    )


def aggregate_leaderboard(
    sort: str = "fairness_score",
    order: str = "desc",
    limit: int = 50,
) -> LeaderboardAggregateResponse:
    """Aggregate buyer leaderboard metrics from the local CSV dataset."""
    sort_column = ALLOWED_SORT_FIELDS.get(sort, "fairness_score")
    sort_order = order.lower()
    ascending = sort_order == "asc"
    bounded_limit = max(1, min(int(limit), MAX_LEADERBOARD_LIMIT))

    dataset = get_dataset()
    last_updated = _last_updated_from_df(dataset)

    grouped = (
        dataset.groupby("buyer_name", dropna=False)
        .agg(
            fairness_score=("fairness_score", "mean"),
            avg_payment_terms_days=("payment_terms_days", "mean"),
            total_smes_served=("sme_id", "nunique"),
        )
        .reset_index()
    )

    grouped["fairness_score"] = grouped["fairness_score"].round().astype(int)
    grouped["avg_payment_terms_days"] = grouped["avg_payment_terms_days"].round(1)

    sort_columns = [sort_column]
    sort_directions = [ascending]
    if sort_column != "buyer_name":
        sort_columns.append("buyer_name")
        sort_directions.append(True)

    grouped = grouped.sort_values(by=sort_columns, ascending=sort_directions).reset_index(drop=True)
    grouped["rank"] = range(1, len(grouped) + 1)
    total_buyers = len(grouped)
    limited = grouped.head(bounded_limit)

    buyers = [
        LeaderboardBuyerAggregate(
            buyer_name=str(row.buyer_name),
            fairness_score=int(row.fairness_score),
            avg_payment_terms_days=round(float(row.avg_payment_terms_days), 1),
            total_smes_served=int(row.total_smes_served),
            rank=int(row.rank),
            badge=get_badge(int(row.fairness_score)),
        )
        for row in limited.itertuples(index=False)
    ]

    logger.info("Leaderboard aggregate built with %s buyers", len(buyers))
    return LeaderboardAggregateResponse(
        buyers=buyers,
        total_buyers=total_buyers,
        last_updated=last_updated,
    )


def aggregate_heatmap_bigquery(industry: str = "all") -> HeatmapAggregateResponse:
    """Aggregate heatmap metrics directly from BigQuery."""
    from google.cloud import bigquery

    project = os.getenv("GCP_PROJECT_ID")
    dataset_id = os.getenv("BIGQUERY_DATASET", "fairterms")
    table_id = os.getenv("BIGQUERY_TABLE", "benchmarks")
    full_table = f"{project}.{dataset_id}.{table_id}"

    client = bigquery.Client(project=project)
    query_parameters: list[bigquery.ScalarQueryParameter] = []
    where_clause = ""
    if industry and industry.lower() != "all":
        where_clause = "WHERE industry = @industry"
        query_parameters.append(bigquery.ScalarQueryParameter("industry", "STRING", industry))

    query = f"""
        SELECT
          state,
          COALESCE(state_code, 'NA') AS state_code,
          ROUND(AVG(payment_terms_days), 1) AS avg_payment_terms_days,
          ROUND(AVG(fairness_score), 1) AS avg_fairness_score,
          COUNT(*) AS total_analyses,
          MAX(created_at) AS last_updated
        FROM `{full_table}`
        {where_clause}
        GROUP BY state, state_code
        ORDER BY avg_fairness_score ASC, total_analyses DESC, state ASC
    """

    dataframe = client.query(
        query,
        job_config=bigquery.QueryJobConfig(query_parameters=query_parameters),
    ).to_dataframe()
    last_updated = _last_updated_from_df(dataframe)

    states = [
        HeatmapStateAggregate(
            state=str(row.state),
            state_code=str(row.state_code),
            avg_payment_terms_days=round(float(row.avg_payment_terms_days), 1),
            avg_fairness_score=round(float(row.avg_fairness_score), 1),
            total_analyses=int(row.total_analyses),
            bias_level=classify_bias_level(float(row.avg_fairness_score)),
        )
        for row in dataframe.itertuples(index=False)
    ]

    return HeatmapAggregateResponse(
        states=states,
        industry_filter=industry,
        last_updated=last_updated,
    )


def aggregate_leaderboard_bigquery(
    sort: str = "fairness_score",
    order: str = "desc",
    limit: int = 50,
) -> LeaderboardAggregateResponse:
    """Aggregate buyer leaderboard metrics directly from BigQuery."""
    from google.cloud import bigquery

    project = os.getenv("GCP_PROJECT_ID")
    dataset_id = os.getenv("BIGQUERY_DATASET", "fairterms")
    table_id = os.getenv("BIGQUERY_TABLE", "benchmarks")
    full_table = f"{project}.{dataset_id}.{table_id}"
    sort_column = ALLOWED_SORT_FIELDS.get(sort, "fairness_score")
    order_sql = "ASC" if order.lower() == "asc" else "DESC"
    secondary_sort = "" if sort_column == "buyer_name" else ", buyer_name ASC"
    bounded_limit = max(1, min(int(limit), MAX_LEADERBOARD_LIMIT))

    client = bigquery.Client(project=project)
    query = f"""
        WITH buyer_aggregates AS (
          SELECT
            buyer_name,
            CAST(ROUND(AVG(fairness_score), 0) AS INT64) AS fairness_score,
            ROUND(AVG(payment_terms_days), 1) AS avg_payment_terms_days,
            COUNT(DISTINCT sme_id) AS total_smes_served,
            MAX(created_at) AS last_updated
          FROM `{full_table}`
          GROUP BY buyer_name
        ),
        ranked AS (
          SELECT
            *,
            ROW_NUMBER() OVER (ORDER BY {sort_column} {order_sql}{secondary_sort}) AS rank,
            COUNT(*) OVER () AS total_buyers
          FROM buyer_aggregates
        )
        SELECT *
        FROM ranked
        ORDER BY rank
        LIMIT @limit
    """

    dataframe = client.query(
        query,
        job_config=bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter("limit", "INT64", bounded_limit),
            ]
        ),
    ).to_dataframe()

    if dataframe.empty:
        return LeaderboardAggregateResponse(
            buyers=[],
            total_buyers=0,
            last_updated=_utc_now_iso(),
        )

    buyers = [
        LeaderboardBuyerAggregate(
            buyer_name=str(row.buyer_name),
            fairness_score=int(row.fairness_score),
            avg_payment_terms_days=round(float(row.avg_payment_terms_days), 1),
            total_smes_served=int(row.total_smes_served),
            rank=int(row.rank),
            badge=get_badge(int(row.fairness_score)),
        )
        for row in dataframe.itertuples(index=False)
    ]

    total_buyers = int(dataframe.iloc[0]["total_buyers"])
    last_updated = _last_updated_from_df(dataframe)
    return LeaderboardAggregateResponse(
        buyers=buyers,
        total_buyers=total_buyers,
        last_updated=last_updated,
    )
