## Replicating MergeTree tables

Notes on how to go about converting a MergeTree family table to a replicated table, while minimizing downtime.

See the following links for more information:

- https://kb.altinity.com/altinity-kb-setup-and-maintenance/altinity-kb-converting-mergetree-to-replicated/
- https://clickhouse.com/docs/en/operations/system-tables/replicas
- https://clickhouse.com/docs/en/architecture/replication#verify-that-clickhouse-keeper-is-running
- https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/replication
- https://clickhouse.com/docs/en/operations/server-configuration-parameters/settings

### Workflow

You should first create the replicated database cluster following the
instructions at the [clickhouse docs](https://clickhouse.com/docs/en/architecture/replication).

The ooni-devops repo has a role called `oonidata_clickhouse` that does that by using the [idealista.clickhouse_role](https://github.com/idealista/clickhouse_role).

Once the cluster is created you can proceed with creating a DATABASE on the cluster by running:

```
CREATE DATABASE ooni ON CLUSTER oonidata_cluster
```

There are now a few options to go about doing this:

1. You just create the new replicated tables and perform a copy into the destination database by running on the source database the following:

```
INSERT INTO FUNCTION
remote('destination-database.ooni.nu', 'obs_web', 'USER', 'PASSWORD')
SELECT * from obs_web
```

This will require duplicating the data and might not be feasible.

2. If you already have all the data setup on one host and you just want to convert the database into a replicate one, you can do the following:

We assume there are 2 tables: `obs_web_bak` (which is the source table) and
`obs_web` which is the destination table. We also assume a single shard and
multiple replicas.

First create the destination replicated table. To retrieve the table create query you can run:

```sql
select create_table_query
from system.tables
where database = 'default' and table = 'obs_web'
```

You should then modify the table to make use of the `ReplicateReplacingMergeTree` engine:

```sql
CREATE TABLE ooni.obs_web (`measurement_uid` String, `observation_idx` UInt16, `input` Nullable(String), `report_id` String, `measurement_start_time` DateTime64(3, 'UTC'), `software_name` String, `software_version` String, `test_name` String, `test_version` String, `bucket_date` String, `probe_asn` UInt32, `probe_cc` String, `probe_as_org_name` String, `probe_as_cc` String, `probe_as_name` String, `network_type` String, `platform` String, `origin` String, `engine_name` String, `engine_version` String, `architecture` String, `resolver_ip` String, `resolver_asn` UInt32, `resolver_cc` String, `resolver_as_org_name` String, `resolver_as_cc` String, `resolver_is_scrubbed` UInt8, `resolver_asn_probe` UInt32, `resolver_as_org_name_probe` String, `created_at` Nullable(DateTime('UTC')), `target_id` Nullable(String), `hostname` Nullable(String), `transaction_id` Nullable(UInt16), `ip` Nullable(String), `port` Nullable(UInt16), `ip_asn` Nullable(UInt32), `ip_as_org_name` Nullable(String), `ip_as_cc` Nullable(String), `ip_cc` Nullable(String), `ip_is_bogon` Nullable(UInt8), `dns_query_type` Nullable(String), `dns_failure` Nullable(String), `dns_engine` Nullable(String), `dns_engine_resolver_address` Nullable(String), `dns_answer_type` Nullable(String), `dns_answer` Nullable(String), `dns_answer_asn` Nullable(UInt32), `dns_answer_as_org_name` Nullable(String), `dns_t` Nullable(Float64), `tcp_failure` Nullable(String), `tcp_success` Nullable(UInt8), `tcp_t` Nullable(Float64), `tls_failure` Nullable(String), `tls_server_name` Nullable(String), `tls_version` Nullable(String), `tls_cipher_suite` Nullable(String), `tls_is_certificate_valid` Nullable(UInt8), `tls_end_entity_certificate_fingerprint` Nullable(String), `tls_end_entity_certificate_subject` Nullable(String), `tls_end_entity_certificate_subject_common_name` Nullable(String), `tls_end_entity_certificate_issuer` Nullable(String), `tls_end_entity_certificate_issuer_common_name` Nullable(String), `tls_end_entity_certificate_san_list` Array(String), `tls_end_entity_certificate_not_valid_after` Nullable(DateTime64(3, 'UTC')), `tls_end_entity_certificate_not_valid_before` Nullable(DateTime64(3, 'UTC')), `tls_certificate_chain_length` Nullable(UInt16), `tls_certificate_chain_fingerprints` Array(String), `tls_handshake_read_count` Nullable(UInt16), `tls_handshake_write_count` Nullable(UInt16), `tls_handshake_read_bytes` Nullable(UInt32), `tls_handshake_write_bytes` Nullable(UInt32), `tls_handshake_last_operation` Nullable(String), `tls_handshake_time` Nullable(Float64), `tls_t` Nullable(Float64), `http_request_url` Nullable(String), `http_network` Nullable(String), `http_alpn` Nullable(String), `http_failure` Nullable(String), `http_request_body_length` Nullable(UInt32), `http_request_method` Nullable(String), `http_runtime` Nullable(Float64), `http_response_body_length` Nullable(Int32), `http_response_body_is_truncated` Nullable(UInt8), `http_response_body_sha1` Nullable(String), `http_response_status_code` Nullable(UInt16), `http_response_header_location` Nullable(String), `http_response_header_server` Nullable(String), `http_request_redirect_from` Nullable(String), `http_request_body_is_truncated` Nullable(UInt8), `http_t` Nullable(Float64), `probe_analysis` Nullable(String))
ENGINE = ReplicatedReplacingMergeTree(
'/clickhouse/{cluster}/tables/{database}/{table}/{shard}',
'{replica}'
)
PARTITION BY concat(substring(bucket_date, 1, 4), substring(bucket_date, 6, 2))
PRIMARY KEY (measurement_uid, observation_idx)
ORDER BY (measurement_uid, observation_idx, measurement_start_time, probe_cc, probe_asn) SETTINGS index_granularity = 8192
```

Check all the partitions that exist for the source table and produce ALTER queries to map them from the source to the destination:

```sql
SELECT DISTINCT 'ALTER TABLE ooni.obs_web ATTACH PARTITION ID \'' || partition_id || '\' FROM obs_web_bak;' from system.parts WHERE table = 'obs_web_bak' AND active;
```

While you are running the following, you should stop all merges by running:

```sql
SYSTEM STOP MERGES;
```

This can then be scripted like so:

```sh
clickhouse-client -q "SELECT DISTINCT 'ALTER TABLE ooni.obs_web ATTACH PARTITION ID \'' || partition_id || '\' FROM obs_web_bak;' from system.parts WHERE table = 'obs_web_bak' format TabSeparatedRaw" | clickhouse-client -u write --password XXXX -mn
```

You will now have a replicated table existing on one of the replicas.

Then you shall for each other replica in the set manually create the table, but this time pass in it explicitly the zookeeper path.

You can get the zookeeper path by running the following on the first replica you have setup

```sql
SELECT zookeeper_path FROM system.replicas WHERE table = 'obs_web';
```

For each replica you will then have to create the tables like so:

```sql
CREATE TABLE ooni.obs_web (`measurement_uid` String, `observation_idx` UInt16, `input` Nullable(String), `report_id` String, `measurement_start_time` DateTime64(3, 'UTC'), `software_name` String, `software_version` String, `test_name` String, `test_version` String, `bucket_date` String, `probe_asn` UInt32, `probe_cc` String, `probe_as_org_name` String, `probe_as_cc` String, `probe_as_name` String, `network_type` String, `platform` String, `origin` String, `engine_name` String, `engine_version` String, `architecture` String, `resolver_ip` String, `resolver_asn` UInt32, `resolver_cc` String, `resolver_as_org_name` String, `resolver_as_cc` String, `resolver_is_scrubbed` UInt8, `resolver_asn_probe` UInt32, `resolver_as_org_name_probe` String, `created_at` Nullable(DateTime('UTC')), `target_id` Nullable(String), `hostname` Nullable(String), `transaction_id` Nullable(UInt16), `ip` Nullable(String), `port` Nullable(UInt16), `ip_asn` Nullable(UInt32), `ip_as_org_name` Nullable(String), `ip_as_cc` Nullable(String), `ip_cc` Nullable(String), `ip_is_bogon` Nullable(UInt8), `dns_query_type` Nullable(String), `dns_failure` Nullable(String), `dns_engine` Nullable(String), `dns_engine_resolver_address` Nullable(String), `dns_answer_type` Nullable(String), `dns_answer` Nullable(String), `dns_answer_asn` Nullable(UInt32), `dns_answer_as_org_name` Nullable(String), `dns_t` Nullable(Float64), `tcp_failure` Nullable(String), `tcp_success` Nullable(UInt8), `tcp_t` Nullable(Float64), `tls_failure` Nullable(String), `tls_server_name` Nullable(String), `tls_version` Nullable(String), `tls_cipher_suite` Nullable(String), `tls_is_certificate_valid` Nullable(UInt8), `tls_end_entity_certificate_fingerprint` Nullable(String), `tls_end_entity_certificate_subject` Nullable(String), `tls_end_entity_certificate_subject_common_name` Nullable(String), `tls_end_entity_certificate_issuer` Nullable(String), `tls_end_entity_certificate_issuer_common_name` Nullable(String), `tls_end_entity_certificate_san_list` Array(String), `tls_end_entity_certificate_not_valid_after` Nullable(DateTime64(3, 'UTC')), `tls_end_entity_certificate_not_valid_before` Nullable(DateTime64(3, 'UTC')), `tls_certificate_chain_length` Nullable(UInt16), `tls_certificate_chain_fingerprints` Array(String), `tls_handshake_read_count` Nullable(UInt16), `tls_handshake_write_count` Nullable(UInt16), `tls_handshake_read_bytes` Nullable(UInt32), `tls_handshake_write_bytes` Nullable(UInt32), `tls_handshake_last_operation` Nullable(String), `tls_handshake_time` Nullable(Float64), `tls_t` Nullable(Float64), `http_request_url` Nullable(String), `http_network` Nullable(String), `http_alpn` Nullable(String), `http_failure` Nullable(String), `http_request_body_length` Nullable(UInt32), `http_request_method` Nullable(String), `http_runtime` Nullable(Float64), `http_response_body_length` Nullable(Int32), `http_response_body_is_truncated` Nullable(UInt8), `http_response_body_sha1` Nullable(String), `http_response_status_code` Nullable(UInt16), `http_response_header_location` Nullable(String), `http_response_header_server` Nullable(String), `http_request_redirect_from` Nullable(String), `http_request_body_is_truncated` Nullable(UInt8), `http_t` Nullable(Float64), `probe_analysis` Nullable(String))
ENGINE = ReplicatedReplacingMergeTree(
'/clickhouse/oonidata_cluster/tables/ooni/obs_web/01',
'{replica}'
)
PARTITION BY concat(substring(bucket_date, 1, 4), substring(bucket_date, 6, 2))
PRIMARY KEY (measurement_uid, observation_idx)
ORDER BY (measurement_uid, observation_idx, measurement_start_time, probe_cc, probe_asn) SETTINGS index_granularity = 8192
```

You will then have to manually copy the data over to the destination replica from the source.

The data lives inside of `/var/lib/clickhouse/data/{database_name}/{table_name}`

Once the data has been copied over you should now have replicated the data and you can resume merges on all database by running:

```sql
SYSTEM START MERGES;
```

### Creating tables on clusters

```sql
CREATE TABLE ooni.obs_web_ctrl ON CLUSTER oonidata_cluster
(`measurement_uid` String, `observation_idx` UInt16, `input` Nullable(String), `report_id` String, `measurement_start_time` DateTime64(3, 'UTC'), `software_name` String, `software_version` String, `test_name` String, `test_version` String, `bucket_date` String, `hostname` String, `created_at` Nullable(DateTime64(3, 'UTC')), `ip` String, `port` Nullable(UInt16), `ip_asn` Nullable(UInt32), `ip_as_org_name` Nullable(String), `ip_as_cc` Nullable(String), `ip_cc` Nullable(String), `ip_is_bogon` Nullable(UInt8), `dns_failure` Nullable(String), `dns_success` Nullable(UInt8), `tcp_failure` Nullable(String), `tcp_success` Nullable(UInt8), `tls_failure` Nullable(String), `tls_success` Nullable(UInt8), `tls_server_name` Nullable(String), `http_request_url` Nullable(String), `http_failure` Nullable(String), `http_success` Nullable(UInt8), `http_response_body_length` Nullable(Int32))
ENGINE = ReplicatedReplacingMergeTree(
'/clickhouse/{cluster}/tables/{database}/{table}/{shard}',
'{replica}'
)
PARTITION BY concat(substring(bucket_date, 1, 4), substring(bucket_date, 6, 2))
PRIMARY KEY (measurement_uid, observation_idx) ORDER BY (measurement_uid, observation_idx, measurement_start_time, hostname) SETTINGS index_granularity = 8192
```
