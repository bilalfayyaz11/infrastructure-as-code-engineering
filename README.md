# Infrastructure as Code Engineering

Production-oriented infrastructure automation patterns built around Terraform, Ansible, Docker, HashiCorp Vault, architecture-as-code, configuration management, and reusable infrastructure design.

This repository focuses on the operational side of Infrastructure as Code: **reusability, state management, drift reconciliation, secrets handling, containerized tooling, configuration automation, and infrastructure architecture.**

## Engineering Portfolio

| Implementation | What It Demonstrates | Core Technologies |
|---|---|---|
| [Terraform State Drift Reconciliation](./terraform-state-drift-reconciliation) | State inspection, out-of-band drift detection, reconciliation, and controlled state manipulation | Terraform, HCL, Local Provider |
| [Reusable Terraform Module Architecture](./terraform-reusable-module-architecture) | Reusable child modules, parameterized infrastructure, module outputs, and independent resource instances | Terraform, HCL, Modules |
| [Ansible Idempotent Configuration Management](./ansible-idempotent-configuration-management) | Declarative Linux configuration, idempotency, handlers, drift recovery, and configuration enforcement | Ansible, YAML, Linux |
| [Containerized IaC Toolchain](./containerized-iac-toolchain) | Reproducible Terraform and Ansible containers with local registry publishing and artifact reuse | Docker, Terraform, Ansible, Registry |
| [Three-Tier Infrastructure Architecture](./three-tier-infrastructure-architecture) | YAML-based infrastructure modeling, deployment sequencing, rollback design, and diagrams-as-code | YAML, Python, Graphviz, Diagrams |
| [Terraform Vault Secret Injection](./terraform-vault-secret-injection) | Dynamic Vault secret retrieval, KV v2 versioning, sensitive configuration generation, and secret rotation | Vault, Terraform, KV v2 |

## Core Capabilities

- **Terraform Engineering** — modules, providers, outputs, state operations, drift detection, reconciliation, and dependency-driven changes
- **Configuration Management** — idempotent Ansible automation, handlers, desired-state enforcement, and drift recovery
- **Secrets Management** — HashiCorp Vault KV v2, versioned secrets, Terraform integration, rotation, and sensitive artifact handling
- **Containerized Tooling** — reproducible Terraform/Ansible execution environments and private registry workflows
- **Infrastructure Architecture** — three-tier topology design, network segmentation, deployment sequencing, rollback procedures, and diagrams-as-code
- **Operational Reliability** — validation, state awareness, immutable configuration patterns, troubleshooting, and safe lifecycle management

## Technology Stack

`Terraform` · `HCL` · `Ansible` · `Docker` · `HashiCorp Vault` · `Linux` · `YAML` · `Python` · `Graphviz` · `Git`

## Engineering Focus

The implementations in this repository emphasize infrastructure patterns applicable to **Platform Engineering, AIOps, DevSecOps, Cloud Infrastructure, and production MLOps environments** where infrastructure must be reproducible, auditable, secure, and safe to evolve.
