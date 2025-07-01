This project is to maintaing a Dockerfile for create a image already prepared to be used as agentic.

- Use ubuntu as base image, because it need to be easy update configurations.
- The target container image will be used by podman, consider it
- Install caddy reverse proxy
- Install ttyd from snap to allow expose terminal page for Claude
- Use image as base node:20.19.3-bookworm-slim@sha256:f8f6771d949ff351c061de64ef9cbfbc5949015883fb3b016b34aca6d0e5b8cc

## Packages that need to be inside the container image
- claude code
- kubectl
- terraform
- helm
- yq
- jq
- envsubst

## Process Management
The container uses [DarthSim/overmind](https://github.com/DarthSim/overmind) for managing multiple processes:

- **Caddy** - Web server running on port 8080
- **ttyd** - Terminal server running on port 7681 with writable access

### Overmind Commands
- `overmind ps` - Show process status
- `overmind restart web` - Restart Caddy web server
- `overmind restart terminal` - Restart ttyd terminal
- `overmind connect <process>` - Connect to a specific process

### Available Makefile targets
- `make test-overmind` - Test overmind process management
- `make restart-web` - Restart Caddy web server
- `make restart-terminal` - Restart ttyd terminal