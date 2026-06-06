"""
Geofence router — pure maths, fully stateless.

POST /geo/check
  Body: { lat, lng, office_lat, office_lng, radius_meters }
  Returns: { inside: bool, distance_meters: float }
"""
from fastapi import APIRouter
from pydantic import BaseModel
from geopy.distance import geodesic

router = APIRouter()


class GeoCheckRequest(BaseModel):
    lat: float
    lng: float
    office_lat: float
    office_lng: float
    radius_meters: float = 100.0


@router.post("/check", summary="Check if coordinates are inside an office geofence")
async def check_geofence(body: GeoCheckRequest):
    employee_point = (body.lat, body.lng)
    office_point = (body.office_lat, body.office_lng)
    distance_m = geodesic(employee_point, office_point).meters
    return {
        "inside": distance_m <= body.radius_meters,
        "distance_meters": round(distance_m, 2),
        "radius_meters": body.radius_meters,
    }
