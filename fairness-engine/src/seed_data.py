"""
FairTerms Fairness Engine - Seed Data Generator.

Generates stage-2 synthetic SME benchmark records with deliberate,
demo-friendly bias patterns for state heatmaps and buyer rankings.

Usage:
    python -m src.seed_data
    python -m src.seed_data --count 1200
"""

from __future__ import annotations

import argparse
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from src.utils import (  # noqa: E402
    BIAS_DISADVANTAGED_INDUSTRY,
    BIAS_NON_METRO,
    BIAS_SMALL_FIRM,
    BUYER_PROFILES,
    DISADVANTAGED_INDUSTRIES,
    INDUSTRY_WEIGHTS,
    METRO_PINCODES,
    NON_METRO_PINCODES,
    SMALL_FIRM_THRESHOLD,
    compute_fairness_score,
    get_state_code,
    get_state_term_baseline,
    logger,
)

RNG = np.random.default_rng(seed=42)

LOCATION_STATE_WEIGHTS = {
    "Maharashtra": 1.20,
    "Karnataka": 1.10,
    "Delhi": 1.00,
    "Tamil Nadu": 1.10,
    "West Bengal": 1.20,
    "Uttar Pradesh": 1.15,
    "Bihar": 1.05,
    "Jharkhand": 1.05,
    "Odisha": 1.05,
}


def _build_location_pool() -> tuple[list[dict], np.ndarray]:
    """Build a weighted location pool from the bundled pincode maps."""
    locations: list[dict] = []

    for pincode, (city, state) in METRO_PINCODES.items():
        locations.append(
            {
                "pincode": pincode,
                "city": city,
                "state": state,
                "state_code": get_state_code(state),
                "is_metro": True,
                "weight": LOCATION_STATE_WEIGHTS.get(state, 0.85),
            }
        )

    for pincode, (city, state) in NON_METRO_PINCODES.items():
        locations.append(
            {
                "pincode": pincode,
                "city": city,
                "state": state,
                "state_code": get_state_code(state),
                "is_metro": False,
                "weight": LOCATION_STATE_WEIGHTS.get(state, 1.0),
            }
        )

    weights = np.array([location["weight"] for location in locations], dtype=float)
    weights = weights / weights.sum()
    return locations, weights


LOCATION_POOL, LOCATION_WEIGHTS = _build_location_pool()
BUYER_NAMES = list(BUYER_PROFILES.keys())
BUYER_WEIGHTS = np.array(
    [profile["weight"] for profile in BUYER_PROFILES.values()],
    dtype=float,
)
BUYER_WEIGHTS = BUYER_WEIGHTS / BUYER_WEIGHTS.sum()


def _pick_location() -> dict:
    """Select a location with weighted sampling for visible state patterns."""
    index = int(RNG.choice(len(LOCATION_POOL), p=LOCATION_WEIGHTS))
    return LOCATION_POOL[index]


def _pick_buyer_name() -> str:
    """Select a buyer name with weighted sampling."""
    return str(RNG.choice(BUYER_NAMES, p=BUYER_WEIGHTS))


def _compute_payment_terms(
    state: str,
    buyer_name: str,
    is_metro: bool,
    industry: str,
    employee_count: int,
) -> int:
    """Compute payment terms with intentional stage-2 buyer and geography bias."""
    state_baseline = get_state_term_baseline(state)
    buyer_baseline = BUYER_PROFILES[buyer_name]["base_terms_days"]
    base_terms = (state_baseline * 0.58) + (buyer_baseline * 0.42)
    bias_multiplier = 1.0

    if not is_metro:
        bias_multiplier *= BIAS_NON_METRO

    if industry in DISADVANTAGED_INDUSTRIES:
        bias_multiplier *= BIAS_DISADVANTAGED_INDUSTRY

    if employee_count < SMALL_FIRM_THRESHOLD:
        bias_multiplier *= BIAS_SMALL_FIRM

    noisy_terms = (base_terms * bias_multiplier) + RNG.normal(0, 5.5)
    return int(np.clip(noisy_terms, 15, 120))


def _generate_single_record(sme_id: int) -> dict:
    """Generate one synthetic SME record using the stage-2 schema."""
    location = _pick_location()
    industries = list(INDUSTRY_WEIGHTS.keys())
    industry_weights = list(INDUSTRY_WEIGHTS.values())
    industry = str(RNG.choice(industries, p=industry_weights))

    annual_revenue = int(
        np.clip(
            RNG.lognormal(mean=15.0, sigma=1.2),
            1_000_000,
            100_000_000,
        )
    )
    employee_count = int(np.clip(RNG.lognormal(mean=2.5, sigma=0.9), 1, 250))
    years_in_operation = int(np.clip(RNG.normal(10, 6), 1, 30))
    buyer_name = _pick_buyer_name()

    payment_terms_days = _compute_payment_terms(
        state=location["state"],
        buyer_name=buyer_name,
        is_metro=bool(location["is_metro"]),
        industry=industry,
        employee_count=employee_count,
    )

    order_value = int(
        np.clip(
            RNG.lognormal(mean=12.0, sigma=1.0),
            50_000,
            5_000_000,
        )
    )

    fairness_score = compute_fairness_score(payment_terms_days)
    days_ago = int(RNG.integers(1, 365))
    created_at = (datetime.now() - timedelta(days=days_ago)).isoformat()

    return {
        "sme_id": f"SME-{sme_id:04d}",
        "pincode": location["pincode"],
        "state": location["state"],
        "state_code": location["state_code"],
        "city": location["city"],
        "is_metro": location["is_metro"],
        "industry": industry,
        "annual_revenue_inr": annual_revenue,
        "employee_count": employee_count,
        "years_in_operation": years_in_operation,
        "buyer_name": buyer_name,
        "payment_terms_days": payment_terms_days,
        "order_value_inr": order_value,
        "fairness_score": fairness_score,
        "created_at": created_at,
    }


def generate_seed_data(count: int = 1000) -> pd.DataFrame:
    """Generate a DataFrame of stage-2 synthetic SME records."""
    logger.info("Generating %s synthetic SME benchmark records...", count)
    df = pd.DataFrame([_generate_single_record(i) for i in range(1, count + 1)])

    state_summary = (
        df.groupby("state")["payment_terms_days"]
        .mean()
        .round(1)
        .sort_values(ascending=False)
    )
    buyer_summary = (
        df.groupby("buyer_name")["payment_terms_days"]
        .mean()
        .round(1)
        .sort_values(ascending=False)
    )

    logger.info("  Records generated: %s", len(df))
    logger.info("  Highest-delay states: %s", state_summary.head(5).to_dict())
    logger.info("  Fairest states: %s", state_summary.tail(5).to_dict())
    logger.info("  Worst buyers: %s", buyer_summary.head(5).to_dict())
    logger.info("  Best buyers: %s", buyer_summary.tail(5).to_dict())

    return df


def save_seed_data(df: pd.DataFrame, path: str = "data/seed_data.csv") -> str:
    """Save seed data to CSV, creating directories as needed."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    df.to_csv(path, index=False)
    logger.info("  Saved to: %s", path)
    return path


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate FairTerms seed data")
    parser.add_argument(
        "--count",
        type=int,
        default=int(os.getenv("SEED_RECORD_COUNT", "1000")),
        help="Number of records to generate",
    )
    parser.add_argument(
        "--output",
        type=str,
        default="data/seed_data.csv",
        help="Output path",
    )
    args = parser.parse_args()

    dataframe = generate_seed_data(args.count)
    save_seed_data(dataframe, args.output)
    print(f"\nGenerated {len(dataframe)} records -> {args.output}")
