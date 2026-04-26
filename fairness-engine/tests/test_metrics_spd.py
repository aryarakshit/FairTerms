"""Unit tests for Statistical Parity Difference sign convention."""
import pandas as pd
from src.metrics import compute_fairness_metrics


def _make_peers(metro_terms, non_metro_terms):
    """Build a peers DataFrame from two lists of payment_terms_days."""
    records = (
        [{"payment_terms_days": d, "is_metro": True} for d in metro_terms]
        + [{"payment_terms_days": d, "is_metro": False} for d in non_metro_terms]
    )
    return pd.DataFrame(records)


def test_spd_negative_when_nonmetro_disadvantaged():
    """Non-metro SMEs getting longer (worse) terms → SPD must be negative."""
    # Metro: mostly short terms (favorable)
    # Non-metro: mostly long terms (unfavorable)
    peers = _make_peers(
        metro_terms=[30, 30, 45, 45, 30],
        non_metro_terms=[75, 90, 60, 90, 75],
    )
    metrics = compute_fairness_metrics(peers)
    assert metrics.statistical_parity_difference < 0, (
        "SPD should be negative when unprivileged group receives fewer favorable outcomes"
    )


def test_spd_zero_when_groups_equal():
    """Identical distributions across groups → SPD must be zero."""
    peers = _make_peers(
        metro_terms=[30, 45, 60],
        non_metro_terms=[30, 45, 60],
    )
    metrics = compute_fairness_metrics(peers)
    assert metrics.statistical_parity_difference == 0.0


def test_spd_positive_when_nonmetro_advantaged():
    """If non-metro somehow gets better terms → SPD should be positive."""
    peers = _make_peers(
        metro_terms=[75, 90, 60],
        non_metro_terms=[30, 30, 30],
    )
    metrics = compute_fairness_metrics(peers)
    assert metrics.statistical_parity_difference > 0
