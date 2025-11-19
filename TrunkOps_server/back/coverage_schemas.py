from __future__ import annotations

from typing import List, Literal
from pydantic import BaseModel, Field


class Site(BaseModel):
    """Parameters of a base station used for coverage calculations."""
    id: str = Field(..., description="Base station identifier")
    lat: float = Field(..., description="Latitude of the base station, degrees")
    lon: float = Field(..., description="Longitude of the base station, degrees")
    tx_power_dbm: float = Field(..., description="Transmitter power, dBm")
    antenna_gain_dbi: float = Field(0.0, description="Base station antenna gain, dBi")
    antenna_height_m: float = Field(..., description="Base station antenna height above ground, m")
    frequency_mhz: float = Field(..., description="Carrier frequency, MHz (e.g., 410)")


class GridConfig(BaseModel):
    """Grid configuration for coverage calculation."""
    center_lat: float = Field(..., description="Latitude of grid center")
    center_lon: float = Field(..., description="Longitude of grid center")
    radius_km: float = Field(..., description="Radius of calculation area, km")
    step_m: float = Field(..., description="Grid step over the surface, meters")


class CoverageRequest(BaseModel):
    """Request body for coverage calculation."""
    sites: List[Site]
    rx_height_m: float = Field(1.5, description="Subscriber antenna height, m")
    grid: GridConfig
    model: Literal["hata", "longley_rice"] = Field(
        "hata",
        description="Radio propagation model; currently only 'hata' is implemented.",
    )


class CoverageCell(BaseModel):
    """Single grid cell with calculated received level."""
    lat: float
    lon: float
    rx_level_dbm: float


class CoverageResponse(BaseModel):
    """Response with calculated coverage grid."""
    crs: str = "EPSG:4326"
    grid_step_m: float
    cells: List[CoverageCell]
