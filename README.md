# OONI Devops


## Infrastructure Tiers

We divide our infrastructure components into 3 tiers:

- **Tier 0: Critical**: These are mission critical infrastructure components. If these become unavailable or have significant disruption, it will have a major impact.

- **Tier 1: Essential**: These components are important, but not as critical as
  tier 0. They are part of our core operations, but if they become unavailable
  the impact is important, but not major.

- **Tier 2: Non-Essential**: These are auxiliary components. Their
  unavailability does not have a major impact.

### Tier 0 (Critical) components

- [ ] Probe Services (collector specifically)
- [ ] Fastpath (part responsible for storing post-cans)
- [x] DNS configuration
- [ ] Monitoring
- [ ] OONI bridges
- [ ] OONI.org website
- [x] Web Connectivity test helpers
- [x] Code signing

### Tier 1 (Essential) components

- [ ] OONI API measurement listing
- [x] OONI Explorer
- [x] OONI Run
- [ ] OONI Data analysis pipeline
- [x] OONI Findings API
- [x] Website analytics

### Tier 2 (Non-Essential) components

- [ ] Test list editor
- [ ] Jupyter notebooks
- [ ] Countly

## DNS and Domains

The primary domains used by the backend are:
- `ooni.org`
- `ooni.io`
- `ooni.nu`

### DNS naming policy

The public facing name of services, follows this format:

- `<service>.ooni.org`

Examples:

- `explorer.ooni.org`
- `run.ooni.org`

Public-facing means the FQDNs are used directly by external users, services, or
embedded in the probes. They cannot be changed or retired without causing
outages.

Use public facing names sparingly and when possible start off by creating a
private name first.
Not every host needs to have a public facing name. For example staging and
testing environments might not have a public facing name.

Each service also has public name which points to the specific host running that
service, and these are hosted in the `.io` zone.
This is helpful because sometimes you might have the same host running multiple
services or you might also have multiple services behind the same public service
endpoint (eg. in the case of an API gateway setup).

Name in the `.io` zone should always include also the environment name they are
related to:

- `<service>.prod.ooni.io` for production services
- `<service>.test.ooni.io` for test services

When there may be multiple instances of a service running, you can append a
number to the service name. Otherwise the service name should be only alphabetic
characters.

Examples:

- `clickhouse.prod.ooni.io`
- `postgres0.prod.ooni.io`
- `postgres1.prod.ooni.io`
- `prometheus.prod.ooni.io`
- `grafana.prod.ooni.io`

Finally, the actual host which runs the service, should have a FQDN defined
inside of the `.nu` zone.

This might not apply to every host, especially in a cloud environment. The FQDN
in the `.nu` are the ones which are going to be stored in the ansible inventory
file and will be used as targets for configuration management.

The structure of these domains is:

- `<name>.<location>.[prod|test].ooni.nu`

The location tag can be either just the provider name or provider name `-` the location.

Here is a list of location tags:

- `htz-fsn`: Hetzner on Falkenstein
- `htz-hel`: Hetzner in Helsinki
- `grh-ams`: Greenhost in Amsterdam
- `grh-mia`: Greenhost in Miami
- `aws-fra`: AWS in Europe (Frankfurt)

Examples:

- `monitoring.htz-fsn.prod.ooni.nu`
