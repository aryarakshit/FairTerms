"""
FairTerms Fairness Engine — Bias Detector

Core bias detection logic. For each potential bias factor, this module:
  1. Splits peers into privileged vs unprivileged groups
  2. Computes the mean payment terms difference (effect size)
  3. Runs Mann-Whitney U test (non-parametric) for significance
  4. Runs Chi-Square test on favorable/unfavorable distributions
  5. Computes an impact score combining effect size + significance
  6. Generates a human-readable explanation

Returns a sorted list of BiasFactor objects (highest impact first).
"""

from __future__ import annotations

import numpy as np
import pandas as pd
from scipy import stats as sp_stats

from src.models import BiasFactor, SMEProfile, StatisticalTests
from src.utils import (
    DISADVANTAGED_INDUSTRIES,
    FAVORABLE_TERMS_THRESHOLD,
    SMALL_FIRM_THRESHOLD,
    is_metro_pincode,
    logger,
)


# ---------------------------------------------------------------------------
# Factor Definitions
# ---------------------------------------------------------------------------
# Each factor defines how to split the data into privileged / unprivileged


def _split_by_metro(peers: pd.DataFrame, sme: SMEProfile):
    """Split by metro vs non-metro pincode."""
    if "is_metro" in peers.columns:
        priv_mask = peers["is_metro"].astype(bool)
    else:
        priv_mask = peers["pincode"].apply(is_metro_pincode)
    return priv_mask, ~priv_mask


def _split_by_industry(peers: pd.DataFrame, sme: SMEProfile):
    """Split by advantaged vs disadvantaged industry."""
    disadv_mask = peers["industry"].isin(DISADVANTAGED_INDUSTRIES)
    return ~disadv_mask, disadv_mask  # privileged = NOT disadvantaged


def _split_by_firm_size(peers: pd.DataFrame, sme: SMEProfile):
    """Split by firm size (small vs non-small)."""
    small_mask = peers["employee_count"] < SMALL_FIRM_THRESHOLD
    return ~small_mask, small_mask  # privileged = larger firms


def _split_by_firm_age(peers: pd.DataFrame, sme: SMEProfile):
    """Split by firm age (young < 5 years vs established)."""
    young_mask = peers["years_in_operation"] < 5
    return ~young_mask, young_mask  # privileged = established firms


def _split_by_state(peers: pd.DataFrame, sme: SMEProfile):
    """Split by whether SME is in the same state as majority of peers."""
    if "state" not in peers.columns:
        return pd.Series(True, index=peers.index), pd.Series(False, index=peers.index)

    # Top states by count as "privileged" (> median representation)
    state_counts = peers["state"].value_counts()
    median_count = state_counts.median()
    top_states = set(state_counts[state_counts >= median_count].index)

    priv_mask = peers["state"].isin(top_states)
    return priv_mask, ~priv_mask


FACTOR_REGISTRY = {
    "pincode_region": {
        "splitter": _split_by_metro,
        "label_priv": "metro",
        "label_unpriv": "non-metro",
        "detail_template": "Businesses in non-metro pincodes receive {pct}% worse terms than metro peers",
    },
    "industry": {
        "splitter": _split_by_industry,
        "label_priv": "advantaged industries",
        "label_unpriv": "disadvantaged industries (Textiles/Handicrafts/Leather)",
        "detail_template": "Disadvantaged industry SMEs receive {pct}% worse terms than other industries",
    },
    "firm_size": {
        "splitter": _split_by_firm_size,
        "label_priv": "firms with ≥10 employees",
        "label_unpriv": "firms with <10 employees",
        "detail_template": "Small firms (<10 employees) receive {pct}% worse terms than larger firms",
    },
    "firm_age": {
        "splitter": _split_by_firm_age,
        "label_priv": "established firms (≥5 years)",
        "label_unpriv": "young firms (<5 years)",
        "detail_template": "Young firms (<5 years) receive {pct}% worse terms than established firms",
    },
    "state": {
        "splitter": _split_by_state,
        "label_priv": "well-represented states",
        "label_unpriv": "under-represented states",
        "detail_template": "SMEs in under-represented states receive {pct}% worse terms",
    },
}


# ---------------------------------------------------------------------------
# Core Bias Analysis
# ---------------------------------------------------------------------------

def _analyze_factor(
    factor_name: str,
    factor_config: dict,
    peers: pd.DataFrame,
    sme: SMEProfile,
) -> tuple[BiasFactor, dict]:
    """
    Analyze a single bias factor.

    Returns:
        (BiasFactor, stat_results_dict)
    """
    splitter = factor_config["splitter"]
    priv_mask, unpriv_mask = splitter(peers, sme)

    terms = peers["payment_terms_days"]
    priv_terms = terms[priv_mask].values
    unpriv_terms = terms[unpriv_mask].values

    # ── Effect Size ──
    if len(priv_terms) > 0 and len(unpriv_terms) > 0:
        priv_mean = np.mean(priv_terms)
        unpriv_mean = np.mean(unpriv_terms)

        if priv_mean > 0:
            pct_diff = round(((unpriv_mean - priv_mean) / priv_mean) * 100, 1)
        else:
            pct_diff = 0.0

        # Normalized effect size (0 to 1 scale)
        # Using Cohen's d approximation, capped at 1
        if len(priv_terms) < 2 or len(unpriv_terms) < 2:
            # Insufficient samples for variance-based effect size — skip factor
            return BiasFactor(
                factor=factor_name,
                impact_score=0.0,
                impact="low",
                detail="Insufficient data for reliable analysis",
            ), {
                "factor": factor_name,
                "mann_whitney_u_pvalue": 1.0,
                "chi_square_pvalue": 1.0,
                "priv_count": len(priv_terms),
                "unpriv_count": len(unpriv_terms),
                "pct_diff": 0.0,
            }

        pooled_std = float(np.sqrt(
            (np.var(priv_terms, ddof=1) + np.var(unpriv_terms, ddof=1)) / 2
        ))

        if pooled_std > 0:
            cohens_d = abs(unpriv_mean - priv_mean) / pooled_std
        else:
            cohens_d = 0.0

    else:
        pct_diff = 0.0
        cohens_d = 0.0

    # ── Statistical Tests ──
    mw_pvalue = 1.0
    chi_pvalue = 1.0

    if len(priv_terms) >= 5 and len(unpriv_terms) >= 5:
        # Mann-Whitney U test (non-parametric)
        try:
            _, mw_pvalue = sp_stats.mannwhitneyu(
                unpriv_terms, priv_terms, alternative="greater"
            )
        except ValueError:
            mw_pvalue = 1.0

        # Chi-Square test on favorable / unfavorable outcome counts
        try:
            priv_fav = np.sum(priv_terms <= FAVORABLE_TERMS_THRESHOLD)
            priv_unfav = len(priv_terms) - priv_fav
            unpriv_fav = np.sum(unpriv_terms <= FAVORABLE_TERMS_THRESHOLD)
            unpriv_unfav = len(unpriv_terms) - unpriv_fav

            contingency = np.array([
                [priv_fav, priv_unfav],
                [unpriv_fav, unpriv_unfav],
            ])

            # Only run if all cells have expected count ≥ 5
            if contingency.min() >= 0 and contingency.sum() > 0:
                chi2, chi_pvalue, _, _ = sp_stats.chi2_contingency(contingency)
            else:
                chi_pvalue = 1.0
        except (ValueError, ZeroDivisionError):
            chi_pvalue = 1.0

    # ── Impact Score ──
    # Combines effect size (Cohen's d, max 1) and statistical significance
    significance_bonus = 0.0
    if mw_pvalue < 0.001:
        significance_bonus = 0.3
    elif mw_pvalue < 0.01:
        significance_bonus = 0.2
    elif mw_pvalue < 0.05:
        significance_bonus = 0.1

    # impact_score = 60% effect size + 40% significance
    raw_score = 0.6 * min(cohens_d, 1.0) + 0.4 * significance_bonus / 0.3
    impact_score = round(min(max(raw_score, 0.0), 1.0), 2)

    # ── Impact Classification ──
    if impact_score >= 0.6:
        impact_level = "high"
    elif impact_score >= 0.3:
        impact_level = "medium"
    else:
        impact_level = "low"

    # ── Human-Readable Detail ──
    if abs(pct_diff) >= 1.0:
        detail = factor_config["detail_template"].format(pct=abs(pct_diff))
    else:
        detail = "Not a significant driver"

    bias_factor = BiasFactor(
        factor=factor_name,
        impact_score=impact_score,
        impact=impact_level,
        detail=detail,
    )

    stat_results = {
        "factor": factor_name,
        "mann_whitney_u_pvalue": round(mw_pvalue, 6),
        "chi_square_pvalue": round(chi_pvalue, 6),
        "priv_count": len(priv_terms),
        "unpriv_count": len(unpriv_terms),
        "pct_diff": pct_diff,
    }

    return bias_factor, stat_results


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def detect_bias(
    peers: pd.DataFrame,
    sme_profile: SMEProfile,
) -> tuple[list[BiasFactor], StatisticalTests]:
    """
    Detect bias across all registered factors.

    Args:
        peers: DataFrame of peer SME records.
        sme_profile: The input SME's profile.

    Returns:
        (sorted list of BiasFactor, aggregated StatisticalTests)
    """
    logger.info(f"Running bias detection on {len(peers)} peers across {len(FACTOR_REGISTRY)} factors")

    bias_factors: list[BiasFactor] = []
    all_stats: list[dict] = []

    for factor_name, factor_config in FACTOR_REGISTRY.items():
        try:
            bf, stat = _analyze_factor(factor_name, factor_config, peers, sme_profile)
            bias_factors.append(bf)
            all_stats.append(stat)
            logger.info(
                f"  {factor_name}: impact={bf.impact_score:.2f} ({bf.impact}), "
                f"MW p={stat['mann_whitney_u_pvalue']:.4f}, "
                f"χ² p={stat['chi_square_pvalue']:.4f}"
            )
        except Exception as e:
            logger.error(f"  Error analyzing factor {factor_name}: {e}")
            bias_factors.append(BiasFactor(
                factor=factor_name,
                impact_score=0.0,
                impact="low",
                detail=f"Analysis error: {str(e)}",
            ))

    # Sort by impact score descending
    bias_factors.sort(key=lambda bf: bf.impact_score, reverse=True)

    # Aggregate statistical tests (use the most significant factor — pincode_region)
    primary_stat = next(
        (s for s in all_stats if s["factor"] == "pincode_region"),
        all_stats[0] if all_stats else {"mann_whitney_u_pvalue": 1.0, "chi_square_pvalue": 1.0},
    )

    mw_p = primary_stat["mann_whitney_u_pvalue"]
    chi_p = primary_stat["chi_square_pvalue"]

    if mw_p < 0.05 and chi_p < 0.05:
        interpretation = "Differences are statistically significant (p < 0.05)"
    elif mw_p < 0.05 or chi_p < 0.05:
        interpretation = "Some evidence of significant differences (partial p < 0.05)"
    else:
        interpretation = "Differences are not statistically significant (p ≥ 0.05)"

    statistical_tests = StatisticalTests(
        mann_whitney_u_pvalue=round(mw_p, 4),
        chi_square_pvalue=round(chi_p, 4),
        interpretation=interpretation,
    )

    return bias_factors, statistical_tests
