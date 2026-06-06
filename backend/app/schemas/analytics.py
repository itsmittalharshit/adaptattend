import uuid
from pydantic import BaseModel


class TeamSummaryResponse(BaseModel):
    present: int
    total: int
    absent: int
    date: str
    attendance_rate: float


class TrendPoint(BaseModel):
    date: str
    count: int


class EmployeeReportResponse(BaseModel):
    employee_id: uuid.UUID
    full_name: str | None
    period_days: int
    present_days: int
    attendance_rate: float
    total_hours: float
    avg_daily_hours: float
    punctuality_score: float      # 0–100
    current_streak: int           # consecutive present days
    longest_streak: int
    records: list[dict]


class PunctualityEntry(BaseModel):
    employee_id: uuid.UUID
    full_name: str | None
    punctuality_score: float
    present_days: int
    attendance_rate: float
