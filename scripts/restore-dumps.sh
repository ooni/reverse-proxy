#!/bin/bash
# Restore schema and sampled dumps to running clickhouse instance
# This script is to be run manually from with CWD set to contains the dumps and
# schema files generated from `dump-tables-ch.sh`
# See dump-tables-ch.sh for instruction on it's usage
for schema_file in *schema.sql;do
    cat $schema_file | clickhouse-client;
done

dump_ts="20240202"
TABLES=(
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
for table in "${TABLES[@]}"; do
    echo "Restoring ${table}"
    cat ${dump_ts}-${table}_dump.clickhouse | clickhouse-client --query="INSERT INTO ${table} FORMAT Native"
done

echo "Restoring fastpath"
gzip -cd 20240109T1314-fastpath.clickhouse.gz | clickhouse-client --query="INSERT INTO fastpath FORMAT Native"
