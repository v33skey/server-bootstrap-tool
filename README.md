# Server bootstrap tool

## About

Educational project created to practice Bash scripting, Linux administration, and infrastructure automation.  
The project is under active development and will be expanded with additional provisioning features over time.

## What It Does

Bash automation script for initial Linux server bootstrap.

## Current Features

- SSH key generation
- SSH key deployment to target server
- Non-root user creation
- Docker installation (Ubuntu/Debian supported)
- Interactive system menu

## Planned Features

- Nginx installation

## Requirements

- Bash-compatible environment
- Ubuntu/Debian target server
- SSH access to target server

## Usage

### Linux

```bash
chmod +x automation.sh
./automation.sh
```

### Windows (WSL / Git Bash)

```bash
./automation.sh
```

## Security Notes

Current implementation uses passwordless sudo for bootstrap automation.
This will be refactored in future versions to use temporary privilege escalation.

## Roadmap

- [x] Docker installation
- [x] SSH key deployment
- [x] Temporary sudo bootstrap refactor
- [x] Nginx installation
- [ ] Firewall setup

## Status

Active development
