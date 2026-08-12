# Vault Secret Architecture Notes

## Secret Path Design

The secrets are organized according to infrastructure responsibility and environment:

    secret/
    ├── database/
    │   └── prod
    └── api/
        └── external-service

`database/prod` separates production database credentials from other environments.

`api/external-service` represents credentials associated with an external service rather than storing unrelated secrets under one shared path.

## Why KV Version 2

KV v2 supports versioned secret values. Updating an existing secret creates a new version rather than immediately discarding the previous value.

This supports controlled secret rotation, version inspection, rollback, and recovery workflows.

## Development Mode

Vault dev mode is appropriate only for local experimentation.

It:

- starts automatically initialized
- starts automatically unsealed
- uses an in-memory storage backend
- exposes a root token
- loses all stored data when the server stops

## Production Architecture

A production Vault deployment would require a persistent and highly available storage architecture such as Vault Integrated Storage using Raft.

Production deployments would also require:

- TLS
- controlled initialization and unsealing
- auto-unseal or managed key procedures
- multiple Vault nodes for high availability
- restricted policies
- production authentication methods
- short-lived workload identities instead of root tokens
- audit logging
- backups and snapshot procedures
- monitoring and alerting
- network access controls

## Terraform Secret Refresh Behavior

The Vault KV data sources were re-read during a normal `terraform plan`.

After rotating the database password in Vault, Terraform detected a change in the rendered configuration without requiring `terraform taint`, manual replacement, or a separate refresh command.

The dependency chain was:

    Vault KV v2 secret
          ↓
    Terraform Vault data source
          ↓
    templatefile()
          ↓
    local_sensitive_file
          ↓
    protected application configuration

This demonstrates that secret changes can propagate through Terraform during its normal refresh and planning process.

## Sensitive Data Handling

Terraform's `sensitive` behavior prevents selected values from being displayed directly in normal CLI output.

It does not make secret values safe to commit.

Sensitive values can still exist in:

- Terraform state
- saved Terraform plan files
- generated configuration files
- process environments
- external logs if explicitly printed

For this reason, state, plan files, runtime output, and token-bearing configuration are excluded from version control.

## Missing Secret Behavior

A missing required secret path or key causes Terraform evaluation to fail.

This fail-closed behavior is preferable to silently generating incomplete infrastructure configuration.

## Secret Rotation

Updating the same KV v2 secret path created a new secret version.

The original value remained available as version 1 while the rotated value became version 2.

Terraform subsequently retrieved the latest version during planning and propagated the new value into the generated application configuration.

## Production Authentication

The root token used here is strictly for Vault development mode.

Production automation should use workload-oriented authentication such as:

- AppRole
- JWT/OIDC
- Kubernetes authentication
- cloud IAM authentication

and should receive narrowly scoped Vault policies rather than root privileges.
