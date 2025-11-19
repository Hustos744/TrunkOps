"""Package initialization for routers.

This file allows Python to treat the `routers` directory as a
package so that modules can be imported using the
`TrunkOps_server.back.routers` namespace.
"""

__all__ = [
    "auth",
    "units",
    "devices",
    "nodes",
    "assets",
    "maintenance",
    "notifications",
    "audit",
    "settings",
    "coverage_calc",
]