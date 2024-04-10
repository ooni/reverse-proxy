resource "aws_route53_record" "ams-pg-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ams-pg.ooni.org"
  records                          = ["142.93.237.101"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "ams-pg-test-ooni-org-_AAAA_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ams-pg-test.ooni.org"
  records                          = ["2a03:b0c0:2:d0::d86:1"]
  ttl                              = "1799"
  type                             = "AAAA"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "ams-pg-test-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ams-pg-test.ooni.org"
  records                          = ["188.166.93.143"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "ams-slack-1-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ams-slack-1.ooni.org"
  records                          = ["37.218.247.98"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "api-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "api.ooni.org"
  records                          = ["142.93.237.101"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "backend-fsn-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "backend-fsn.ooni.org"
  records                          = ["162.55.247.208"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "backend-hel-ooni-org-_AAAA_" {
  multivalue_answer_routing_policy = "false"
  name                             = "backend-hel.ooni.org"
  records                          = ["2a01:4f9:1a:9494::2"]
  ttl                              = "1799"
  type                             = "AAAA"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "backend-hel-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "backend-hel.ooni.org"
  records                          = ["65.108.192.151"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "bridge-greenhost-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "bridge-greenhost.ooni.org"
  records                          = ["37.218.243.110"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "data-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "data.ooni.org"
  records                          = ["88.198.54.12"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "deb-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "deb.ooni.org"
  records                          = ["backend-fsn.ooni.org"]
  ttl                              = "1799"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "deb-ci-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "deb-ci.ooni.org"
  records                          = ["188.166.93.143"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "docs-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "docs.ooni.org"
  records                          = ["cname.vercel-dns.com"]
  ttl                              = "1799"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "explorer-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "explorer.ooni.org"
  records                          = ["cname.vercel-dns.com"]
  ttl                              = "300"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "explorer-test-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "explorer.test.ooni.org"
  records                          = ["cname.vercel-dns.com"]
  ttl                              = "300"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "google-_domainkey-ooni-org-_TXT_" {
  multivalue_answer_routing_policy = "false"
  name                             = "google._domainkey.ooni.org"
  records                          = ["GBZ4lG5WRfJGf2Kreit9zV6aTg+CD84mQYutBhPVAsPvew8y12gn2aGCjWl3bVQHV8I63PCFKT2j9bUYIO3zLQ+ysxKxXfUBDDKUlpYV4UmXqG6qk6EWIdYc7cA6wE77CKMs8lp3XEgpGAo+pgxKWwIDAQAB", "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxrf/CaRZdg4PjQCtys4YM71kC8Qpi++r5xMdPHOVCFa3ovA+QxKS62QS0A+rvH2lZK36+fqDZYpJnNEaqKdhdOnO6muVqPKgRRDZkvDHLHcIiG3+fUIzARlfKoIOV6zdYWf99FmAYfcu5zLzxMVgz2v7oeIAj+T6swcjM22Z8uWSGDwGdPYXKr6FeismxlY/"]
  ttl                              = "3600"
  type                             = "TXT"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "grafana-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "grafana.ooni.org"
  records                          = ["monitoring.ooni.org"]
  ttl                              = "1799"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "jupyter-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "jupyter.ooni.org"
  records                          = ["monitoring.ooni.org"]
  ttl                              = "1799"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "loghost-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "loghost.ooni.org"
  records                          = ["monitoring.ooni.org"]
  ttl                              = "1799"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "matomo-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "matomo.ooni.org"
  records                          = ["37.218.242.173"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "monitoring-ooni-org-_AAAA_" {
  multivalue_answer_routing_policy = "false"
  name                             = "monitoring.ooni.org"
  records                          = ["a01:4f8:162:53e8::2"]
  ttl                              = "1799"
  type                             = "AAAA"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "monitoring-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "monitoring.ooni.org"
  records                          = ["5.9.112.244"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "netdata-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "netdata.ooni.org"
  records                          = ["monitoring.ooni.org"]
  ttl                              = "1799"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ooni.org"
  records                          = ["75.2.60.5"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "ooni-org-_MX_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ooni.org"
  records                          = ["1 ASPMX.L.GOOGLE.COM", "10 ASPMX2.GOOGLEMAIL.COM", "10 ASPMX3.GOOGLEMAIL.COM", "5 ALT1.ASPMX.L.GOOGLE.COM", "5 ALT2.ASPMX.L.GOOGLE.COM"]
  ttl                              = "3600"
  type                             = "MX"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "ooni-org-_TXT_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ooni.org"
  records                          = ["OSSRH-66913", "google-site-verification=a6qQkxsRhS_0ZpxTXyPU4tOa4Jm9ZtSn7EGHJPa4b8c", "twilio-domain-verification=c8ac43e4d3e8476d8459233d7f6a7d46", "v=spf1 include:_spf.google.com include:riseup.net ~all"]
  ttl                              = "1799"
  type                             = "TXT"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "oonidata-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "oonidata.ooni.org"
  records                          = ["142.132.254.225"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "probe-by1-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "probe-by1.ooni.org"
  records                          = ["93.84.114.133"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "probe-hk1-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "probe-hk1.ooni.org"
  records                          = ["185.74.222.11"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "probe-kg1-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "probe-kg1.ooni.org"
  records                          = ["91.213.233.204"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "probe-kz1-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "probe-kz1.ooni.org"
  records                          = ["94.131.2.196"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "probe-ru1-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "probe-ru1.ooni.org"
  records                          = ["45.144.31.248"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "probe-sa1-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "probe-sa1.ooni.org"
  records                          = ["185.241.126.49"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "probe-th1-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "probe-th1.ooni.org"
  records                          = ["27.254.153.219"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "probe-tr1-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "probe-tr1.ooni.org"
  records                          = ["194.116.190.70"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "probe-ua1-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "probe-ua1.ooni.org"
  records                          = ["45.137.155.235"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "probe-web-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "probe-web.ooni.org"
  records                          = ["ooni.github.io"]
  ttl                              = "1799"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "prometheus-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "prometheus.ooni.org"
  records                          = ["monitoring.ooni.org"]
  ttl                              = "1799"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "quic-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "quic.ooni.org"
  records                          = ["167.99.36.132"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "run-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "run.ooni.org"
  records                          = ["cname.vercel-dns.com"]
  ttl                              = "300"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "run-test-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "run.test.ooni.org"
  records                          = ["cname.vercel-dns.com"]
  ttl                              = "300"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "shinri-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "shinri.ooni.org"
  records                          = ["93.115.25.177"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "shop-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "shop.ooni.org"
  records                          = ["shops.myshopify.com"]
  ttl                              = "300"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "slack-ooni-org-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "slack.ooni.org"
  records                          = ["37.218.247.98"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "swag-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "swag.ooni.org"
  records                          = ["shops.myshopify.com"]
  ttl                              = "60"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "test-lists-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "test-lists.ooni.org"
  records                          = ["cname.vercel-dns.com"]
  ttl                              = "1799"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "test-lists-test-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "test-lists.test.ooni.org"
  records                          = ["cname.vercel-dns.com"]
  ttl                              = "1799"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "th-ooni-org-_NS_" {
  multivalue_answer_routing_policy = "false"
  name                             = "th.ooni.org"
  records                          = ["ns1.digitalocean.com"]
  ttl                              = "300"
  type                             = "NS"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "umami-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "umami.ooni.org"
  records                          = ["xhgyj5se.up.railway.app"]
  ttl                              = "60"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "url-prioritization-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "url-prioritization.ooni.org"
  records                          = ["cname.vercel-dns.com"]
  ttl                              = "1799"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "www-ooni-org-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "www.ooni.org"
  records                          = ["ooni.netlify.com"]
  ttl                              = "300"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_org
}

resource "aws_route53_record" "_amazonses-ooni-io-_TXT_" {
  multivalue_answer_routing_policy = "false"
  name                             = "_amazonses.ooni.io"
  records                          = ["azEYpr/7CEF1lHGi/rRg0hGDTOjwBFKFLU47CfHYK4Y="]
  ttl                              = "1799"
  type                             = "TXT"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "a-collector-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "a.collector.ooni.io"
  records                          = ["162.55.247.208"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "a-echo-th-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "a.echo.th.ooni.io"
  records                          = ["37.218.241.93"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "a-http-th-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "a.http.th.ooni.io"
  records                          = ["37.218.241.94"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "a-web-connectivity-th-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "a.web-connectivity.th.ooni.io"
  records                          = ["37.218.245.117"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "acme-redirect-helper-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "acme-redirect-helper.ooni.io"
  records                          = ["37.218.241.32"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "analytics-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "analytics.ooni.io"
  records                          = ["37.218.242.173"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "api-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "api.ooni.io"
  records                          = ["162.55.247.208"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "b-collector-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "b.collector.ooni.io"
  records                          = ["162.55.247.208"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "b-web-connectivity-th-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "b.web-connectivity.th.ooni.io"
  records                          = ["37.218.245.117"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "bouncer-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "bouncer.ooni.io"
  records                          = ["37.218.245.90"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "c-collector-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "c.collector.ooni.io"
  records                          = ["162.55.247.208"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "c-echo-th-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "c.echo.th.ooni.io"
  records                          = ["37.218.241.93"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "c-web-connectivity-th-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "c.web-connectivity.th.ooni.io"
  records                          = ["37.218.245.117"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "collector-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "collector.ooni.io"
  records                          = ["162.55.247.208"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "countly-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "countly.ooni.io"
  records                          = ["167.71.64.109"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "datacollector-infra-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "datacollector.infra.ooni.io"
  records                          = ["37.218.240.67"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "db-1-proteus-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "db-1.proteus.ooni.io"
  records                          = ["37.218.242.79"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "design-ooni-io-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "design.ooni.io"
  records                          = ["ooni-design.netlify.com"]
  ttl                              = "1799"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "dev-ooni-io-_NS_" {
  multivalue_answer_routing_policy = "false"
  name                             = "dev.ooni.io"
  records                          = ["ns-1320.awsdns-37.org.", "ns-1722.awsdns-23.co.uk.", "ns-311.awsdns-38.com.", "ns-646.awsdns-16.net."]
  ttl                              = "300"
  type                             = "NS"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "dw-wsm-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "dw.wsm.ooni.io"
  records                          = ["54.82.14.69"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "dw-superset-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "dw-superset.ooni.io"
  records                          = ["54.221.146.227"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "echoth-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "echoth.ooni.io"
  records                          = ["37.218.241.93"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "events-proteus-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "events.proteus.ooni.io"
  records                          = ["37.218.245.90"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "explorer-ooni-io-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "explorer.ooni.io"
  records                          = ["cname.vercel-dns.com"]
  ttl                              = "60"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "google-_domainkey-ooni-io-_TXT_" {
  multivalue_answer_routing_policy = "false"
  name                             = "google._domainkey.ooni.io"
  records                          = ["v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAi34W2DN2w5z/4do2GpVQmd18eAM7HFmDvOk16W+0k/DDtEWgwQQMRU4Jf2dUhZuIbZ60TJZVz6Vj5lbErldLPykQD+1UqShnslofePeDxZL3d9yx3y9R5OZ51X62Ym5USoTxx6Ka7rSFRuhcj2MgtBCwBiiIRx5HImdWjkaYE8agbKzsXPPnGtwcybCiMGYrS"]
  ttl                              = "1799"
  type                             = "TXT"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "gorush-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "gorush.ooni.io"
  records                          = ["37.218.247.95"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "hkgmetadb-infra-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "hkgmetadb.infra.ooni.io"
  records                          = ["37.218.240.56"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "httpth-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "httpth.ooni.io"
  records                          = ["37.218.241.94"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "irc-bouncer-service-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "irc-bouncer.service.ooni.io"
  records                          = ["37.218.240.126"]
  ttl                              = "1800"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "jupyter-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "jupyter.ooni.io"
  records                          = ["37.218.242.67"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "labs-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "labs.ooni.io"
  records                          = ["104.198.14.52"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "measurements-ooni-io-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "measurements.ooni.io"
  records                          = ["api.ooni.io"]
  ttl                              = "1800"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "measurements-beta-ooni-io-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "measurements-beta.ooni.io"
  records                          = ["api.ooni.io"]
  ttl                              = "1800"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "msg-ooni-io-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "msg.ooni.io"
  records                          = ["ooni.netlify.com"]
  ttl                              = "1799"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "notify-proteus-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "notify.proteus.ooni.io"
  records                          = ["37.218.242.67"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ooni.io"
  records                          = ["104.198.14.52"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "ooni-io-_MX_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ooni.io"
  records                          = ["1 ASPMX.L.GOOGLE.COM.ooni.io", "10 ALT3.ASPMX.L.GOOGLE.COM.ooni.io", "10 ALT4.ASPMX.L.GOOGLE.COM.ooni.io", "5 ALT1.ASPMX.L.GOOGLE.COM.ooni.io", "5 ALT2.ASPMX.L.GOOGLE.COM.ooni.io"]
  ttl                              = "1799"
  type                             = "MX"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "ooni-io-_TXT_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ooni.io"
  records                          = ["google-site-verification=e9IMJ_PebCn6CXK3_VT1acJkJR0IkKhSMe7Qakyc5sQ", "google-site-verification=iKvYSN7XqzuvT6gBjS6DjGLhwP1uRTPOjlZfOtK8mro", "v=spf1 ip4:37.218.245.43 include:_spf.google.com ~all"]
  ttl                              = "1799"
  type                             = "TXT"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "ooni-zoo-infra-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ooni-zoo.infra.ooni.io"
  records                          = ["37.218.240.138"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "orchestra-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "orchestra.ooni.io"
  records                          = ["37.218.247.95"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "orchestra-test-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "orchestra-test.ooni.io"
  records                          = ["37.218.241.87"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "orchestrate-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "orchestrate.ooni.io"
  records                          = ["37.218.245.90"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "prod-ooni-io-_NS_" {
  multivalue_answer_routing_policy = "false"
  name                             = "prod.ooni.io"
  records                          = ["ns-1325.awsdns-37.org.", "ns-1738.awsdns-25.co.uk.", "ns-349.awsdns-43.com.", "ns-619.awsdns-13.net."]
  ttl                              = "300"
  type                             = "NS"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "prometheus-infra-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "prometheus.infra.ooni.io"
  records                          = ["37.218.245.43"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "proteus-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "proteus.ooni.io"
  records                          = ["37.218.247.95"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "ps-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ps.ooni.io"
  records                          = ["162.55.247.208"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "ps-test-ooni-io-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ps-test.ooni.io"
  records                          = ["ams-pg.ooni.org"]
  ttl                              = "1799"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "ps1-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ps1.ooni.io"
  records                          = ["162.55.247.208"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "ps2-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ps2.ooni.io"
  records                          = ["162.55.247.208"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "ps3-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ps3.ooni.io"
  records                          = ["162.55.247.208"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "ps4-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ps4.ooni.io"
  records                          = ["162.55.247.208"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "registry-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "registry.ooni.io"
  records                          = ["37.218.245.90"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "registry-proteus-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "registry.proteus.ooni.io"
  records                          = ["37.218.245.90"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "run-ooni-io-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "run.ooni.io"
  records                          = ["cname.vercel-dns.com"]
  ttl                              = "60"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "slack-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "slack.ooni.io"
  records                          = ["37.218.247.98"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "slides-ooni-io-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "slides.ooni.io"
  records                          = ["ooni-slides.netlify.com"]
  ttl                              = "1200"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "superset-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "superset.ooni.io"
  records                          = ["37.218.240.92"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "test-ooni-io-_NS_" {
  multivalue_answer_routing_policy = "false"
  name                             = "test.ooni.io"
  records                          = ["ns-126.awsdns-15.com.", "ns-1348.awsdns-40.org.", "ns-2044.awsdns-63.co.uk.", "ns-615.awsdns-12.net."]
  ttl                              = "300"
  type                             = "NS"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "test-qemu-infra-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "test-qemu.infra.ooni.io"
  records                          = ["199.119.112.12"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "wcth-ooni-io-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "wcth.ooni.io"
  records                          = ["37.218.245.117"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "www-ooni-io-_CNAME_" {
  multivalue_answer_routing_policy = "false"
  name                             = "www.ooni.io"
  records                          = ["ooni.netlify.com"]
  ttl                              = "300"
  type                             = "CNAME"
  zone_id                          = local.dns_root_zone_ooni_io
}

resource "aws_route53_record" "ams-ps-ooni-nu-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ams-ps.ooni.nu"
  records                          = ["37.218.245.90"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_nu
}

resource "aws_route53_record" "ams-wcth-ooni-nu-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ams-wcth.ooni.nu"
  records                          = ["37.218.245.114"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_nu
}

resource "aws_route53_record" "ams-wcth2-ooni-nu-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ams-wcth2.ooni.nu"
  records                          = ["37.218.247.47"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_nu
}

resource "aws_route53_record" "ams-wcth3-ooni-nu-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "ams-wcth3.ooni.nu"
  records                          = ["37.218.245.117"]
  ttl                              = "300"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_nu
}

resource "aws_route53_record" "amsmatomo-ooni-nu-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "amsmatomo.ooni.nu"
  records                          = ["37.218.242.173"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_nu
}

resource "aws_route53_record" "dev-ooni-nu-_NS_" {
  multivalue_answer_routing_policy = "false"
  name                             = "dev.ooni.nu"
  records                          = ["ns-1094.awsdns-08.org.", "ns-157.awsdns-19.com.", "ns-1825.awsdns-36.co.uk.", "ns-619.awsdns-13.net."]
  ttl                              = "300"
  type                             = "NS"
  zone_id                          = local.dns_root_zone_ooni_nu
}

resource "aws_route53_record" "dnstunnel-ooni-nu-_NS_" {
  multivalue_answer_routing_policy = "false"
  name                             = "dnstunnel.ooni.nu"
  records                          = ["ooni.nu"]
  ttl                              = "1800"
  type                             = "NS"
  zone_id                          = local.dns_root_zone_ooni_nu
}

resource "aws_route53_record" "doams1-countly-ooni-nu-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "doams1-countly.ooni.nu"
  records                          = ["167.71.64.109"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_nu
}

resource "aws_route53_record" "fastpath-ooni-nu-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "fastpath.ooni.nu"
  records                          = ["103.104.244.20"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_nu
}

resource "aws_route53_record" "mia-echoth-ooni-nu-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "mia-echoth.ooni.nu"
  records                          = ["37.218.241.93"]
  ttl                              = "1799"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_nu
}

resource "aws_route53_record" "mia-httpth-ooni-nu-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "mia-httpth.ooni.nu"
  records                          = ["37.218.241.94"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_nu
}

resource "aws_route53_record" "mia-orchestra-test-ooni-nu-_A_" {
  multivalue_answer_routing_policy = "false"
  name                             = "mia-orchestra-test.ooni.nu"
  records                          = ["37.218.241.87"]
  ttl                              = "60"
  type                             = "A"
  zone_id                          = local.dns_root_zone_ooni_nu
}

resource "aws_route53_record" "prod-ooni-nu-_NS_" {
  multivalue_answer_routing_policy = "false"
  name                             = "prod.ooni.nu"
  records                          = ["ns-1507.awsdns-60.org.", "ns-1635.awsdns-12.co.uk.", "ns-54.awsdns-06.com.", "ns-629.awsdns-14.net."]
  ttl                              = "300"
  type                             = "NS"
  zone_id                          = local.dns_root_zone_ooni_nu
}

resource "aws_route53_record" "test-ooni-nu-_NS_" {
  multivalue_answer_routing_policy = "false"
  name                             = "test.ooni.nu"
  records                          = ["ns-1432.awsdns-51.org.", "ns-1601.awsdns-08.co.uk.", "ns-392.awsdns-49.com.", "ns-840.awsdns-41.net."]
  ttl                              = "300"
  type                             = "NS"
  zone_id                          = local.dns_root_zone_ooni_nu
}
