# Claude Agent Container Image

A Docker/Podman container image pre-configured with Claude Code CLI and essential DevOps tools for agentic development workflows.

## Features

- **Claude Code CLI** - Anthropic's official CLI for Claude interactions
- **Terminal Access** - TLS-enabled ttyd terminal server on port 7681
- **DevOps Tools** - kubectl, terraform, helm, yq, jq, envsubst
- **Process Management** - Overmind for multi-process management
- **Security** - TLS encryption with runtime certificate generation
- **Authentication** - Optional HTTP Basic Authentication

## Quick Start

### CLI Wrapper (Recommended)

For the easiest experience, use the provided CLI wrapper script:

```bash
# Install the CLI wrapper
curl -o claude-agent https://raw.githubusercontent.com/yourusername/claude-agent-image/main/claude-agent
chmod +x claude-agent
sudo mv claude-agent /usr/local/bin/

# Or add to your PATH
export PATH="$PATH:/path/to/claude-agent-image"
```

Usage examples:
```bash
# Interactive Claude session
claude-agent

# Run Claude with a prompt
claude-agent "analyze this codebase"

# Start terminal server
claude-agent --terminal

# Get help
claude-agent --help

# Run without mounting config
claude-agent --no-config --help
```

### Run Terminal Server (Default)

Start the container with web terminal access:

```bash
# Basic usage
podman run -p 7681:7681 claude-agent-image

# With authentication
podman run -e TTYD_AUTH_USER="admin" -e TTYD_AUTH_PASSWORD="secure123" -p 7681:7681 claude-agent-image

# With custom shell
podman run -e TTYD_COMMAND="zsh" -p 7681:7681 claude-agent-image
```

Access the terminal at: https://localhost:7681

### Run Claude CLI Directly

Execute Claude Code commands directly without starting the terminal server:

```bash
# Run claude command directly
podman run --rm claude-agent-image claude --help

# Interactive Claude session
podman run --rm -it claude-agent-image claude

# Mount current directory and run Claude on local files
podman run --rm -v $(pwd):/workspace -w /workspace claude-agent-image claude "analyze this codebase"

# Run Claude with specific prompt
podman run --rm -v $(pwd):/workspace -w /workspace claude-agent-image claude "fix the bug in main.py"

# Advanced usage with Claude configuration persistence
podman run \
    -v "${HOME}/.claude:/home/agent/.claude" \
    -v "${HOME}/.claude.json:/home/agent/.claude.json" \
    -v "${PWD}:${PWD}" \
    -w "$PWD" \
    --rm \
    --name "claude-cli" \
    -ti \
    claude-agent-image claude "$@"
```

### Development Workflow Examples

```bash
# Start persistent development environment
podman run -d --name dev-env -p 7681:7681 -v $(pwd):/workspace claude-agent-image

# Execute commands in running container
podman exec dev-env claude "review the code changes"
podman exec dev-env kubectl get pods
podman exec dev-env terraform plan

# Access interactive terminal
podman exec -it dev-env bash
```

## Environment Variables

### Container Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TTYD_PORT` | `7681` | Terminal server port |
| `TTYD_COMMAND` | `bash` | Shell command to run |
| `TTYD_AUTH_USER` | _(empty)_ | Basic auth username |
| `TTYD_AUTH_PASSWORD` | _(empty)_ | Basic auth password |
| `CERT_COMMON_NAME` | `localhost` | TLS certificate common name |
| `CERT_VALIDITY_DAYS` | `365` | Certificate validity period |
| `CERT_KEY_SIZE` | `4096` | RSA key size in bits |

### CLI Wrapper Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_AGENT_IMAGE` | `claude-agent-image` | Container image name |
| `CLAUDE_AGENT_NAME` | `claude-cli-TIMESTAMP` | Container name prefix |
| `PODMAN_ARGS` | _(empty)_ | Additional podman arguments |

## Installed Tools

- **Node.js** 20.19.3
- **Claude Code CLI** (latest via npm)
- **ttyd** 1.7.7 - Web terminal
- **kubectl** (latest stable)
- **terraform** (latest)
- **helm** (latest)
- **yq** (latest)
- **jq** 1.6
- **envsubst** (gettext)
- **overmind** 2.5.1 - Process manager

## Build and Development

```bash
# Build the image
make build

# Run with terminal server
make run

# Test all installed tools
make test

# Validate Claude Code installation
make validate-claude

# View logs
make logs

# Stop container
make stop
```

## Security Notes

- **TLS Encryption**: All terminal traffic is encrypted with self-signed certificates
- **Authentication**: Configure `TTYD_AUTH_USER` and `TTYD_AUTH_PASSWORD` for production
- **Network Access**: Container only exposes port 7681 for terminal access
- **User Permissions**: Runs as non-root `agent` user with sudo access

## Use Cases

- **AI-Assisted Development** - Interactive Claude sessions with full DevOps toolkit
- **Infrastructure Management** - Kubernetes, Terraform, and Helm operations
- **Data Processing** - YAML/JSON manipulation with yq/jq
- **Remote Development** - Secure web-based terminal access
- **CI/CD Integration** - Container-based build and deployment pipelines

## License

This project follows the same licensing as the tools it contains. See individual tool documentation for specific license information.