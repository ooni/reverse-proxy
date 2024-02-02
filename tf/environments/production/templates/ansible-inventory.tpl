[clickhouse_servers]
%{ for hostname in clickhouse_servers ~}
${hostname}
%{ endfor ~}