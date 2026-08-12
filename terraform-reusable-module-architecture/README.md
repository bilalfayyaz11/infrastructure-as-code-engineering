# Reusable Terraform Module Architecture

## What This Does

This implementation demonstrates how to design and consume reusable Terraform modules instead of duplicating infrastructure definitions across multiple configurations.

A reusable child module encapsulates a `local_file` resource and exposes a clean interface through typed input variables and module outputs. The root configuration calls that same module multiple times with different values, allowing independent resources to be created from one shared implementation.

The configuration also demonstrates module output propagation, resource-level state addresses, file permission overrides, and isolated change behavior between module instances. This pattern is directly applicable to production Terraform environments where reusable infrastructure components must be standardized and instantiated consistently across teams, environments, regions, and workloads.

## Architecture

    ┌───────────────────────────────────────────────────────────────┐
    │                      Root Configuration                       │
    │                           main.tf                             │
    │                                                               │
    │     Defines module instances and passes configuration values   │
    └─────────────────────────────┬─────────────────────────────────┘
                                  │
                     ┌────────────┴────────────┐
                     │                         │
                     ▼                         ▼
    ┌──────────────────────────┐   ┌──────────────────────────┐
    │   module.readme_file     │   │   module.config_file     │
    │                          │   │                          │
    │ filename                 │   │ filename                 │
    │ content                  │   │ content                  │
    │ default permission       │   │ custom permission 0600   │
    └─────────────┬────────────┘   └─────────────┬────────────┘
                  │                              │
                  └──────────────┬───────────────┘
                                 │
                                 ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                 Reusable Child Module                         │
    │              modules/file-creator/                            │
    │                                                               │
    │  variables.tf  → module input contract                        │
    │  main.tf       → local_file resource implementation           │
    │  outputs.tf    → reusable resource outputs                    │
    └─────────────────────────────┬─────────────────────────────────┘
                                  │
                                  ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                    HashiCorp Local Provider                    │
    └─────────────────────────────┬─────────────────────────────────┘
                                  │
                     ┌────────────┴────────────┐
                     │                         │
                     ▼                         ▼
              output/README.txt          output/app.conf
              default permission         permission 0600
                     │                         │
                     └────────────┬────────────┘
                                  │
                                  ▼
    ┌───────────────────────────────────────────────────────────────┐
    │                       Terraform State                         │
    │                                                               │
    │ module.readme_file.local_file.this                             │
    │ module.config_file.local_file.this                             │
    └───────────────────────────────────────────────────────────────┘

## Prerequisites

- Ubuntu or another supported Linux distribution
- Terraform CLI
- Internet access to Terraform Registry
- Bash-compatible shell
- Git
- Access to the HashiCorp Local provider

## Setup & Installation

Install Terraform on Ubuntu using HashiCorp's package repository:

    curl -fsSL https://apt.releases.hashicorp.com/gpg \
      | gpg --dearmor \
      | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release) main" \
      | sudo tee /etc/apt/sources.list.d/hashicorp.list

    sudo apt-get update
    sudo apt-get install -y terraform

    terraform version

## How to Reproduce

Clone the repository and enter this implementation directory:

    git clone https://github.com/bilalfayyaz11/infrastructure-as-code-engineering.git
    cd infrastructure-as-code-engineering/terraform-reusable-module-architecture

Inspect the directory structure:

    find . -maxdepth 3 -type f -print

Initialize Terraform:

    terraform init

Format all Terraform files recursively:

    terraform fmt -recursive

Validate the root configuration and child module:

    terraform validate

Review the proposed infrastructure changes:

    terraform plan

Apply the configuration:

    terraform apply -auto-approve

Verify the generated resources:

    cat output/README.txt
    cat output/app.conf

Verify the custom file permission:

    stat -c "%a %n" output/app.conf

Expected result:

    600 output/app.conf

Display root-level outputs:

    terraform output

Inspect the independent module resource addresses:

    terraform state list

Expected resource addresses include:

    module.config_file.local_file.this
    module.readme_file.local_file.this

Inspect one module instance in detail:

    terraform state show module.config_file.local_file.this

Modify an input for only one module instance:

    sed -i 's/version=1.0/version=2.0/' main.tf

Review the isolated change:

    terraform plan

Terraform should detect a change for the configuration module instance while leaving the README module instance unchanged.

Apply the updated configuration:

    terraform apply -auto-approve

Verify the new application configuration:

    cat output/app.conf

Confirm that the README resource remains unchanged:

    cat output/README.txt

Run the final validation:

    terraform validate
    terraform state list
    terraform output
    terraform plan

A clean final plan should report that the infrastructure matches the configuration.

Clean up managed resources when finished:

    terraform destroy -auto-approve

## Tools Used

- Terraform
- HashiCorp Configuration Language
- HashiCorp Local Provider
- Terraform Modules
- Linux
- Bash
- Git
- Terraform State CLI

## Key Skills Demonstrated

- Reusable Terraform child module development
- Terraform module composition
- Input variable design
- Module output design
- Root-to-child parameter passing
- Child-to-root output propagation
- Reusing one implementation across multiple resource instances
- File permission configuration through module inputs
- Terraform module state addressing
- Independent lifecycle behavior between module instances
- Recursive Terraform formatting and validation
- Infrastructure abstraction and standardization

## Real-World Use Case

Production Terraform environments rarely define every infrastructure resource independently. Platform and infrastructure teams typically create reusable modules for standardized components such as virtual networks, Kubernetes clusters, compute instances, databases, IAM policies, observability stacks, secrets infrastructure, and MLOps platforms.

A module establishes a controlled interface between infrastructure consumers and the underlying implementation. Engineers can pass environment-specific inputs while the organization keeps security controls, naming conventions, lifecycle behavior, networking rules, and operational defaults centralized inside reusable components.

This approach reduces duplication, improves consistency, makes infrastructure changes easier to review, and allows platform teams to evolve implementation details without forcing every consumer to redesign their infrastructure configuration.

## Lessons Learned

- Terraform modules provide reusable infrastructure abstractions similar to reusable functions in software engineering.
- Input variables define the public configuration interface of a module.
- Outputs allow resource information generated inside a child module to be consumed by the root configuration or other modules.
- Multiple module calls can reuse the same implementation while maintaining separate resource instances and state addresses.
- Module inputs can override defaults without modifying reusable implementation code.
- Changing the inputs of one module instance does not automatically affect other instances using the same module.
- Resource addresses inside modules include the module path, making state ownership and troubleshooting explicit.
- Well-designed modules reduce duplication and create consistent infrastructure patterns across environments.

## Troubleshooting Log

### Terraform Installation

Terraform was not available in the fresh Ubuntu environment.

Terraform was installed using HashiCorp's official Ubuntu package repository rather than downloading and manually managing an old version-specific binary.

### Provider Version Modernization

The supplied configuration constrained the HashiCorp Local provider to an older `~> 2.4` release range.

The implementation was updated to:

    version = "~> 2.9"

This keeps the module aligned with the newer Local provider release family used during execution.

### Child Module Input Completion

The module required a default value for the `content` variable.

A neutral reusable default was added:

    default = "Managed by Terraform."

The root configuration explicitly overrides this value for both module instances.

### Resource Argument Completion

The reusable `local_file` resource was completed using module variables:

    filename        = var.filename
    content         = var.content
    file_permission = var.file_permission

This removes hard-coded resource values and makes the child module reusable.

### Module Output Completion

The child module exposes:

    file_path
    file_id
    content_md5

The root configuration consumes the module outputs and exposes selected values at root level.

### Custom Permission Verification

The configuration module overrides the module's default permission with:

    file_permission = "0600"

The resulting filesystem permission was verified with:

    stat -c "%a %n" output/app.conf

### Independent Module Change Verification

The application configuration was changed from:

    version=1.0

to:

    version=2.0

Terraform detected the change only for:

    module.config_file.local_file.this

The README module remained independent, demonstrating that separate calls to the same reusable module maintain independent infrastructure lifecycles.

### Runtime Artifact Handling

Terraform runtime data should not be stored in source control.

The following artifacts are intentionally excluded from Git:

    .terraform/
    terraform.tfstate
    terraform.tfstate.*
    *.tfplan
    crash logs
    generated output files

Only reproducible Terraform configuration and documentation are committed.
