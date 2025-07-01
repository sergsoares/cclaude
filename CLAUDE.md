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

## Container Entry Points

### Current Implementation
- **Direct ttyd** - Terminal server running on port 7681 with writable access
- Single-process container with ttyd as the main entrypoint

### Process Management (Available but not active)
The container includes [DarthSim/overmind](https://github.com/DarthSim/overmind) for managing multiple processes (kept for future use):

- **Caddy** - Web server running on port 8080 (available via overmind)
- **ttyd** - Terminal server (can be managed via overmind)

### Overmind Commands (when using overmind entrypoint)
- `overmind ps` - Show process status
- `overmind restart web` - Restart Caddy web server
- `overmind restart terminal` - Restart ttyd terminal
- `overmind connect <process>` - Connect to a specific process

### Available Makefile targets
- `make test-overmind` - Test overmind process management
- `make restart-web` - Restart Caddy web server
- `make restart-terminal` - Restart ttyd terminal
- `make test-tls` - Test TLS certificate functionality
- `make test-https` - Test HTTPS connectivity

## Git rules
- Every work will be done in feature branches that can be created following that example: feature/example
- Not commit directly to main
- After end of any success changes can push to feature branch


## TLS Configuration

The container now supports TLS encryption for ttyd terminal access:

### Environment Variables
- `CERT_COMMON_NAME`: Certificate common name (default: localhost)
- `CERT_VALIDITY_DAYS`: Certificate validity period (default: 365)
- `CERT_KEY_SIZE`: RSA key size in bits (default: 4096)
- `TTYD_PORT`: ttyd listening port (default: 7681)
- `TTYD_COMMAND`: Shell command to run in ttyd (default: bash)

### Features
- Runtime certificate generation using OpenSSL
- Self-signed certificates with proper Subject Alternative Names
- Automatic certificate validation and renewal
- Secure file permissions for certificate files
- TLS encryption for all terminal traffic

### Usage
The container automatically generates TLS certificates at startup and launches ttyd with HTTPS enabled on port 7681.

#### Custom Shell Commands
You can specify a different shell or command for ttyd by setting the `TTYD_COMMAND` environment variable:

```bash
# Use zsh instead of bash
podman run -e TTYD_COMMAND="zsh" -p 7681:7681 claude-agent

# Run a custom script
podman run -e TTYD_COMMAND="/path/to/script.sh" -p 7681:7681 claude-agent

# Use fish shell
podman run -e TTYD_COMMAND="fish" -p 7681:7681 claude-agent
```

## Notifications
- There is a bash function prepared for notify you can call like in the example with a brief with max 5 words the status of tasks: notify_claude "<CONTENT>" 
  When job is done or any error or pending edit is necessary