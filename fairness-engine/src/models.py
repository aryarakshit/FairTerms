"""
FairTerms Fairness Engine - Pydantic models.

Request and response models for both the compute endpoint and the
stage-2 aggregate endpoints.
"""

from __future__ import annotations

from pydantic import BaseModel, Field


class SMEProfile(BaseModel):
    """Input SME business profile."""

    pincode: str = Field(..., examples=["743201"], description="6-digit Indian pincode")
    state: str = Field(..., examples=["West Bengal"])
    industry: str = Field(..., examples=["Textiles"])
    annual_revenue_inr: int = Field(..., gt=0, examples=[5_000_000])
    employee_count: int = Field(..., gt=0, examples=[12])
    years_in_operation: int = Field(..., ge=0, examples=[8])


class ComputeRequest(BaseModel):
    """Main request payload sent by the Node.js backend."""

    sme_profile: SMEProfile
    payment_terms_days: int = Field(..., gt=0, examples=[90])
    order_value_inr: int = Field(..., gt=0, examples=[250_000])
    buyer_industry: str = Field(..., examples=["Retail"])


class TermsDistribution(BaseModel):
    """Distribution of payment terms across standard buckets."""

    range_0_30: int = Field(0, alias="0-30", serialization_alias="0-30")
    range_31_45: int = Field(0, alias="31-45", serialization_alias="31-45")
    range_46_60: int = Field(0, alias="46-60", serialization_alias="46-60")
    range_61_90: int = Field(0, alias="61-90", serialization_alias="61-90")
    range_90_plus: int = Field(0, alias="90+", serialization_alias="90+")

    model_config = {"populate_by_name": True}


class BenchmarkResult(BaseModel):
    """Anonymized peer comparison results."""

    peers_found: int = Field(..., ge=0)
    average_terms_days: float
    median_terms_days: float
    std_dev: float
    percentile: float = Field(..., ge=0, le=100)
    distribution: TermsDistribution


class FairnessMetrics(BaseModel):
    """Core fairness metric calculations."""

    statistical_parity_difference: float
    disparate_impact_ratio: float
    equal_opportunity_difference: float
    theil_index: float


class BiasFactor(BaseModel):
    """A single detected bias factor with its impact assessment."""

    factor: str = Field(..., examples=["pincode_region"])
    impact_score: float = Field(..., ge=0, le=1)
    impact: str = Field(..., pattern="^(high|medium|low)$")
    detail: str


class StatisticalTests(BaseModel):
    """Statistical significance test results."""

    mann_whitney_u_pvalue: float
    chi_square_pvalue: float
    interpretation: str


class ComputeResponse(BaseModel):
    """Full response payload returned to the Node.js backend."""

    benchmark: BenchmarkResult
    fairness_metrics: FairnessMetrics
    bias_factors: list[BiasFactor]
    statistical_tests: StatisticalTests


class HeatmapStateAggregate(BaseModel):
    """Aggregate heatmap metrics for one state."""

    state: str
    state_code: str
    avg_payment_terms_days: float
    avg_fairness_score: float
    total_analyses: int
    bias_level: str = Field(..., pattern="^(fair|moderate|severe)$")


class HeatmapAggregateResponse(BaseModel):
    """Response payload for the national heatmap endpoint."""

    states: list[HeatmapStateAggregate]
    industry_filter: str
    last_updated: str


class LeaderboardBuyerAggregate(BaseModel):
    """Aggregate leaderboard metrics for one buyer."""

    buyer_name: str
    fairness_score: int = Field(..., ge=0, le=100)
    avg_payment_terms_days: float
    total_smes_served: int
    rank: int = Field(..., ge=1)
    badge: str = Field(..., pattern="^(gold|silver|bronze|red_flag)$")


class LeaderboardAggregateResponse(BaseModel):
    """Response payload for the buyer leaderboard endpoint."""

    buyers: list[LeaderboardBuyerAggregate]
    total_buyers: int = Field(..., ge=0)
    last_updated: str
