"""
FairTerms Fairness Engine - FastAPI application.

Exposes:
  POST /compute
  GET  /health
  GET  /aggregate/heatmap
  GET  /aggregate/leaderboard
"""

from __future__ import annotations

import os
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

from src.aggregation import (
    aggregate_heatmap,
    aggregate_heatmap_bigquery,
    aggregate_leaderboard,
    aggregate_leaderboard_bigquery,
)
from src.benchmarking import compute_benchmark, find_peers, find_peers_bigquery, load_dataset
from src.bias_detector import detect_bias
from src.metrics import compute_fairness_metrics
from src.models import (
    ComputeRequest,
    ComputeResponse,
    HeatmapAggregateResponse,
    LeaderboardAggregateResponse,
)
from src.utils import get_allowed_origins, is_bigquery_enabled, logger

load_dotenv()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load seed data once on startup when running in local CSV mode."""
    logger.info("=" * 60)
    logger.info("FairTerms Fairness Engine - Starting up")
    logger.info("=" * 60)

    if not is_bigquery_enabled():
        load_dataset()
        logger.info("Running in LOCAL CSV mode")
    else:
        logger.info("Running in BIGQUERY mode")

    logger.info("CORS origins: %s", get_allowed_origins())
    logger.info("Ready to accept requests")
    logger.info("=" * 60)
    yield
    logger.info("Fairness Engine - Shutting down")


app = FastAPI(
    title="FairTerms Fairness Engine",
    description=(
        "AI-powered bias detection and transparency platform for SME payment terms. "
        "Computes fairness metrics, benchmarking, and stage-2 aggregate datasets."
    ),
    version="1.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=get_allowed_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", tags=["info"])
async def root():
    """Service information."""
    return {
        "service": "FairTerms Fairness Engine",
        "version": "1.1.0",
        "status": "running",
        "mode": "bigquery" if is_bigquery_enabled() else "local_csv",
        "docs": "/docs",
    }


@app.get("/health", tags=["info"])
async def health():
    """Health check endpoint for Cloud Run and local development."""
    return {"status": "healthy"}


@app.get(
    "/aggregate/heatmap",
    response_model=HeatmapAggregateResponse,
    tags=["aggregates"],
    summary="Get national heatmap aggregates",
)
async def get_heatmap(
    industry: str = Query(default="all", description="Industry filter or 'all'"),
) -> HeatmapAggregateResponse:
    """Return state-level aggregate metrics for the stage-2 heatmap."""
    try:
        if is_bigquery_enabled():
            return aggregate_heatmap_bigquery(industry=industry)
        return aggregate_heatmap(industry=industry)
    except Exception as exc:
        logger.error("Heatmap aggregate error: %s", exc, exc_info=True)
        raise HTTPException(status_code=500, detail=f"Heatmap aggregation failed: {exc}") from exc


@app.get(
    "/aggregate/leaderboard",
    response_model=LeaderboardAggregateResponse,
    tags=["aggregates"],
    summary="Get buyer fairness leaderboard aggregates",
)
async def get_leaderboard(
    sort: str = Query(default="fairness_score", description="Sort field"),
    order: str = Query(default="desc", description="Sort order"),
    limit: int = Query(default=50, ge=1, le=100, description="Maximum buyers to return"),
) -> LeaderboardAggregateResponse:
    """Return buyer-level aggregate metrics for the stage-2 leaderboard."""
    try:
        if is_bigquery_enabled():
            return aggregate_leaderboard_bigquery(sort=sort, order=order, limit=limit)
        return aggregate_leaderboard(sort=sort, order=order, limit=limit)
    except Exception as exc:
        logger.error("Leaderboard aggregate error: %s", exc, exc_info=True)
        raise HTTPException(status_code=500, detail=f"Leaderboard aggregation failed: {exc}") from exc


@app.post(
    "/compute",
    response_model=ComputeResponse,
    tags=["analysis"],
    summary="Compute bias analysis for an SME",
)
async def compute(request: ComputeRequest) -> ComputeResponse:
    """Main analysis endpoint called by the Node.js backend."""
    sme = request.sme_profile
    logger.info(
        "Compute request: %s SME, pincode=%s, revenue=%s, terms=%sd",
        sme.industry,
        sme.pincode,
        f"Rs{sme.annual_revenue_inr:,}",
        request.payment_terms_days,
    )

    try:
        if is_bigquery_enabled():
            peers = find_peers_bigquery(sme)
        else:
            peers = find_peers(sme)

        logger.info("Found %s peers for benchmarking", len(peers))
        if len(peers) == 0:
            raise HTTPException(
                status_code=404,
                detail="No peer SMEs found for the given profile.",
            )

        benchmark = compute_benchmark(peers, request.payment_terms_days)
        fairness_metrics = compute_fairness_metrics(peers, protected_col="is_metro")
        bias_factors, statistical_tests = detect_bias(peers, sme)

        return ComputeResponse(
            benchmark=benchmark,
            fairness_metrics=fairness_metrics,
            bias_factors=bias_factors,
            statistical_tests=statistical_tests,
        )
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Compute error: %s", exc, exc_info=True)
        raise HTTPException(status_code=500, detail=f"Analysis failed: {exc}") from exc


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", 8080))
    host = os.getenv("HOST", "0.0.0.0")
    uvicorn.run("src.main:app", host=host, port=port, reload=True)
