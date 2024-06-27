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
- [ ] Code signing

### Tier 1 (Essential) components

- [ ] OONI API measurement listing
- [x] OONI Explorer
- [x] OONI Run
- [ ] OONI Data analysis pipeline
- [x] Website analytics

### Tier 2 (Non-Essential) components

- [ ] Test list editor
- [ ] Jupyter notebooks
- [ ] Countly
