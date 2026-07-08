import os
from contextlib import contextmanager
from dotenv import load_dotenv
import psycopg
from psycopg.rows import dict_row

load_dotenv(override=True)

class Database:
    def __init__(self):
        self.config = {
            "host": os.getenv("DB_HOST", "localhost"),
            "port": int(os.getenv("DB_PORT", "5433")), # Using 5433 for local dev by default because docker-compose maps it there
            "dbname": os.getenv("DB_NAME", os.getenv("DB_NAME_SECRET", "reportDB")),
            "user": os.getenv("DB_USER", os.getenv("DB_USER_SECRET", "hilaTalya")),
            "password": os.getenv("DB_PASS", os.getenv("DB_PASSWORD_SECRET", "hilaTalya")),
        }

    @contextmanager
    def connect(self):
        load_dotenv(override=True)
        # Update config dynamically in case env changed
        self.config = {
            "host": os.getenv("DB_HOST", "localhost"),
            "port": int(os.getenv("DB_PORT", "5433")),
            "dbname": os.getenv("DB_NAME", os.getenv("DB_NAME_SECRET", "reportDB")),
            "user": os.getenv("DB_USER", os.getenv("DB_USER_SECRET", "hilaTalya")),
            "password": os.getenv("DB_PASS", os.getenv("DB_PASSWORD_SECRET", "hilaTalya")),
        }
        conn = psycopg.connect(**self.config, row_factory=dict_row)
        try:
            yield conn
            conn.commit()
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            conn.close()

    def fetchall(self, query, params=None):
        with self.connect() as conn:
            with conn.cursor() as cur:
                cur.execute(query, params or [])
                return cur.fetchall()

    def execute(self, query, params=None):
        with self.connect() as conn:
            with conn.cursor() as cur:
                cur.execute(query, params or [])
                if cur.description:
                    return cur.fetchall()
                return []

    def get_tables(self):
        rows = self.fetchall("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_type = 'BASE TABLE'
            ORDER BY table_name;
        """)
        return [r["table_name"] for r in rows]

    def get_columns(self, table):
        return self.fetchall("""
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = %s
            ORDER BY ordinal_position;
        """, [table])

    def get_primary_key(self, table):
        rows = self.fetchall("""
            SELECT kcu.column_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu
              ON tc.constraint_name = kcu.constraint_name
             AND tc.table_schema = kcu.table_schema
            WHERE tc.constraint_type = 'PRIMARY KEY'
              AND tc.table_schema = 'public'
              AND tc.table_name = %s
            ORDER BY kcu.ordinal_position;
        """, [table])
        return [r["column_name"] for r in rows]

    def get_foreign_keys(self, table):
        rows = self.fetchall("""
            SELECT
                kcu.column_name,
                ccu.table_name AS foreign_table_name,
                ccu.column_name AS foreign_column_name
            FROM information_schema.table_constraints AS tc
            JOIN information_schema.key_column_usage AS kcu
              ON tc.constraint_name = kcu.constraint_name
             AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage AS ccu
              ON ccu.constraint_name = tc.constraint_name
             AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY'
              AND tc.table_schema = 'public'
              AND tc.table_name = %s;
        """, [table])
        return {r["column_name"]: dict(r) for r in rows}

    def best_label_column(self, table):
        columns = self.get_columns(table)
        preferred_names = ["name", "attraction_name", "customer_name", "full_name", "title", "email", "description"]
        for preferred in preferred_names:
            for c in columns:
                if c["column_name"].lower() == preferred:
                    return c["column_name"]
        for c in columns:
            if c["data_type"] in ("character varying", "text", "character"):
                return c["column_name"]
        return columns[0]["column_name"] if columns else None

    def get_fk_options(self, foreign_table, foreign_column):
        label_col = self.best_label_column(foreign_table)
        if label_col == foreign_column:
            query = f'SELECT "{foreign_column}" AS id, "{foreign_column}"::text AS label FROM "{foreign_table}" ORDER BY 1 LIMIT 500;'
        else:
            query = f'SELECT "{foreign_column}" AS id, COALESCE("{label_col}"::text, "{foreign_column}"::text) AS label FROM "{foreign_table}" ORDER BY 2 LIMIT 500;'
        rows = self.fetchall(query)
        return [(r["id"], r["label"]) for r in rows]

    def select_table_rows(self, table, limit=200):
        query = f'SELECT * FROM "{table}" LIMIT %s;'
        return self.fetchall(query, [limit])
