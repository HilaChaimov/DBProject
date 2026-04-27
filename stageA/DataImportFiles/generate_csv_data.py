import csv
import random
from datetime import date, timedelta

random.seed(42)

# =========================
# Configuration
# =========================
NUM_CUSTOMERS = 500
NUM_ATTRACTIONS = 500
NUM_TICKETS = 20000
NUM_REVIEWS = 20000
NUM_REACTIONS = 500
NUM_REPORTS = 500

# =========================
# Helpers
# =========================
first_names = [
    "Noa", "Maya", "Dana", "Yael", "Hila", "Tamar", "Lior", "Shira", "Amit", "Roni",
    "Eden", "Neta", "Adi", "Bar", "Moran", "Gal", "Ofir", "Tal", "Yarden", "Shelly"
]

last_names = [
    "Cohen", "Levi", "Mizrahi", "Biton", "Azulay", "Peretz", "David", "Avraham", "Sharabi", "Malka",
    "Ben David", "Aharon", "Ohana", "Abutbul", "Yosef", "Haddad", "Buzaglo", "Katz", "Mor", "Dayan"
]

cities = [
    "Tel Aviv", "Jerusalem", "Haifa", "Eilat", "Ramat Gan", "Netanya", "Ashdod", "Beer Sheva", "Nazareth", "Holon"
]

categories = [
    "Museum", "Water Park", "Zoo", "Adventure", "Amusement Park", "Nature", "Science", "History", "Kids", "Family"
]

ticket_statuses = ["active", "used", "cancelled"]
reaction_types = ["like", "dislike"]
report_reasons = ["Spam", "Offensive language", "Misleading information", "Harassment", "Irrelevant content"]
admin_decisions = ["Approved", "Rejected", None]

review_titles = [
    "Amazing", "Very good", "Nice place", "Not bad", "Could be better",
    "Highly recommended", "Disappointing", "Fun day", "Worth it", "Great for families"
]

review_contents = [
    "Everything was well organized and enjoyable.",
    "The place was clean and the staff were helpful.",
    "I had a good experience overall.",
    "It was too crowded and not as expected.",
    "A nice attraction for families and children.",
    "The visit was fun and memorable.",
    "Some parts were good, but there is room for improvement.",
    "The attraction was interesting and worth the price.",
    "I expected more from the experience.",
    "I would recommend this place to others."
]

descriptions = [
    "Popular attraction with many activities.",
    "Suitable for children and families.",
    "Open all year round.",
    "Offers guided tours and events.",
    "Includes food stands and rest areas."
]


def random_date(start: date, end: date) -> str:
    delta = (end - start).days
    return (start + timedelta(days=random.randint(0, delta))).isoformat()


def random_phone(i: int) -> str:
    return f"05{random.randint(0,9)}{random.randint(1000000, 9999999)}"


def random_name() -> str:
    return f"{random.choice(first_names)} {random.choice(last_names)}"


def random_email(i: int) -> str:
    return f"user{i}@example.com"


# =========================
# Generate CUSTOMER
# =========================
with open("customer.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["customer_id", "full_name", "email", "phone", "register_date"])

    for i in range(1, NUM_CUSTOMERS + 1):
        writer.writerow([
            i,
            random_name(),
            random_email(i),
            random_phone(i),
            random_date(date(2023, 1, 1), date(2024, 12, 31))
        ])

# =========================
# Generate ATTRACTION
# =========================
with open("attraction.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["attraction_id", "attraction_name", "city", "category", "description"])

    for i in range(1, NUM_ATTRACTIONS + 1):
        writer.writerow([
            i,
            f"Attraction {i}",
            random.choice(cities),
            random.choice(categories),
            random.choice(descriptions)
        ])

# =========================
# Generate TICKET
# =========================
with open("ticket.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow([
        "ticket_id", "purchase_date", "visit_date", "price",
        "ticket_status", "customer_id", "attraction_id"
    ])

    for i in range(1, NUM_TICKETS + 1):
        purchase = date(2024, 1, 1) + timedelta(days=random.randint(0, 300))
        visit = purchase + timedelta(days=random.randint(1, 60))
        writer.writerow([
            i,
            purchase.isoformat(),
            visit.isoformat(),
            round(random.uniform(20, 500), 2),
            random.choice(ticket_statuses),
            random.randint(1, NUM_CUSTOMERS),
            random.randint(1, NUM_ATTRACTIONS)
        ])

# =========================
# Generate REVIEW
# =========================
with open("review.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow([
        "review_id", "rating", "title", "content",
        "review_date", "is_deleted", "deleted_date", "ticket_id"
    ])

    for i in range(1, NUM_REVIEWS + 1):
        is_deleted = random.choice([True, False])
        review_date = random_date(date(2024, 1, 1), date(2025, 3, 1))
        deleted_date = random_date(date(2025, 3, 2), date(2025, 4, 1)) if is_deleted else ""
        writer.writerow([
            i,
            random.randint(1, 5),
            random.choice(review_titles),
            random.choice(review_contents),
            review_date,
            str(is_deleted).lower(),
            deleted_date,
            random.randint(1, NUM_TICKETS)
        ])

# =========================
# Generate REVIEWREACTION
# =========================
with open("reviewreaction.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow([
        "reaction_id", "reaction_type", "reaction_date", "review_id", "customer_id"
    ])

    for i in range(1, NUM_REACTIONS + 1):
        writer.writerow([
            i,
            random.choice(reaction_types),
            random_date(date(2024, 1, 1), date(2025, 4, 1)),
            random.randint(1, NUM_REVIEWS),
            random.randint(1, NUM_CUSTOMERS)
        ])

# =========================
# Generate REVIEWREPORT
# =========================
with open("reviewreport.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow([
        "report_id", "report_reason", "report_description", "report_date",
        "admin_decision", "decision_date", "customer_id", "review_id"
    ])

    for i in range(1, NUM_REPORTS + 1):
        decision = random.choice(admin_decisions)
        decision_date = random_date(date(2025, 1, 1), date(2025, 4, 1)) if decision else ""
        writer.writerow([
            i,
            random.choice(report_reasons),
            "Automatically generated report description",
            random_date(date(2024, 1, 1), date(2025, 3, 1)),
            decision if decision else "",
            decision_date,
            random.randint(1, NUM_CUSTOMERS),
            random.randint(1, NUM_REVIEWS)
        ])

print("CSV files generated successfully.")