# Terraform State Drift Detection and Reconciliation

## What This Does

This implementation demonstrates how Terraform tracks managed infrastructure state, detects out-of-band changes, and reconciles real resources back to their declared configuration.

Three resources are provisioned through the HashiCorp Local provider and recorded in Terraform state. One resource is then modified outside Terraform to simulate configuration drift, allowing `terraform plan` to identify the discrepancy and `terraform apply` to restore the declared state.

The implementation also demonstrates direct state inspection and controlled removal of resource tracking with `terraform state list`, `terraform state show`, and `terraform state rm`. These workflows are directly relevant to diagnosing state inconsistencies and infrastructure drift in production Terraform environments.

## Architecture

    ┌─────────────────────────────────────────────────────────┐
    │                 Terraform Configuration                 │
    │                        main.tf                          │
    │                                                         │
    │      Desired infrastructure definitions and content     │
    └───────────────────────────┬─────────────────────────────┘
                                │
                                │ terraform init / plan / apply
                                ▼
    ┌─────────────────────────────────────────────────────────┐
    │                HashiCorp Local Provider                 │
    │                                                         │
    │          Translates declared resources into             │
    │                local filesystem objects                 │
    └───────────────────────────┬─────────────────────────────┘
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
              ▼                 ▼                 ▼
    ┌────────────────┐ ┌────────────────┐ ┌────────────────┐
    │    config_a    │ │    config_b    │ │    config_c    │
    │ environment=dev│ │ staging / drift│ │environment=prod│
    │ version=1.0    │ │ reconciliation │ │ version=1.0    │
    └────────┬───────┘ └────────┬───────┘ └────────┬───────┘
             │                  │                  │
             └──────────────────┼──────────────────┘
                                │
                                ▼
    ┌─────────────────────────────────────────────────────────┐
    │                  Terraform State                        │
    │                terraform.tfstate                       │
    │                                                         │
    │ Resource identity • attributes • hashes • relationships │
    └───────────────────────────┬─────────────────────────────┘
                                │
                                │ terraform state
                                ▼
    ┌─────────────────────────────────────────────────────────┐
    │                 State Operations                        │
    │                                                         │
    │ state list → tracked resource inventory                 │
    │ state show → resource metadata and attributes           │
    │ state rm   → remove tracking without deleting object    │
    └─────────────────────────────────────────────────────────┘

## Prerequisites

- Ubuntu or another supported Linux distribution
- Terraform CLI
- Internet connectivity for provider installation
- Bash-compatible shell
- Git for repository management

## Setup & Installation

Install Terraform using HashiCorp's official package repository on Ubuntu:

    curl -fsSL https://apt.releases.hashicorp.com/gpg \
      | gpg --dearmor \
      | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release) main" \
      | sudo tee /etc/apt/sources.list.d/hashicorp.list

    sudo apt-get update
    sudo apt-get install -y terraform

    terraform version

## How to Reproduce

Clone the repository:

    git clone https://github.com/bilalfayyaz11/infrastructure-as-code-engineering.git
    cd infrastructure-as-code-engineering/terraform-state-drift-reconciliation

Initialize Terraform:

    terraform init

Validate the configuration:

    terraform validate

Review the execution plan:

    terraform plan

Provision all declared resources:

    terraform apply -auto-approve

Verify the generated files:

    ls -la files/
    cat files/config_a.txt
    cat files/config_b.txt
    cat files/config_c.txt

Inspect all resources tracked in Terraform state:

    terraform state list

Inspect detailed state metadata for one resource:

    terraform state show local_file.config_a

Simulate an out-of-band modification:

    printf "environment=staging\nversion=2.0-hotfix\n" > files/config_b.txt
    cat files/config_b.txt

Detect the resulting drift:

    terraform plan

Terraform should detect that the real resource no longer matches the declared configuration.

Reconcile the drift:

    terraform apply -auto-approve
    cat files/config_b.txt

The file should return to:

    environment=staging
    version=1.0

Remove `config_c` from Terraform state without deleting the physical file:

    terraform state rm local_file.config_c

Verify the remaining tracked resources:

    terraform state list

Confirm that the underlying file still exists:

    ls -l files/config_c.txt
    cat files/config_c.txt

Run another Terraform plan:

    terraform plan

Terraform should propose managing `config_c` again because the resource remains declared in `main.tf` but is no longer associated with Terraform state.

## Tools Used

- Terraform
- HashiCorp Configuration Language
- HashiCorp Local Provider
- Linux
- Bash
- Git
- Terraform State CLI

## Key Skills Demonstrated

- Terraform state inspection and resource identity analysis
- Infrastructure drift detection using execution plans
- Desired-state reconciliation
- Controlled manipulation of Terraform resource tracking
- Understanding configuration, state, and real infrastructure relationships
- Diagnosing changes made outside Terraform
- Safe use of `terraform state list`
- Safe use of `terraform state show`
- Safe use of `terraform state rm`
- Infrastructure lifecycle troubleshooting

## Real-World Use Case

Production infrastructure frequently changes outside the expected Infrastructure as Code workflow because of emergency fixes, cloud-console modifications, manual administrator actions, automation failures, or legacy operational processes.

Terraform drift detection allows infrastructure, platform, AIOps, and DevSecOps engineers to identify those differences before additional infrastructure changes are made. State inspection is also critical when resources become incorrectly tracked, moved, replaced, imported, or intentionally detached from Terraform management.

These capabilities are especially important in cloud platforms, Kubernetes environments, MLOps infrastructure, and enterprise DevSecOps systems where incorrect state manipulation can result in unexpected resource replacement, recreation, or deletion.

## Lessons Learned

- Terraform configuration represents the desired state of infrastructure.
- Terraform state records the resources and attributes currently managed by Terraform.
- Real infrastructure can diverge from configuration when changes occur outside Terraform.
- `terraform plan` exposes drift before Terraform performs infrastructure changes.
- `terraform apply` can reconcile managed resources back to the declared configuration.
- `terraform state rm` removes Terraform's association with a resource without deleting the underlying object.
- State manipulation must be performed carefully because incorrect operations can cause Terraform to recreate or lose management of infrastructure.

## Troubleshooting Log

### Outdated Terraform Installation

The supplied procedure used a manually downloaded Terraform 1.8.5 binary.

The installation was replaced with HashiCorp's official Ubuntu package repository so Terraform can be installed through the system package manager using a current supported release.

### Unreliable Newline Handling

The supplied drift simulation used:

    echo "environment=staging\nversion=2.0-hotfix" > files/config_b.txt

Plain `echo` does not guarantee consistent interpretation of escape sequences across shell implementations.

The reliable replacement was:

    printf "environment=staging\nversion=2.0-hotfix\n" > files/config_b.txt

### Drift Reconciliation

`config_b.txt` was manually changed outside Terraform.

Running:

    terraform plan

detected the difference between the declared configuration and the real resource.

Running:

    terraform apply -auto-approve

restored the resource to the desired configuration.

### State Removal Behavior

Running:

    terraform state rm local_file.config_c

removed Terraform's state association with `config_c` but did not delete the physical file.

Because `local_file.config_c` remained declared in `main.tf`, a subsequent:

    terraform plan

proposed managing the resource again.

This demonstrates why manual state manipulation should normally be paired with an appropriate configuration change, state move, or import strategy.
