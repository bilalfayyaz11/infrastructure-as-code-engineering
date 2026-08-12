# Infrastructure Components

## Compute

| Tier | Instances | CPU | Memory | Port |
|------|-----------|-----|--------|------|
| Web | 2 | 1 vCPU | 2GB | 80 |
| App | 2 | 2 vCPU | 4GB | 8080 |

## Networking

| Subnet Name | CIDR Block | Purpose |
|-------------|------------|---------|
| web-subnet | 10.0.1.0/24 | Web tier traffic |
| app-subnet | 10.0.2.0/24 | Application tier traffic |
| db-subnet | 10.0.3.0/24 | Database traffic |

## Storage

| Component | Engine | Version | Size | Port |
|-----------|--------|---------|------|------|
| Database | PostgreSQL | 14 | 20GB | 5432 |

## Traffic Flow

Client traffic enters the web tier on port 80.

The web tier communicates with the application tier on port 8080.

The application tier communicates with PostgreSQL on port 5432.

The database tier should not be directly exposed to external clients.
