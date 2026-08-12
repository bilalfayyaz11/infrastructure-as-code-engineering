# Deployment Plan - Three-Tier Application

## Pre-Deployment Checks

- [ ] Validate the environment YAML manifest.
- [ ] Confirm the target environment is `dev`.
- [ ] Confirm the required CIDR ranges are available.
- [ ] Verify compute and storage capacity.
- [ ] Confirm PostgreSQL version requirements.
- [ ] Review security and network access between tiers.
- [ ] Notify stakeholders of the deployment window.
- [ ] Confirm a previous known-good manifest is available for rollback.

## Execution Steps

1. Validate `environments/dev.yaml`.
2. Provision the VPC and required subnets.
3. Apply network access controls between tiers.
4. Provision the PostgreSQL database.
5. Validate database availability.
6. Provision the application tier.
7. Validate application-to-database connectivity.
8. Provision the web tier.
9. Validate web-to-application connectivity.
10. Run end-to-end smoke tests.
11. Record the deployed configuration version.

## Rollback Procedures

1. Stop further deployment changes.
2. Identify the failed infrastructure component.
3. Preserve logs and diagnostic information.
4. Restore the previous known-good infrastructure manifest.
5. Re-apply the previously validated configuration.
6. Verify database health and data integrity.
7. Verify application-tier connectivity.
8. Verify web-tier connectivity.
9. Run end-to-end smoke tests.
10. Document the failure and rollback outcome.
