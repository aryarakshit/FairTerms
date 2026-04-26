"""
FairTerms Fairness Engine - Utilities & Constants.

Shared helpers, pincode mappings, stage-2 aggregation helpers,
and configuration constants used across the service.
"""

import logging
import os
from enum import Enum

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(name)s | %(levelname)s | %(message)s",
)
logger = logging.getLogger("fairterms")

# ---------------------------------------------------------------------------
# Payment Terms Threshold
# ---------------------------------------------------------------------------
FAVORABLE_TERMS_THRESHOLD = 45  # days

# ---------------------------------------------------------------------------
# Metro Pincode Mapping
# ---------------------------------------------------------------------------
METRO_PINCODE_PREFIXES = {
    "400", "401", "410",  # Mumbai
    "110", "120", "121", "122", "201",  # Delhi / NCR
    "560", "561", "562",  # Bangalore
    "600", "601", "602",  # Chennai
    "500", "501",  # Hyderabad
    "411", "412",  # Pune
    "700", "701",  # Kolkata
    "380", "382",  # Ahmedabad
}

METRO_PINCODES = {
    "400001": ("Mumbai", "Maharashtra"),
    "400053": ("Mumbai", "Maharashtra"),
    "110001": ("New Delhi", "Delhi"),
    "110085": ("New Delhi", "Delhi"),
    "122001": ("Gurugram", "Haryana"),
    "560001": ("Bangalore", "Karnataka"),
    "560034": ("Bangalore", "Karnataka"),
    "600001": ("Chennai", "Tamil Nadu"),
    "600040": ("Chennai", "Tamil Nadu"),
    "500001": ("Hyderabad", "Telangana"),
    "500034": ("Hyderabad", "Telangana"),
    "411001": ("Pune", "Maharashtra"),
    "411014": ("Pune", "Maharashtra"),
    "700001": ("Kolkata", "West Bengal"),
    "380001": ("Ahmedabad", "Gujarat"),
}

NON_METRO_PINCODES = {
    "743201": ("Barasat", "West Bengal"),
    "302001": ("Jaipur", "Rajasthan"),
    "226001": ("Lucknow", "Uttar Pradesh"),
    "452001": ("Indore", "Madhya Pradesh"),
    "440001": ("Nagpur", "Maharashtra"),
    "641001": ("Coimbatore", "Tamil Nadu"),
    "360001": ("Rajkot", "Gujarat"),
    "396001": ("Valsad", "Gujarat"),
    "583101": ("Bellary", "Karnataka"),
    "516001": ("Kadapa", "Andhra Pradesh"),
    "754001": ("Cuttack", "Odisha"),
    "781001": ("Guwahati", "Assam"),
    "800001": ("Patna", "Bihar"),
    "831001": ("Jamshedpur", "Jharkhand"),
    "682001": ("Kochi", "Kerala"),
}


def is_metro_pincode(pincode: str) -> bool:
    """Check if a pincode belongs to a metro city using prefix matching."""
    return str(pincode)[:3] in METRO_PINCODE_PREFIXES


# ---------------------------------------------------------------------------
# Industry Classification
# ---------------------------------------------------------------------------
class IndustryCategory(str, Enum):
    """Industry verticals matching Indian MSME census distribution."""

    TEXTILES = "Textiles"
    FOOD_PROCESSING = "Food Processing"
    AUTO_COMPONENTS = "Auto Components"
    IT_SERVICES = "IT Services"
    HANDICRAFTS = "Handicrafts"
    CHEMICALS = "Chemicals"
    LEATHER = "Leather"
    ELECTRONICS = "Electronics"
    PHARMA = "Pharma"
    METAL_FABRICATION = "Metal Fabrication"


DISADVANTAGED_INDUSTRIES = {"Textiles", "Handicrafts", "Leather"}

INDUSTRY_WEIGHTS = {
    "Textiles": 0.20,
    "Food Processing": 0.15,
    "Auto Components": 0.08,
    "IT Services": 0.10,
    "Handicrafts": 0.07,
    "Chemicals": 0.08,
    "Leather": 0.05,
    "Electronics": 0.12,
    "Pharma": 0.07,
    "Metal Fabrication": 0.08,
}

# ---------------------------------------------------------------------------
# Revenue Bands
# ---------------------------------------------------------------------------
REVENUE_BANDS = [
    (0, 2_500_000, "micro"),  # < 25L
    (2_500_001, 10_000_000, "small"),  # 25L - 1Cr
    (10_000_001, 50_000_000, "medium"),  # 1Cr - 5Cr
    (50_000_001, float("inf"), "large"),  # > 5Cr
]


def get_revenue_band(revenue: int) -> str:
    """Classify annual revenue into a band."""
    for low, high, label in REVENUE_BANDS:
        if low <= revenue <= high:
            return label
    return "large"


# ---------------------------------------------------------------------------
# Employee Size Categories
# ---------------------------------------------------------------------------
SMALL_FIRM_THRESHOLD = 10


def is_small_firm(employee_count: int) -> bool:
    """Check if a firm is 'small' by employee count."""
    return employee_count < SMALL_FIRM_THRESHOLD


# ---------------------------------------------------------------------------
# Bias Multipliers
# ---------------------------------------------------------------------------
BIAS_NON_METRO = 1.30
BIAS_DISADVANTAGED_INDUSTRY = 1.20
BIAS_SMALL_FIRM = 1.15


# ---------------------------------------------------------------------------
# State Codes And Baselines
# ---------------------------------------------------------------------------
STATE_CODE_MAP = {
    "Andhra Pradesh": "AP",
    "Assam": "AS",
    "Bihar": "BR",
    "Delhi": "DL",
    "Gujarat": "GJ",
    "Haryana": "HR",
    "Jharkhand": "JH",
    "Karnataka": "KA",
    "Kerala": "KL",
    "Madhya Pradesh": "MP",
    "Maharashtra": "MH",
    "Odisha": "OR",
    "Rajasthan": "RJ",
    "Tamil Nadu": "TN",
    "Telangana": "TS",
    "Uttar Pradesh": "UP",
    "West Bengal": "WB",
}

STATE_TERM_BASELINES = {
    "Delhi": 40,
    "Maharashtra": 44,
    "Karnataka": 43,
    "Tamil Nadu": 46,
    "Telangana": 48,
    "Gujarat": 50,
    "Haryana": 47,
    "Kerala": 52,
    "Andhra Pradesh": 55,
    "Madhya Pradesh": 58,
    "Rajasthan": 60,
    "Assam": 65,
    "Odisha": 76,
    "West Bengal": 78,
    "Uttar Pradesh": 82,
    "Jharkhand": 84,
    "Bihar": 88,
}


def get_state_code(state: str) -> str:
    """Return the standard two-letter Indian state code."""
    if not state:
        return "NA"
    return STATE_CODE_MAP.get(state, state[:2].upper())


def get_state_term_baseline(state: str) -> int:
    """Return the stage-2 target baseline for a state."""
    return STATE_TERM_BASELINES.get(state, 58)


# ---------------------------------------------------------------------------
# Buyer Profiles
# ---------------------------------------------------------------------------
BUYER_PROFILES = {
    "Infosys": {"weight": 0.10, "base_terms_days": 30},
    "Wipro": {"weight": 0.08, "base_terms_days": 34},
    "Hindustan Unilever": {"weight": 0.08, "base_terms_days": 38},
    "Asian Paints": {"weight": 0.07, "base_terms_days": 40},
    "Bharti Airtel": {"weight": 0.03, "base_terms_days": 41},
    "ITC Ltd": {"weight": 0.07, "base_terms_days": 42},
    "Maruti Suzuki": {"weight": 0.07, "base_terms_days": 43},
    "Bajaj Auto": {"weight": 0.06, "base_terms_days": 44},
    "Tata Motors": {"weight": 0.08, "base_terms_days": 45},
    "Mahindra & Mahindra": {"weight": 0.07, "base_terms_days": 47},
    "Godrej Consumer": {"weight": 0.05, "base_terms_days": 48},
    "Larsen & Toubro": {"weight": 0.05, "base_terms_days": 50},
    "Flipkart": {"weight": 0.08, "base_terms_days": 58},
    "Adani Enterprises": {"weight": 0.04, "base_terms_days": 72},
    "Reliance Retail": {"weight": 0.07, "base_terms_days": 85},
}


# ---------------------------------------------------------------------------
# Stage-2 Aggregation Helpers
# ---------------------------------------------------------------------------
def compute_fairness_score(payment_terms_days: int) -> int:
    """Convert payment terms into a 0-100 fairness score where higher is fairer."""
    raw_score = 100 - ((payment_terms_days - 30) * 1.35)
    return int(round(max(0, min(100, raw_score))))


def classify_bias_level(avg_fairness_score: float) -> str:
    """Map an average fairness score to the stage-2 heatmap label."""
    if avg_fairness_score >= 70:
        return "fair"
    if avg_fairness_score >= 40:
        return "moderate"
    return "severe"


def get_badge(fairness_score: int | float) -> str:
    """Return the leaderboard badge for a given fairness score."""
    if fairness_score >= 80:
        return "gold"
    if fairness_score >= 60:
        return "silver"
    if fairness_score >= 40:
        return "bronze"
    return "red_flag"


# ---------------------------------------------------------------------------
# Environment Helpers
# ---------------------------------------------------------------------------
def get_allowed_origins() -> list[str]:
    """Parse ALLOWED_ORIGINS env var into a list."""
    raw = os.getenv(
        "ALLOWED_ORIGINS",
        "http://localhost:3000,http://localhost:5000,http://127.0.0.1:3000,http://127.0.0.1:5000",
    )
    return [origin.strip() for origin in raw.split(",") if origin.strip()]


def is_bigquery_enabled() -> bool:
    """Check if BigQuery mode is enabled."""
    return os.getenv("BIGQUERY_ENABLED", "false").lower() == "true"
