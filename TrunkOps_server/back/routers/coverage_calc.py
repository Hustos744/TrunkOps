"""Endpoints for radio coverage calculation.

This router exposes a stateless calculation API that can be used
by the TrunkOps frontend to estimate trunking network coverage
for selected base stations.
"""

from __future__ import annotations

from typing import List

from fastapi import APIRouter

from ..coverage_schemas import CoverageRequest, CoverageResponse, CoverageCell
from ..services.grid_service import generate_grid
from ..services.propagation_service import calc_rx_level


router = APIRouter(
    prefix="/coverage",
    tags=["coverage"],
)

print(">>> coverage_calc router imported")


@router.post("/calc", response_model=CoverageResponse)
def calculate_coverage(
    req: CoverageRequest,
) -> CoverageResponse:
    """Calculate coverage for the given base stations and grid.

    The endpoint is intentionally stateless and does not persist
    any data. It is designed to be called from the frontend
    (e.g. Flutter app) to quickly estimate coverage on demand.
    """
    # Генеруємо сітку точок навколо центру
    points = generate_grid(
        center_lat=req.grid.center_lat,
        center_lon=req.grid.center_lon,
        radius_km=req.grid.radius_km,
        step_m=req.grid.step_m,
    )

    cells: List[CoverageCell] = []

    for lat, lon in points:
        best_rx: float | None = None

        # Шукаємо найкращий рівень сигналу від усіх БС
        for site in req.sites:
            rx = calc_rx_level(
                site=site,
                target_lat=lat,
                target_lon=lon,
                rx_height_m=req.rx_height_m,
                model=req.model,
            )
            if best_rx is None or rx > best_rx:
                best_rx = rx

        cells.append(
            CoverageCell(
                lat=lat,
                lon=lon,
                rx_level_dbm=best_rx if best_rx is not None else -200.0,
            )
        )

    return CoverageResponse(
        grid_step_m=req.grid.step_m,
        cells=cells,
    )
