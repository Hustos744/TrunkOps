from __future__ import annotations

import math
from typing import List, Tuple


def haversine_distance_km(lat1: float, lon1: float,
                          lat2: float, lon2: float) -> float:
    """Great-circle distance between two points (in kilometers)."""
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


def generate_grid(center_lat: float,
                  center_lon: float,
                  radius_km: float,
                  step_m: float) -> List[Tuple[float, float]]:
    """
    Generate list of (lat, lon) points inside a circle of radius_km
    around center_lat/center_lon, spaced approximately by step_m.
    """
    km_per_deg_lat = 111.0
    km_per_deg_lon = 111.0 * math.cos(math.radians(center_lat))

    step_km = step_m / 1000.0

    dlat_deg_step = step_km / km_per_deg_lat
    dlon_deg_step = step_km / km_per_deg_lon

    max_dlat_deg = radius_km / km_per_deg_lat
    max_dlon_deg = radius_km / km_per_deg_lon

    lat_min = center_lat - max_dlat_deg
    lat_max = center_lat + max_dlat_deg
    lon_min = center_lon - max_dlon_deg
    lon_max = center_lon + max_dlon_deg

    points: List[Tuple[float, float]] = []

    lat = lat_min
    while lat <= lat_max:
        lon = lon_min
        while lon <= lon_max:
            d_km = haversine_distance_km(center_lat, center_lon, lat, lon)
            if d_km <= radius_km:
                points.append((lat, lon))
            lon += dlon_deg_step
        lat += dlat_deg_step

    return points
