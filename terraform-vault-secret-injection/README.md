# Terraform Vault Secret Injection and Rotation

## What This Does

This implementation demonstrates how Terraform can retrieve secrets dynamically from HashiCorp Vault instead of hardcoding credentials inside Infrastructure as Code source files.

Vault runs locally in development mode with a KV Version 2 secrets engine containing database and external API credentials. Terraform reads those values using the HashiCorp Vault provider, passes them through a template, and generates a protected application configuration file with restricted filesystem permissions.

The workflow also demonstrates live secret rotation. A database password is updated in Vault, Terraform detects the change during a normal plan refresh, and the rotated secret propagates automatically into the generated configuration.

The implementation is intentionally focused on secret lifecycle behavior, Terraform sensitivity boundaries, KV versioning, and the security implications of state and generated artifacts.

## Architecture

    ┌───────────────────────────────────────────────────────────────┐
    │                  HashiCorp Vault Dev Server                  │
    │                     127.0.0.1:8200                          │
    │                                                               │
    │                         KV v2                                 │
    │                                                               │
    │   secret/database/prod                                       │
    │   ├── db_username                                            │
    │   └── db_password                                            │
    │                                                               │
    │   secret/api/external-service                                │
    │   ├── api_key                                                │
    │   └── api_endpoint                                           │
    └─────────────────────────────┬─────────────────────────────────┘
                                  │
                                  │ Vault API
                                  ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                      Terraform Vault Provider                 │
    │                                                               │
    │   data.vault_kv_secret_v2.db                                  │
    │   data.vault_kv_secret_v2.api                                 │
    └─────────────────────────────┬─────────────────────────────────┘
                                  │
                                  ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                         Terraform Locals                       │
    │                                                               │
    │   db_username                                                  │
    │   db_password                                                  │
    │   api_key                                                      │
    │   api_endpoint                                                 │
    └─────────────────────────────┬─────────────────────────────────┘
                                  │
                                  │ templatefile()
                                  ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                  local_sensitive_file                         │
    │                                                               │
    │              output/app_config.conf                           │
    │                                                               │
    │                  file permission: 0600                        │
    └───────────────────────────────────────────────────────────────┘

                                  │
                                  ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                    Secret Rotation Flow                       │
    │                                                               │
    │   Vault KV v2 version 1                                      │
    │              ↓                                                │
    │   Vault KV v2 version 2                                      │
    │              ↓                                                │
    │   terraform plan refresh                                     │
    │              ↓                                                │
    │   sensitive resource change detected                         │
    │              ↓                                                │
    │   terraform apply                                            │
    │              ↓                                                │
    │   updated application configuration                          │
    └───────────────────────────────────────────────────────────────┘

## Repository Structure

    terraform-vault-secret-injection/
    ├── README.md
    ├── NOTES.md
    ├── .gitignore
    ├── .terraform.lock.hcl
    ├── providers.tf
    ├── variables.tf
    ├── data.tf
    ├── main.tf
    ├── outputs.tf
    └── templates/
        └── app_config.tftpl

Runtime files such as Terraform state, plan files, Vault logs, process IDs, generated secret-bearing configuration, and local variable files are excluded from source control.

## Prerequisites

- Ubuntu or another supported Linux distribution
- HashiCorp Vault CLI
- Terraform CLI
- Git
- curl
- jq
- GPG
- sudo privileges
- Internet connectivity to HashiCorp repositories

## Setup & Installation

Install Vault and Terraform using HashiCorp's official Ubuntu repository:

    curl -fsSL https://apt.releases.hashicorp.com/gpg \
      | gpg --dearmor \
      | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release) main" \
      | sudo tee /etc/apt/sources.list.d/hashicorp.list

    sudo apt-get update
    sudo apt-get install -y vault terraform

Verify:

    vault version
    terraform version

## Start Vault in Development Mode

Start the Vault development server:

    vault server \
      -dev \
      -dev-listen-address="127.0.0.1:8200" \
      -dev-root-token-id="vault-dev-root"

In another shell, configure the Vault client:

    export VAULT_ADDR="http://127.0.0.1:8200"
    export VAULT_TOKEN="vault-dev-root"

Verify:

    vault status

Vault development mode is intentionally temporary and insecure.

It:

- starts initialized
- starts unsealed
- uses in-memory storage
- exposes a root token
- loses all data when stopped

This mode is suitable only for isolated local testing.

## Secret Hierarchy

Secrets are organized according to responsibility and environment:

    secret/
    ├── database/
    │   └── prod
    │       ├── db_username
    │       └── db_password
    └── api/
        └── external-service
            ├── api_key
            └── api_endpoint

This structure separates database secrets from external service credentials and leaves room for additional environments and services.

## Store Vault Secrets

Store database credentials:

    vault kv put secret/database/prod \
      db_username="app_admin" \
      db_password="DevOnly-DB-Password-v1"

Store API credentials:

    vault kv put secret/api/external-service \
      api_key="dev-api-key-7f93a1" \
      api_endpoint="https://api.example.internal"

Verify:

    vault kv get secret/database/prod
    vault kv get secret/api/external-service

## Why KV Version 2

KV v2 provides version-aware secret management.

When a value changes, Vault creates a new version rather than immediately discarding the previous value.

This supports:

- secret rotation
- version inspection
- rollback
- recovery
- soft deletion
- controlled secret lifecycle management

## Terraform Provider Design

Terraform uses two providers:

    hashicorp/vault
    hashicorp/local

The Vault provider retrieves secrets.

The Local provider creates the protected application configuration file.

The Terraform configuration does not contain plaintext credentials.

Vault connection values are supplied through environment-backed Terraform variables instead of hardcoded source.

Example:

    export VAULT_ADDR="http://127.0.0.1:8200"
    export VAULT_TOKEN="vault-dev-root"

    export TF_VAR_vault_addr="$VAULT_ADDR"
    export TF_VAR_vault_token="$VAULT_TOKEN"

## Initialize Terraform

Run:

    terraform fmt -recursive
    terraform init
    terraform validate

The generated:

    .terraform.lock.hcl

should be committed to source control so provider versions remain consistent across environments.

The `.terraform/` directory should not be committed.

## Secret Retrieval

Terraform reads the database secret through:

    data.vault_kv_secret_v2.db

and the API secret through:

    data.vault_kv_secret_v2.api

The values are mapped into Terraform locals and passed into:

    templates/app_config.tftpl

using:

    templatefile()

## Generated Configuration

Terraform creates:

    output/app_config.conf

using:

    local_sensitive_file

The file contains database and API credentials retrieved from Vault.

The resource is configured with:

    file_permission = "0600"

This restricts access to the file owner.

The generated `output/` directory is excluded from Git because the file contains plaintext secret material by design.

## Sensitive Value Handling

Terraform marks secret-derived content as sensitive in normal CLI output.

For example, a plan should show:

    content = (sensitive value)

rather than displaying the real credential.

However, sensitivity is primarily an output-redaction mechanism.

Sensitive information can still exist inside:

- Terraform state
- saved plan files
- generated configuration files
- environment variables
- process memory
- external logs if explicitly printed

For this reason, these artifacts must be treated as secret-bearing data.

## Terraform State Security

Terraform state is excluded through `.gitignore`:

    terraform.tfstate
    terraform.tfstate.*

Terraform state must never be assumed safe merely because CLI output hides sensitive values.

Production environments should use a protected remote state backend with encryption, access control, auditability, and locking rather than unmanaged local state.

## Apply Workflow

Run:

    terraform plan -out=tfplan

Review the plan without exposing secret-bearing internals.

Apply:

    terraform apply tfplan

Verify the protected configuration:

    stat -c "%a %n" output/app_config.conf

Expected:

    600 output/app_config.conf

Inspect the file only in a controlled local environment:

    cat output/app_config.conf

## Terraform State Inspection

List Terraform objects:

    terraform state list

Expected addresses include:

    data.vault_kv_secret_v2.api
    data.vault_kv_secret_v2.db
    local_sensitive_file.app_config

Inspect the managed file resource:

    terraform state show local_sensitive_file.app_config

Terraform should redact sensitive content in the CLI representation.

## Secret Rotation

The original database password is stored as KV version 1.

Verify:

    vault kv get -version=1 secret/database/prod

Rotate the database password:

    vault kv put secret/database/prod \
      db_username="app_admin" \
      db_password="DevOnly-DB-Password-v2"

Verify the latest version:

    vault kv get secret/database/prod

Verify the original value still exists:

    vault kv get -version=1 secret/database/prod

Verify version 2:

    vault kv get -version=2 secret/database/prod

## Terraform Refresh Behavior

After rotating the Vault secret, run:

    terraform plan

Terraform refreshes the Vault data source during normal planning and evaluates the latest secret value.

The dependency chain is:

    Vault secret
        ↓
    Vault data source
        ↓
    Terraform locals
        ↓
    templatefile()
        ↓
    local_sensitive_file

Terraform should detect that the rendered configuration has changed.

No `terraform taint` is required merely to force a normal Vault data source refresh.

Apply the rotated value:

    terraform apply -auto-approve

Verify:

    grep '^password=' output/app_config.conf

The generated configuration should now contain the rotated password.

## Missing Secret Behavior

Terraform should fail when a required secret key is missing rather than silently generating an incomplete configuration.

For example, if a Vault path contains:

    db_username

but does not contain:

    db_password

then evaluating:

    data.vault_kv_secret_v2.example.data["db_password"]

fails during Terraform evaluation.

This is desirable fail-closed behavior for infrastructure automation.

## Vault Availability Behavior

Verify Vault:

    vault status

Verify its HTTP health endpoint:

    curl -s "$VAULT_ADDR/v1/sys/health" | jq

If Vault becomes unavailable, Terraform Vault data sources cannot refresh and the plan should fail rather than silently falling back to hardcoded credentials.

## Production Architecture

Vault development mode should never be used for real secrets.

A production Vault deployment would typically require:

- Vault Integrated Storage using Raft or another supported persistent architecture
- multiple Vault nodes
- TLS
- controlled initialization
- secure unsealing or auto-unseal
- narrowly scoped policies
- workload authentication
- audit devices
- snapshot and recovery procedures
- monitoring and alerting
- network segmentation
- controlled token TTLs
- secret lease management

Production automation should not use root tokens.

Appropriate authentication methods may include:

- AppRole
- JWT/OIDC
- Kubernetes authentication
- cloud IAM authentication

Each workload should receive only the minimum Vault permissions it requires.

## Tools Used

- HashiCorp Vault
- Vault KV Version 2
- Terraform
- HashiCorp Vault Provider
- HashiCorp Local Provider
- HCL
- Terraform Templates
- Linux
- Bash
- curl
- jq
- Git

## Key Skills Demonstrated

- HashiCorp Vault deployment
- Vault development server configuration
- KV v2 secret engine usage
- Secret hierarchy design
- Secret version management
- Terraform Vault provider integration
- Dynamic secret retrieval
- Terraform template rendering
- Sensitive Terraform values
- Protected local secret-file generation
- Secret rotation
- Terraform refresh behavior
- Fail-closed secret handling
- Terraform state security
- Secret-bearing artifact management
- Infrastructure credential lifecycle management

## Real-World Use Case

Infrastructure automation frequently requires credentials for databases, APIs, service accounts, cloud platforms, deployment systems, and internal services.

Hardcoding those values in Terraform files, Git repositories, CI variables, or scripts creates long-lived credential exposure and makes rotation difficult.

Vault provides a centralized security boundary where secrets can be stored, versioned, rotated, audited, and retrieved only by authorized workloads.

Terraform can retrieve required values at execution time and use them to configure dependent systems without embedding those credentials directly in source code.

In production environments, this pattern is commonly extended with short-lived Vault tokens, dynamic database credentials, cloud authentication, CI workload identity, Kubernetes authentication, remote encrypted Terraform state, and strict Vault policies.

## Lessons Learned

- Secret values should remain outside Infrastructure as Code source whenever possible.
- Vault KV v2 provides version-aware secret lifecycle management.
- Terraform data sources refresh during normal planning and can detect rotated Vault values.
- `sensitive = true` protects normal CLI presentation but does not automatically secure state.
- Saved Terraform plan files must also be treated as sensitive.
- Generated configuration files containing secrets require restricted permissions.
- Secret-bearing runtime artifacts should never be committed to Git.
- Missing required secret keys should fail automation rather than silently degrade security.
- Vault development mode is useful for experimentation but fundamentally unsuitable for production.
- Production workloads should authenticate through restricted identity-based methods rather than root tokens.

## Troubleshooting Log

### Vault and Terraform Missing

The fresh Ubuntu environment did not contain Vault or Terraform.

Both tools were installed using HashiCorp's official package repository.

### Existing KV v2 Mount

Vault development mode automatically exposes a KV Version 2 secrets engine at:

    secret/

Attempting to blindly enable another secrets engine at the same path would conflict with the existing mount.

The existing mount was inspected instead of recreated.

### Vault Dev Token Handling

A deterministic development root token was supplied using:

    -dev-root-token-id

This avoided parsing a random token from background process output.

This token is intentionally development-only and must never be reused as a production authentication pattern.

### Vault Provider Modernization

The Terraform Vault provider configuration uses the current provider family rather than the older 4.x constraint from the initial design.

### Template Naming

The application template uses:

    app_config.tftpl

to clearly identify it as a Terraform template source.

### Sensitive File Resource

The generated configuration contains real secret material.

A sensitive-aware local file resource is used and configured with:

    file_permission = "0600"

The entire generated output directory is excluded from Git.

### Secret Rotation Verification

The database password was changed from its original value to a second value at the same Vault KV path.

Vault retained both versions.

Terraform then detected the new secret during normal planning and updated the generated application configuration.

No taint operation was required.

### Missing Secret Test

A temporary secret lacking `db_password` was created and referenced.

Terraform failed when attempting to resolve the missing map key.

The temporary Terraform test configuration was then removed and normal validation restored.

### Terraform State Exposure

Although Terraform redacted sensitive content in normal CLI output, state and plan files were still treated as potentially secret-bearing artifacts.

Both are excluded from source control.

### Vault Availability

Vault health was validated through both:

    vault status

and:

    /v1/sys/health

Loss of Vault availability should cause Terraform secret retrieval to fail instead of bypassing the secrets-management layer.
