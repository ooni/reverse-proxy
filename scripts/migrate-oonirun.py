"""
Dump OONI Run links for clickhouse into postgres by performing appropriate
transformations.

To setup run:

pip install psycopg2 clickhouse-driver

Then:

OONI_PG_PASSWORD=XXXX python migrate-oonirun.py
"""
import os
import json
from pprint import pprint
from collections import defaultdict
from datetime import timedelta

from clickhouse_driver import Client
import psycopg2

def dump_oonirun_links_clickhouse():
    client = Client("localhost")

    rows, cols = client.execute("SELECT * FROM oonirun", with_column_types=True)
    col_names = list(map(lambda x: x[0], cols))

    rows_by_id = defaultdict(list)

    for row in rows:
        d = dict(zip(col_names, row))
        desc = json.loads(d["descriptor"])
        row = {
            "oonirun_link_id": d["ooni_run_link_id"],
            "date_created": d["descriptor_creation_time"],
            "date_updated": d["translation_creation_time"],
            "creator_account_id": d["creator_account_id"],
            "revision": None,
            "expiration_date": d["descriptor_creation_time"] + timedelta(days=6 * 30),
            "name": desc["name"],
            "name_intl": None,
            "short_description": desc["short_description"],
            "short_description_intl": None,
            "description": desc["description"],
            "description_intl": None,
            "icon": desc["icon"],
            "color": desc.get("color"),
            "nettests": json.dumps(desc["nettests"])
        }
        rows_by_id[row["oonirun_link_id"]].append(row)

    oonirun_links_with_revision = []
    for runlink_id, rows in rows_by_id.items():
        revision = 1
        for oonirun_link in sorted(rows, key=lambda r: r["date_created"]):
            oonirun_link["revision"] = revision
            oonirun_links_with_revision.append(oonirun_link)
            revision += 1
    return oonirun_links_with_revision

def insert_run_links_postgresql(data_to_insert):
    db_params = {
        'dbname': 'oonipg',
        'user': 'oonipg',
        'password': os.environ["OONI_PG_PASSWORD"],
        'host': 'postgres.tier0.prod.ooni.nu'
    }

    conn = psycopg2.connect(**db_params)
    cur = conn.cursor()

    col_names = list(data_to_insert[0].keys())
    col_values = ["%s"]*len(col_names)
    insert_query = f'INSERT INTO oonirun ({",".join(col_names)}) VALUES ({",".join(col_values)})'

    insert_count = 0
    try:
        for row in data_to_insert:
            values = [row[cn] for cn in col_names]
            cur.execute(insert_query, values)
            insert_count += 1
        conn.commit()
        print("Data inserted successfully")
    except Exception as e:
        conn.rollback()
        print(f"Failed after {insert_count} rows at row:")
        print(row)
        print(f"An error occurred: {e}")
        raise e
    finally:
        # Close the cursor and connection
        cur.close()
        conn.close()

insert_run_links_postgresql(dump_oonirun_links_clickhouse())
