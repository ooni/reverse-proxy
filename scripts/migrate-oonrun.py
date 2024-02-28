import json
from collections import defaultdict
from datetime import timedelta
from clickhouse_driver import Client
from pprint import pprint

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
        "nettests": desc["nettests"]
    }
    rows_by_id[row["oonirun_link_id"]].append(row)

oonirun_links_with_revision = []
for runlink_id, rows in rows_by_id.items():
    revision = 1
    for oonirun_link in sorted(rows, key=lambda r: r["date_created"]):
        oonirun_link["revision"] = revision
        oonirun_links_with_revision.append(oonirun_link)
        revision += 1

with open("oonirun_links_with_revision.json", "w") as out_file:
    json.dump(oonirun_links_with_revision, out_file, default=str)
