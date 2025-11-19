from __future__ import annotations

import math

from ..coverage_schemas import Site
from .grid_service import haversine_distance_km


def hata_path_loss(f_mhz: float,
                   d_km: float,
                   h_bs_m: float,
                   h_ms_m: float) -> float:
    """
    Okumura-Hata model for urban areas.

    f_mhz: 150–1500 MHz
    h_bs_m: 30–200 m
    h_ms_m: 1–10 m
    d_km: typical 1–20 km (can be used beyond as an approximation)
    """
    if d_km < 0.001:
        d_km = 0.001

    a_hms = (1.1 * math.log10(f_mhz) - 0.7) * h_ms_m - (1.56 * math.log10(f_mhz) - 0.8)

    pl = (
        69.55
        + 26.16 * math.log10(f_mhz)
        - 13.82 * math.log10(h_bs_m)
        - a_hms
        + (44.9 - 6.55 * math.log10(h_bs_m)) * math.log10(d_km)
    )
    return pl


def calc_rx_level(
    site: Site,
    target_lat: float,
    target_lon: float,
    rx_height_m: float,
    model: str = "hata",
) -> float:
    """
    Calculate received signal level at target_lat/target_lon from a single site.

    Currently only Hata is implemented; "longley_rice" falls back to Hata as stub.
    """
    d_km = haversine_distance_km(site.lat, site.lon, target_lat, target_lon)

    if model in ("hata", "longley_rice"):
        pl = hata_path_loss(
            f_mhz=site.frequency_mhz,
            d_km=d_km,
            h_bs_m=site.antenna_height_m,
            h_ms_m=rx_height_m,
        )
    else:
        pl = hata_path_loss(
            f_mhz=site.frequency_mhz,
            d_km=d_km,
            h_bs_m=site.antenna_height_m,
            h_ms_m=rx_height_m,
        )

    prx_dbm = site.tx_power_dbm + site.antenna_gain_dbi - pl
    return prx_dbm
