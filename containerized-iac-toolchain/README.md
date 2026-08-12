# Containerized Infrastructure as Code Toolchain

## What This Does

This implementation packages Terraform and Ansible into reproducible Docker images that can be used consistently across developer workstations, CI runners, and automation environments.

A lightweight Terraform-only image provides a minimal containerized Terraform CLI, while a second toolbox image bundles Terraform, Ansible Core, Python, and sample Infrastructure as Code definitions into a reusable execution environment.

The workflow also includes a local Docker registry used to publish, retrieve, and validate the custom IaC toolbox image. This demonstrates how infrastructure tooling can be distributed as a versioned artifact rather than installed independently on every target machine.

## Architecture

    ┌───────────────────────────────────────────────────────────────┐
    │                      Ubuntu Docker Host                       │
    │                                                               │
    │              Docker Engine + Buildx + Registry               │
    └─────────────────────────────┬─────────────────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼
    ┌─────────────────────────────┐  ┌─────────────────────────────┐
    │    terraform-cli:1.0       │  │      iac-toolbox:1.0        │
    │                             │  │                             │
    │ Alpine Linux                │  │ Alpine Linux                │
    │ Terraform CLI               │  │ Terraform CLI               │
    │ CA certificates             │  │ Python                      │
    │ curl / unzip                │  │ Ansible Core                │
    │                             │  │ Bash                        │
    └──────────────┬──────────────┘  │ IaC source files            │
                   │                 └──────────────┬──────────────┘
                   │                                │
                   ▼                                ▼
          Terraform CLI execution          Terraform + Ansible
                                            validation workflow
                                                    │
                                                    │
                                                    ▼
                                    ┌─────────────────────────────┐
                                    │   Local Docker Registry     │
                                    │                             │
                                    │      localhost:5000         │
                                    │                             │
                                    │ iac-toolbox:1.0             │
                                    └──────────────┬──────────────┘
                                                   │
                                                   ▼
                                    Push → Store → Pull → Reuse

## Repository Structure

    containerized-iac-toolchain/
    ├── README.md
    ├── .gitignore
    ├── terraform-cli/
    │   └── Dockerfile
    └── full-iac/
        ├── Dockerfile
        ├── main.tf
        └── playbook.yml

## Prerequisites

- Ubuntu or another Docker-supported Linux distribution
- Docker Engine
- Docker Buildx
- Docker Compose plugin
- Git
- curl
- Internet connectivity to Docker Hub
- Internet connectivity to HashiCorp releases
- Permission to access the Docker daemon

## Docker Access

Verify Docker:

    docker --version
    docker buildx version
    docker compose version

Verify daemon access:

    docker info

If the current user cannot access the Docker socket:

    sudo usermod -aG docker "$USER"

A new login session or shell with the updated group membership may be required.

Verify:

    id
    docker info

## Terraform CLI Image

The Terraform-only image is located in:

    terraform-cli/Dockerfile

The image uses a lightweight Alpine Linux base and installs Terraform from HashiCorp releases.

The build accepts Docker's target architecture so the Terraform binary can be selected for supported platforms such as AMD64 and ARM64.

The downloaded Terraform archive is validated using HashiCorp's published SHA-256 checksum before installation.

Build the image:

    cd terraform-cli
    docker build -t terraform-cli:1.0 .

Verify:

    docker run --rm terraform-cli:1.0 version

## IaC Toolbox Image

The full toolbox image is located in:

    full-iac/Dockerfile

It packages:

- Terraform CLI
- Python
- Ansible Core
- Bash
- OpenSSH client
- Terraform configuration
- Ansible playbook

Ansible is installed into an isolated Python virtual environment rather than modifying the base distribution's managed Python environment.

Build the toolbox:

    cd full-iac
    docker build -t iac-toolbox:1.0 .

Verify Terraform:

    docker run --rm \
      --entrypoint terraform \
      iac-toolbox:1.0 \
      version

Verify Ansible:

    docker run --rm \
      --entrypoint ansible-playbook \
      iac-toolbox:1.0 \
      --version

## Terraform Validation Inside Docker

The embedded Terraform configuration explicitly declares the HashiCorp Local provider.

Run the complete workflow:

    docker run --rm \
      --entrypoint bash \
      iac-toolbox:1.0 \
      -lc '
        cd /workspace &&
        terraform init &&
        terraform validate &&
        terraform plan -out=tfplan &&
        terraform apply -auto-approve tfplan &&
        cat sample_output.txt &&
        terraform state list
      '

Expected managed resource:

    local_file.sample

Expected generated content:

    Hello from Terraform inside Docker

This confirms that provider initialization, planning, resource creation, and Terraform state handling work from inside the container.

## Ansible Validation Inside Docker

The embedded playbook uses a local connection and a fully qualified Ansible module name.

Run:

    docker run --rm \
      --entrypoint bash \
      iac-toolbox:1.0 \
      -lc '
        cd /workspace &&
        ansible-playbook --syntax-check playbook.yml &&
        ansible-playbook playbook.yml
      '

Expected message:

    Hello from Ansible inside Docker

The execution should finish with:

    failed=0

## Local Docker Registry

Run a private local registry:

    docker run -d \
      --name registry \
      --restart unless-stopped \
      -p 5000:5000 \
      registry:2

Verify:

    docker ps --filter name=registry
    curl -fsS http://localhost:5000/v2/

## Publish the Toolbox Image

Tag the image for the local registry:

    docker tag iac-toolbox:1.0 localhost:5000/iac-toolbox:1.0

Push:

    docker push localhost:5000/iac-toolbox:1.0

Verify the repository catalog:

    curl -fsS http://localhost:5000/v2/_catalog

Expected response:

    {"repositories":["iac-toolbox"]}

Verify tags:

    curl -fsS http://localhost:5000/v2/iac-toolbox/tags/list

Expected response:

    {"name":"iac-toolbox","tags":["1.0"]}

## Registry Reuse Verification

Remove the local registry-tagged image reference:

    docker image rm localhost:5000/iac-toolbox:1.0

Pull the image back:

    docker pull localhost:5000/iac-toolbox:1.0

Verify Terraform from the retrieved artifact:

    docker run --rm \
      --entrypoint terraform \
      localhost:5000/iac-toolbox:1.0 \
      version

Verify Ansible:

    docker run --rm \
      --entrypoint ansible-playbook \
      localhost:5000/iac-toolbox:1.0 \
      --version

This proves the image can move through an artifact distribution workflow rather than only executing from a local build cache.

## Tools Used

- Docker Engine
- Docker Buildx
- Docker Registry
- Dockerfile
- Alpine Linux
- Terraform
- HashiCorp Local Provider
- Ansible Core
- Python
- Python virtual environments
- Bash
- curl
- SHA-256 checksum validation
- Git

## Key Skills Demonstrated

- Dockerfile engineering
- Containerized infrastructure tooling
- Terraform CLI packaging
- Ansible packaging
- Reproducible IaC execution environments
- Multi-tool container image design
- Architecture-aware Docker builds
- Binary integrity validation
- Terraform provider initialization inside containers
- Terraform state handling inside ephemeral environments
- Ansible playbook execution inside containers
- Local Docker registry deployment
- Docker image tagging
- Registry push and pull workflows
- CI/CD artifact reuse
- Linux Docker socket troubleshooting

## Real-World Use Case

Infrastructure teams frequently need the same Terraform, Ansible, Python, cloud CLI, and automation dependencies across laptops, build agents, CI runners, and deployment systems.

Installing those dependencies independently can create version drift and inconsistent runtime behavior. Packaging them into versioned Docker images creates a controlled execution environment that can be tested once and reused across multiple systems.

In CI/CD environments, the same approach can be used to create standardized infrastructure runner images containing Terraform, Ansible, Kubernetes tooling, cloud CLIs, policy engines, security scanners, and deployment utilities.

Publishing these images to an internal container registry allows pipeline workers to retrieve the exact toolchain version required for infrastructure deployment.

## Lessons Learned

- Containerizing infrastructure tools reduces dependency differences between development and CI environments.
- Docker image versions provide a reproducible mechanism for distributing infrastructure tooling.
- Terraform binaries should be verified against published checksums before being added to reusable images.
- Docker build architecture should not be hard-coded when portable builds are practical.
- Python tooling can be isolated in a virtual environment instead of modifying distribution-managed packages.
- Terraform providers should be declared explicitly to make configurations reproducible.
- A registry push alone is not enough to prove artifact reuse; pulling and executing the published image validates the complete distribution workflow.
- Docker daemon permissions are a critical prerequisite for non-root container workflows.

## Troubleshooting Log

### Docker Socket Permission Failure

Docker was installed and the daemon was active, but the non-root user could not access:

    /var/run/docker.sock

Commands failed with:

    permission denied while trying to connect to the docker API

The user was added to the Docker group:

    sudo usermod -aG docker "$USER"

Docker socket ownership and permissions were verified:

    ls -l /var/run/docker.sock

The shell session was refreshed so the new Docker group membership became active.

Successful recovery was confirmed with:

    docker info

### Registry Connection Failure

Registry API calls initially failed with:

    curl: (7) Failed to connect to localhost port 5000

This was a downstream effect of the Docker permission failure.

Because Docker commands could not execute, the registry container had never started.

Once Docker access was restored, the registry was successfully created and the API became reachable.

### Outdated Alpine Base

The supplied Dockerfiles referenced:

    alpine:3.19

The implementation was updated to a newer Alpine release family for a fresh container build.

### Outdated Terraform Version

The supplied Dockerfiles referenced Terraform 1.7.5.

The implementation was updated to a newer stable Terraform release used during execution.

### Hard-Coded Terraform Architecture

The supplied Terraform download path explicitly referenced:

    linux_amd64

The Dockerfiles were updated to use the build target architecture and map supported architectures to the corresponding Terraform binary.

### Missing Terraform Provider Declaration

The sample Terraform configuration created a `local_file` resource without an explicit `required_providers` declaration.

The configuration was updated to declare:

    hashicorp/local

with an explicit version constraint.

### Python Package Isolation

Installing Ansible directly into Alpine's managed Python environment with:

    pip3 install --break-system-packages

was avoided.

Ansible Core was installed into:

    /opt/ansible

using a Python virtual environment.

This keeps Python application dependencies isolated from the operating system package environment.

### Registry Artifact Verification

The toolbox image was tagged and pushed to:

    localhost:5000/iac-toolbox:1.0

Registry catalog and tag APIs were used to confirm storage.

The image was then pulled back from the registry and executed again, validating end-to-end artifact reuse.
