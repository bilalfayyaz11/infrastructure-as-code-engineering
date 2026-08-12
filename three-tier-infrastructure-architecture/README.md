# Three-Tier Infrastructure Architecture and Deployment Design

## What This Does

This implementation provides a documentation-first infrastructure design for a three-tier application consisting of web, application, and PostgreSQL database tiers.

The architecture is described through a structured YAML desired-state manifest, infrastructure component documentation, deployment sequencing, rollback procedures, and a diagrams-as-code implementation.

The design deliberately separates infrastructure intent from provisioning technology. This allows the architecture to be reviewed, validated, and communicated before being translated into Terraform, Ansible, cloud-native templates, Kubernetes manifests, or other Infrastructure as Code systems.

## Architecture

    ┌──────────────────────────────────────────────────────────────────┐
    │                         Client Traffic                           │
    └───────────────────────────────┬──────────────────────────────────┘
                                    │
                                    │ HTTP :80
                                    ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │                  Web Tier - 10.0.1.0/24                          │
    │                                                                  │
    │             ┌─────────────┐      ┌─────────────┐                  │
    │             │   web-01    │      │   web-02    │                  │
    │             │    Nginx    │      │    Nginx    │                  │
    │             │   1 vCPU    │      │   1 vCPU    │                  │
    │             │    2 GB     │      │    2 GB     │                  │
    │             └──────┬──────┘      └──────┬──────┘                  │
    └────────────────────┼─────────────────────┼────────────────────────┘
                         │                     │
                         │       TCP :8080     │
                         ▼                     ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │                Application Tier - 10.0.2.0/24                    │
    │                                                                  │
    │             ┌─────────────┐      ┌─────────────┐                  │
    │             │   app-01    │      │   app-02    │                  │
    │             │   Server    │      │   Server    │                  │
    │             │   2 vCPU    │      │   2 vCPU    │                  │
    │             │    4 GB     │      │    4 GB     │                  │
    │             └──────┬──────┘      └──────┬──────┘                  │
    └────────────────────┼─────────────────────┼────────────────────────┘
                         │                     │
                         │       TCP :5432     │
                         └──────────┬──────────┘
                                    ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │                 Database Tier - 10.0.3.0/24                      │
    │                                                                  │
    │                       ┌────────────────┐                          │
    │                       │ PostgreSQL 14  │                          │
    │                       │    20 GB       │                          │
    │                       │   Port 5432    │                          │
    │                       └────────────────┘                          │
    └──────────────────────────────────────────────────────────────────┘

                                    │
                                    ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │                      Architecture Assets                         │
    │                                                                  │
    │ environments/dev.yaml                                            │
    │ docs/infrastructure-components.md                                 │
    │ docs/deployment-plan.md                                           │
    │ docs/architecture.png                                             │
    │ scripts/generate_diagram.py                                       │
    └──────────────────────────────────────────────────────────────────┘

## Repository Structure

    .
    ├── README.md
    ├── docs
    │   ├── architecture.png
    │   ├── deployment-plan.md
    │   └── infrastructure-components.md
    ├── environments
    │   └── dev.yaml
    ├── modules
    └── scripts
        └── generate_diagram.py

## Prerequisites

- Ubuntu or another supported Linux distribution
- Python 3
- Graphviz
- pipx
- Python `diagrams` package
- PyYAML
- Git
- Bash-compatible shell

## Setup & Installation

Install Graphviz and pipx:

    sudo apt-get update
    sudo apt-get install -y graphviz pipx

Configure the pipx executable path:

    pipx ensurepath
    export PATH="$HOME/.local/bin:$PATH"

Install the diagrams-as-code dependency:

    pipx install diagrams

Verify Graphviz:

    dot -V

Verify the isolated diagrams environment:

    pipx runpip diagrams show diagrams

Verify PyYAML availability:

    python3 -c "import yaml; print('PyYAML available')"

## Infrastructure Manifest

The development environment is defined in:

    environments/dev.yaml

The manifest contains:

- application metadata
- web-tier compute requirements
- application-tier compute requirements
- PostgreSQL storage requirements
- VPC naming
- three subnet CIDR ranges
- service ports
- instance counts

The declared architecture consists of:

    Web Tier
    - 2 instances
    - 1 vCPU each
    - 2 GB memory each
    - Port 80
    - 10.0.1.0/24

    Application Tier
    - 2 instances
    - 2 vCPU each
    - 4 GB memory each
    - Port 8080
    - 10.0.2.0/24

    Database Tier
    - PostgreSQL 14
    - 20 GB storage
    - Port 5432
    - 10.0.3.0/24

## YAML Validation

Validate the environment manifest:

    python3 -c "import yaml; yaml.safe_load(open('environments/dev.yaml')); print('Valid YAML')"

A successful result prints:

    Valid YAML

This validates syntax and structure at the YAML parsing layer before the manifest is consumed by future automation.

## Infrastructure Components

Detailed compute, networking, and storage specifications are documented in:

    docs/infrastructure-components.md

The document describes:

- instance counts
- CPU requirements
- memory requirements
- service ports
- subnet allocations
- CIDR boundaries
- PostgreSQL version
- storage capacity
- expected traffic flow between tiers

The intended communication model is:

    Client
      ↓
    Web Tier :80
      ↓
    Application Tier :8080
      ↓
    PostgreSQL :5432

Direct client access to the database tier is intentionally excluded from the architecture.

## Deployment Strategy

The deployment procedure is documented in:

    docs/deployment-plan.md

The infrastructure should be introduced in dependency order:

    1. Validate environment manifest
    2. Provision VPC
    3. Provision subnets
    4. Apply network access controls
    5. Provision PostgreSQL
    6. Validate database availability
    7. Provision application tier
    8. Validate application-to-database connectivity
    9. Provision web tier
    10. Validate web-to-application connectivity
    11. Run end-to-end smoke tests
    12. Record deployed configuration version

This ordering ensures lower-level infrastructure dependencies are available before dependent services are introduced.

## Rollback Strategy

The rollback procedure follows a controlled recovery sequence:

    1. Stop additional deployment changes.
    2. Identify the failed infrastructure component.
    3. Preserve logs and diagnostic information.
    4. Restore the previous known-good manifest.
    5. Re-apply the previously validated configuration.
    6. Verify database health and data integrity.
    7. Verify application-tier connectivity.
    8. Verify web-tier connectivity.
    9. Run end-to-end smoke tests.
    10. Document the incident and rollback result.

Maintaining a previous known-good manifest provides a deterministic recovery point rather than relying on undocumented manual reconstruction.

## Diagrams as Code

The architecture diagram is generated from:

    scripts/generate_diagram.py

Generate the diagram with:

    pipx run --spec diagrams python scripts/generate_diagram.py

The generated artifact is:

    docs/architecture.png

Verify it:

    file docs/architecture.png
    ls -lh docs/architecture.png

Unlike a manually maintained architecture image, the Python source provides a version-controlled representation of the infrastructure topology.

## How to Reproduce

Clone the repository:

    git clone https://github.com/bilalfayyaz11/infrastructure-as-code-engineering.git

Enter the architecture directory:

    cd infrastructure-as-code-engineering/three-tier-infrastructure-architecture

Inspect the repository:

    find . -maxdepth 3 -type f | sort

Validate the YAML manifest:

    python3 -c "import yaml; yaml.safe_load(open('environments/dev.yaml')); print('Valid YAML')"

Inspect the infrastructure specification:

    cat docs/infrastructure-components.md

Review the deployment and rollback plan:

    cat docs/deployment-plan.md

Generate the architecture diagram:

    pipx run --spec diagrams python scripts/generate_diagram.py

Verify the generated diagram:

    file docs/architecture.png

Validate the diagram generator syntax:

    pipx run --spec diagrams python -m py_compile scripts/generate_diagram.py

## Tools Used

- Python 3
- YAML
- PyYAML
- Graphviz
- Python Diagrams
- pipx
- Markdown
- Linux
- Bash
- Git

## Key Skills Demonstrated

- Infrastructure architecture documentation
- Documentation-first Infrastructure as Code design
- YAML desired-state modeling
- Infrastructure manifest validation
- Three-tier application architecture
- Network segmentation planning
- Compute capacity documentation
- Storage architecture documentation
- Deployment sequencing
- Rollback procedure design
- Diagrams-as-code
- Graphviz-based architecture rendering
- Infrastructure repository organization
- Architecture communication
- Version-controlled operational documentation

## Real-World Use Case

Infrastructure implementations frequently fail because architecture decisions exist only in engineers' heads, informal conversations, or disconnected diagrams.

A documentation-first workflow creates a structured architectural contract before infrastructure is provisioned. Platform, DevOps, AIOps, security, application, and operations teams can review network boundaries, compute requirements, storage dependencies, deployment sequencing, and rollback procedures before automation reaches production.

The same design can later become the input for Terraform modules, Ansible automation, Kubernetes manifests, cloud provisioning pipelines, policy checks, validation systems, and CI/CD workflows.

For AI and MLOps platforms, this pattern can similarly document inference services, API gateways, model-serving nodes, feature stores, databases, observability infrastructure, and private network boundaries before deployment automation is introduced.

## Lessons Learned

- Infrastructure documentation can act as an architectural contract before provisioning begins.
- YAML provides a readable structured format for expressing desired infrastructure intent.
- Infrastructure manifests should separate environment-specific requirements from implementation logic.
- Architecture diagrams should match the declared infrastructure model rather than present a simplified topology that contradicts configuration.
- Network boundaries and service ports should be documented explicitly.
- Deployment order should reflect infrastructure dependencies.
- Rollback procedures should exist before deployment rather than being invented during an incident.
- Diagrams-as-code make architecture changes reviewable and version controlled.
- Generated images should be treated as derived artifacts while their source code remains the maintainable representation.

## Troubleshooting Log

### Missing Python Package Manager

The fresh Ubuntu environment contained Python 3 but did not contain pip or pipx.

Rather than modifying the distribution-managed Python environment directly, pipx was installed:

    sudo apt-get install -y pipx

This provides isolated Python application environments.

### Missing Graphviz

Graphviz was not installed in the fresh environment.

It was installed using:

    sudo apt-get install -y graphviz

Graphviz provides the `dot` renderer required by the Python diagrams library.

### Isolated Diagrams Installation

The diagrams package was installed using:

    pipx install diagrams

This avoids modifying Ubuntu's system Python packages directly.

### Existing PyYAML

PyYAML was already available in the environment.

The YAML manifest could therefore be validated directly with:

    python3 -c "import yaml; yaml.safe_load(open('environments/dev.yaml')); print('Valid YAML')"

No unnecessary PyYAML installation was performed.

### Diagram and Manifest Mismatch

The original architecture example represented:

    1 web node
    1 application node
    1 database node

while the YAML desired-state manifest specified:

    2 web instances
    2 application instances
    1 database

The diagram implementation was corrected to represent:

    web-01
    web-02
    app-01
    app-02
    PostgreSQL 14

This ensures the visual architecture remains consistent with the declared desired state.

### Diagram Generation Verification

The architecture generator was executed through the isolated diagrams environment:

    pipx run --spec diagrams python scripts/generate_diagram.py

The resulting artifact was verified using:

    file docs/architecture.png

The Python source was also syntax checked using:

    pipx run --spec diagrams python -m py_compile scripts/generate_diagram.py
