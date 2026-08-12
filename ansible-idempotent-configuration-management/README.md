# Ansible Idempotent Configuration Management

## What This Does

This implementation demonstrates declarative Linux configuration management using Ansible with a local inventory and an idempotent playbook.

The automation creates and manages an application directory, provisions a configuration file, enforces required configuration values, and uses an Ansible handler to respond only when managed configuration changes.

The workflow also validates true idempotency by executing the same playbook repeatedly and confirming that an already-correct system produces zero unnecessary changes. A managed file is then deliberately removed outside Ansible to simulate configuration drift, after which the playbook restores the expected state automatically.

## Architecture

    ┌──────────────────────────────────────────────────────────────┐
    │                     Ansible Control Node                     │
    │                         localhost                            │
    │                                                              │
    │          inventory.ini + first_playbook.yml                  │
    └──────────────────────────────┬───────────────────────────────┘
                                   │
                                   │ ansible_connection=local
                                   ▼
    ┌──────────────────────────────────────────────────────────────┐
    │                    Ansible Play Execution                    │
    │                                                              │
    │   ansible.builtin.file                                       │
    │          │                                                   │
    │          ▼                                                   │
    │   Create /tmp/myapp                                         │
    │                                                              │
    │   ansible.builtin.copy                                       │
    │          │                                                   │
    │          ▼                                                   │
    │   Manage /tmp/myapp/app.conf                                │
    │                                                              │
    │   ansible.builtin.lineinfile                                 │
    │          │                                                   │
    │          ▼                                                   │
    │   Enforce environment=production                             │
    └──────────────────────────────┬───────────────────────────────┘
                                   │
                          change detected?
                            │           │
                           no          yes
                            │           │
                            ▼           ▼
                    No handler       Notify handler
                                        │
                                        ▼
                              ┌───────────────────────┐
                              │    Config Changed     │
                              │       Handler         │
                              │                       │
                              │ Emits change message  │
                              └───────────────────────┘

                                   │
                                   ▼
    ┌──────────────────────────────────────────────────────────────┐
    │                       Desired State                          │
    │                                                              │
    │ /tmp/myapp                         mode 0755                  │
    │ /tmp/myapp/app.conf                mode 0644                  │
    │                                                              │
    │ # App Configuration File                                    │
    │ application=myapp                                           │
    │ environment=production                                      │
    └──────────────────────────────────────────────────────────────┘

## Prerequisites

- Ubuntu or another supported Linux distribution
- Python 3
- pipx
- ansible-core
- sudo privileges
- Bash-compatible shell
- Git
- Internet access for Ansible installation

## Setup & Installation

Install pipx on Ubuntu:

    sudo apt-get update
    sudo apt-get install -y pipx

Configure the user executable path:

    pipx ensurepath
    export PATH="$HOME/.local/bin:$PATH"

Install Ansible Core:

    pipx install ansible-core

Verify installation:

    ansible --version
    ansible-playbook --version

## Configuration Structure

The implementation contains:

    ansible-local-configuration/
    ├── inventory.ini
    └── first_playbook.yml

The inventory targets the local Linux machine:

    [local]
    localhost ansible_connection=local

Using `ansible_connection=local` allows Ansible to execute configuration management against the control node without requiring SSH.

## How to Reproduce

Clone the repository:

    git clone https://github.com/bilalfayyaz11/infrastructure-as-code-engineering.git
    cd infrastructure-as-code-engineering/ansible-idempotent-configuration-management

Inspect the inventory:

    cat inventory.ini

Inspect the playbook:

    cat first_playbook.yml

Verify the inventory structure:

    ansible-inventory -i inventory.ini --graph

Test Ansible connectivity:

    ansible -i inventory.ini local -m ansible.builtin.ping

Expected result:

    localhost | SUCCESS

with:

    "ping": "pong"

Validate the playbook before execution:

    ansible-playbook -i inventory.ini first_playbook.yml --syntax-check

Execute the playbook:

    ansible-playbook -i inventory.ini first_playbook.yml

Verify the managed directory:

    ls -ld /tmp/myapp

Verify the managed configuration file:

    ls -l /tmp/myapp/app.conf
    cat /tmp/myapp/app.conf

Expected configuration:

    # App Configuration File
    application=myapp
    environment=production

Verify permissions:

    stat -c "%a %n" /tmp/myapp
    stat -c "%a %n" /tmp/myapp/app.conf

Expected permissions:

    755 /tmp/myapp
    644 /tmp/myapp/app.conf

## Idempotency Verification

Run the exact same playbook again:

    ansible-playbook -i inventory.ini first_playbook.yml

Because the machine already matches the desired configuration, the final play recap should report:

    changed=0
    failed=0

This demonstrates true configuration-management idempotency.

Ansible evaluates the current state before changing the machine and avoids performing unnecessary operations when the desired state is already satisfied.

## Configuration Drift Simulation

Remove the configuration file manually outside Ansible:

    sudo rm -f /tmp/myapp/app.conf

Verify that the managed resource has disappeared:

    ls -l /tmp/myapp/app.conf

The file should no longer exist.

Run the playbook again:

    ansible-playbook -i inventory.ini first_playbook.yml

Ansible detects that the real system no longer matches the declared configuration and automatically restores the missing resource.

Verify the restored configuration:

    cat /tmp/myapp/app.conf

Expected result:

    # App Configuration File
    application=myapp
    environment=production

Run the playbook once more:

    ansible-playbook -i inventory.ini first_playbook.yml

The final execution should again report:

    changed=0
    failed=0

This confirms that drift was reconciled and the machine returned to a stable desired state.

## Handler Behavior

The playbook defines a handler named:

    Config Changed

Tasks that modify managed configuration notify this handler.

The handler executes only when a notifying task reports a real change.

If no configuration changes occur, the handler is not executed.

This event-driven behavior avoids unnecessary follow-up operations and is commonly used for actions such as:

- restarting services
- reloading configuration
- restarting application processes
- regenerating dependent files
- sending operational notifications

## Tools Used

- Ansible Core
- Python 3
- pipx
- YAML
- Linux
- Bash
- Git
- ansible.builtin.file
- ansible.builtin.copy
- ansible.builtin.lineinfile
- ansible.builtin.debug
- ansible.builtin.ping

## Key Skills Demonstrated

- Ansible installation and CLI configuration
- Static inventory management
- Local connection configuration
- Ad-hoc Ansible command execution
- Declarative Linux configuration management
- YAML playbook development
- Built-in Ansible module usage
- Privilege escalation with `become`
- Idempotent automation design
- Configuration drift reconciliation
- Handler implementation
- Change-driven automation
- File and directory permission management
- Playbook syntax validation
- Desired-state configuration management

## Real-World Use Case

Ansible is commonly used by infrastructure, DevOps, platform, security, and SRE teams to maintain consistent operating-system and application configuration across fleets of Linux servers.

Instead of administrators manually configuring each machine, engineers describe the required end state using playbooks. Ansible then determines what needs to change and applies only the necessary operations.

The same pattern demonstrated here can be expanded to manage application servers, Kubernetes nodes, MLOps infrastructure, monitoring agents, security controls, system packages, configuration files, users, services, firewall policies, and cloud-host configuration across hundreds or thousands of machines.

Idempotency is particularly important in production because automation must be safe to execute repeatedly without creating duplicate configuration or restarting healthy services unnecessarily.

## Lessons Learned

- Ansible uses declarative automation to enforce a desired machine configuration.
- Inventory defines which systems Ansible manages and how Ansible connects to them.
- `ansible.builtin.ping` verifies Ansible connectivity and Python execution rather than performing an ICMP network ping.
- Idempotent automation changes a machine only when the current state differs from the required state.
- Multiple Ansible modules managing the same file must be designed carefully to avoid continuously overwriting each other's changes.
- Handlers provide event-driven follow-up behavior and execute only when notified by tasks that actually changed state.
- Configuration drift can be corrected automatically by rerunning the same declarative automation.
- Fully Qualified Collection Names make module ownership explicit and reduce ambiguity in larger Ansible environments.

## Troubleshooting Log

### Missing Ansible Installation

The fresh Ubuntu environment contained Python 3 but did not include pip, pipx, or Ansible.

Instead of modifying the operating system's managed Python environment directly, pipx was installed and used to provide an isolated Ansible Core environment.

Installation:

    sudo apt-get install -y pipx
    pipx ensurepath
    pipx install ansible-core

### Modern Ansible Module Naming

Short module names such as:

    file
    copy
    lineinfile
    debug

were replaced with Fully Qualified Collection Names:

    ansible.builtin.file
    ansible.builtin.copy
    ansible.builtin.lineinfile
    ansible.builtin.debug

This makes module sources explicit and reduces potential naming collisions with external collections.

### Idempotency Conflict

The initial design created the configuration file using:

    content: "# App Configuration File\n"

and then added:

    environment=production

using `lineinfile`.

This introduces an idempotency problem.

On subsequent executions, the `copy` module sees additional content in the file and restores the file to only its declared content. The `lineinfile` task then adds the environment setting again.

Both tasks therefore report changes repeatedly even though the final file appears identical after every run.

The configuration was corrected by giving the `copy` module a stable base configuration:

    # App Configuration File
    application=myapp

The independent environment setting is then managed by:

    ansible.builtin.lineinfile

This produces a stable final configuration and allows subsequent executions to report:

    changed=0

### Handler Notification

Configuration-changing tasks notify:

    Config Changed

The handler executes only when an actual change occurs.

A clean idempotent execution does not trigger the handler.

### Drift Reconciliation

The managed configuration file was manually removed using:

    sudo rm -f /tmp/myapp/app.conf

Running the playbook again restored the file and its required contents.

This demonstrated Ansible's ability to reconcile an out-of-band system change back to its declared desired state.
