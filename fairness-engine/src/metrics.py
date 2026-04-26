"""
FairTerms Fairness Engine — Fairness Metrics

Manual implementation of four core fairness metrics.
Designed as a pluggable module — AIF360 can replace these
calculations later without changing the API interface.

Metrics:
  1. Statistical Parity Difference
  2. Disparate Impact Ratio
  3. Equal Opportunity Difference
  4. Theil Index (Generalized Entropy)
"""

from __future__ import annotations

import numpy as np
import pandas as pd

from src.models import FairnessMetrics
from src.utils import FAVORABLE_TERMS_THRESHOLD, logger


def compute_fairness_metrics(
    peers: pd.DataFrame,
    protected_col: str = "is_metro",
) -> FairnessMetrics:
    """
    Compute all four fairness metrics for a given protected attribute.

    The primary protected attribute is metro vs non-metro (is_metro).
    A payment term is "favorable" if it is <= FAVORABLE_TERMS_THRESHOLD (45 days).

    Groups:
      - Privileged:    is_metro == True  (or the advantaged group)
      - Unprivileged:  is_metro == False (or the disadvantaged group)

    Args:
        peers: DataFrame of peer SMEs with 'payment_terms_days' and the protected column.
        protected_col: Column name for the protected attribute (boolean-like).

    Returns:
        FairnessMetrics with all four metric values.
    """
    if len(peers) == 0:
        return FairnessMetrics(
            statistical_parity_difference=0.0,
            disparate_impact_ratio=1.0,
            equal_opportunity_difference=0.0,
            theil_index=0.0,
        )

    # Ensure the protected column exists
    if protected_col not in peers.columns:
        logger.warning(f"Protected column '{protected_col}' not found, returning neutral metrics")
        return FairnessMetrics(
            statistical_parity_difference=0.0,
            disparate_impact_ratio=1.0,
            equal_opportunity_difference=0.0,
            theil_index=0.0,
        )

    # Binary favorable outcome: terms <= threshold
    favorable = peers["payment_terms_days"] <= FAVORABLE_TERMS_THRESHOLD

    # Split into privileged / unprivileged
    privileged_mask = peers[protected_col].astype(bool)
    unprivileged_mask = ~privileged_mask

    priv = favorable[privileged_mask]
    unpriv = favorable[unprivileged_mask]

    # Handle edge cases where one group is empty
    if len(priv) == 0 or len(unpriv) == 0:
        return FairnessMetrics(
            statistical_parity_difference=0.0,
            disparate_impact_ratio=1.0,
            equal_opportunity_difference=0.0,
            theil_index=compute_theil_index(peers["payment_terms_days"].values),
        )

    # ── 1. Statistical Parity Difference ──
    # P(favorable | unprivileged) - P(favorable | privileged)
    # Negative = unprivileged group gets fewer favorable outcomes
    p_fav_priv = priv.mean()
    p_fav_unpriv = unpriv.mean()
    spd = round(float(p_fav_unpriv - p_fav_priv), 4)

    # ── 2. Disparate Impact Ratio ──
    # P(favorable | unprivileged) / P(favorable | privileged)
    # < 0.8 = adverse impact (4/5ths rule)
    if p_fav_priv > 0:
        dir_val = round(float(p_fav_unpriv / p_fav_priv), 4)
    else:
        dir_val = 1.0 if p_fav_unpriv == 0 else 0.0

    # ── 3. Equal Opportunity Difference ──
    # Among SMEs that *deserve* favorable terms (good financials),
    # what's the gap in actually receiving them?
    # Proxy: SMEs with above-median revenue "deserve" good terms
    if "annual_revenue_inr" in peers.columns:
        median_rev = peers["annual_revenue_inr"].median()
        deserving = peers["annual_revenue_inr"] >= median_rev
    else:
        # Fallback: use all records
        deserving = pd.Series(True, index=peers.index)

    priv_deserving = favorable[privileged_mask & deserving]
    unpriv_deserving = favorable[unprivileged_mask & deserving]

    if len(priv_deserving) > 0 and len(unpriv_deserving) > 0:
        eod = round(float(unpriv_deserving.mean() - priv_deserving.mean()), 4)
    else:
        eod = 0.0

    # ── 4. Theil Index ──
    theil = compute_theil_index(peers["payment_terms_days"].values)

    return FairnessMetrics(
        statistical_parity_difference=spd,
        disparate_impact_ratio=dir_val,
        equal_opportunity_difference=eod,
        theil_index=theil,
    )


def compute_theil_index(values: np.ndarray) -> float:
    """
    Compute the Theil Index (Generalized Entropy with alpha=1).

    T = (1/N) * Σ (y_i / μ) * ln(y_i / μ)

    - 0 = perfect equality
    - Higher values = more inequality

    Args:
        values: Array of payment term values (must be positive).

    Returns:
        Theil index rounded to 4 decimal places.
    """
    values = values.astype(float)
    values = values[values > 0]  # Theil requires positive values

    if len(values) == 0:
        return 0.0

    mu = np.mean(values)
    if mu == 0:
        return 0.0

    ratios = values / mu
    # Avoid log(0) by filtering zeros (already done above)
    theil = float(np.mean(ratios * np.log(ratios)))
    return round(theil, 4)


# ---------------------------------------------------------------------------
# AIF360 Integration Point
# ---------------------------------------------------------------------------
# To switch to AIF360 later, replace the compute_fairness_metrics function
# body with something like:
#
#   from aif360.datasets import BinaryLabelDataset
#   from aif360.metrics import BinaryLabelDatasetMetric
#
#   bld = BinaryLabelDataset(
#       df=peers_df,
#       label_names=["favorable"],
#       protected_attribute_names=["is_metro"],
#   )
#   metric = BinaryLabelDatasetMetric(bld, privileged_groups=[{"is_metro": 1}],
#                                      unprivileged_groups=[{"is_metro": 0}])
#   spd = metric.statistical_parity_difference()
#   dir = metric.disparate_impact()
#   ...
#
# The function signature and return type remain identical.
