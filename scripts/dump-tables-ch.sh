#!/bin/bash
set -euxo pipefail
# This is to be run manually on the clickhouse host to dump schemas and table dumps
# You may want to make some tweaks to the dumping rules in order avoid dumping
# too much data (eg. fastpath)
# You should then scp the data over to the target host manually, by running:
# $ scp * clickhouse-instance2:/var/lib/clickhouse/ooni-dumps/
TABLES=(
"fastpath"
"jsonl"
"url_priorities"
"citizenlab"
"citizenlab_flip"
"test_groups"
"accounts"
"session_expunge"
"msmt_feedback"
"fingerprints_dns"
"fingerprints_http"
"asnmeta"
"counters_test_list"
"counters_asn_test_list"
"incidents"
"oonirun"
)

dump_dir="./dumps"
current_date=$(date +%Y%m%d)

# Directory to store the dumps
mkdir -p "$dump_dir"

# Iterate over each table
for table in "${TABLES[@]}"; do
    # Define file names for schema and data dump
    schema_file="${dump_dir}/${current_date}-${table}_schema.sql"
    data_file="${dump_dir}/${current_date}-${table}_dump.clickhouse"

    # Dump the table schema
    echo "[+] dumping schema $schema_file"
    clickhouse-client --query="SHOW CREATE TABLE ${table} FORMAT TabSeparatedRaw" > "$schema_file"

    # Dump the table data in ClickHouse native format
    echo "[+] dumping table data $data_file"
    clickhouse-client --query="SELECT * FROM ${table} INTO OUTFILE '${data_file}' FORMAT Native"
done
