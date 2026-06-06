"""
Demo data seeder.

Populates 30 days of realistic attendance records for all employees in a given org.
Run AFTER creating a guest account via the API (you'll have an org_id).

Usage:
    python seed.py --org-id <UUID>

Or to seed ALL demo orgs:
    python seed.py --all

The seeder creates attendance records with:
  - Realistic check-in times (8:45–9:30 AM)
  - Realistic check-out times (5:30–7:00 PM)
  - ~85% attendance rate with random absences
  - Random attendance methods (qr / geo / face)
"""
import asyncio
import argparse
import random
from datetime import date, datetime, timedelta, timezone, time

from sqlalchemy import select

from app.database import AsyncSessionLocal, create_db_tables
from app.models.attendance import AttendanceRecord
from app.models.organization import Organization
from app.models.user import User


METHODS = ["qr", "geo", "face"]
ATTENDANCE_RATE = 0.85  # 85% chance of being present on any working day

def random_checkin(day: date) -> datetime:
    """Random check-in between 8:45 and 9:30."""
    minute = random.randint(8 * 60 + 45, 9 * 60 + 30)
    return datetime(day.year, day.month, day.day, minute // 60, minute % 60, tzinfo=timezone.utc)


def random_checkout(checkin: datetime) -> datetime:
    """Random check-out 7.5 to 10 hours after check-in."""
    minutes_worked = random.randint(450, 600)  # 7.5h to 10h
    return checkin + timedelta(minutes=minutes_worked)


async def seed_org(org_id: str, days: int = 30):
    async with AsyncSessionLocal() as db:
        # Fetch employees
        result = await db.execute(
            select(User).where(
                User.org_id == org_id,
                User.role == "employee",
                User.is_active == True,
            )
        )
        employees = result.scalars().all()
        if not employees:
            print(f"  No employees found in org {org_id}")
            return

        print(f"  Seeding {len(employees)} employees × {days} days...")
        today = date.today()
        start = today - timedelta(days=days - 1)
        records_created = 0

        for emp in employees:
            current = start
            while current <= today:
                if current.weekday() >= 5:  # skip weekends
                    current += timedelta(days=1)
                    continue

                # Check if record already exists
                existing = await db.execute(
                    select(AttendanceRecord).where(
                        AttendanceRecord.user_id == emp.id,
                        AttendanceRecord.date == current,
                    )
                )
                if existing.scalar_one_or_none():
                    current += timedelta(days=1)
                    continue

                # Decide presence
                if random.random() < ATTENDANCE_RATE:
                    checkin = random_checkin(current)
                    checkout = random_checkout(checkin)
                    duration = int((checkout - checkin).total_seconds() / 60)
                    method = random.choice(METHODS)

                    record = AttendanceRecord(
                        user_id=emp.id,
                        org_id=org_id,
                        date=current,
                        check_in=checkin,
                        check_out=checkout if current < today else None,  # today might not have checkout
                        duration_minutes=duration if current < today else None,
                        method=method,
                        status="present",
                        location={"lat": 28.6139, "lng": 77.2090, "accuracy": 10.0} if method == "geo" else None,
                    )
                    db.add(record)
                    records_created += 1

                current += timedelta(days=1)

        await db.commit()
        print(f"  Created {records_created} attendance records.")


async def main():
    parser = argparse.ArgumentParser(description="Seed demo attendance data")
    parser.add_argument("--org-id", help="Specific org UUID to seed")
    parser.add_argument("--all", action="store_true", help="Seed all demo orgs")
    parser.add_argument("--days", type=int, default=30, help="Days of history to generate")
    args = parser.parse_args()

    await create_db_tables()

    async with AsyncSessionLocal() as db:
        if args.all:
            result = await db.execute(select(Organization).where(Organization.is_demo == True))
            orgs = result.scalars().all()
        elif args.org_id:
            result = await db.execute(select(Organization).where(Organization.id == args.org_id))
            orgs = result.scalars().all()
        else:
            parser.print_help()
            return

    for org in orgs:
        print(f"\nSeeding org: {org.name} ({org.id})")
        await seed_org(str(org.id), days=args.days)

    print("\nDone!")


if __name__ == "__main__":
    asyncio.run(main())
