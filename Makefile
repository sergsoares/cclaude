# Makefile for Claude Agent Container Image

.PHONY: build run stop clean test validate validate-claude claude

# Variables
IMAGE_NAME := claude-agent-image
CONTAINER_NAME := claude-agent
PORTS := -p 7681:7681

# Install cli 
install:
	sudo install -o root -g root -m 0755 cclaude /usr/local/bin/cclaude

# Install cli 
install-mac:
	sudo chmod +x cclaude
	sudo cp cclaude /usr/local/bin/cclaude

# Build the container image
build:
	podman build -t $(IMAGE_NAME) .

# Run the container in detached mode
run:
	podman run --rm -d --name $(CONTAINER_NAME) $(PORTS) $(IMAGE_NAME)

# Run the container interactively
run-interactive:
	podman run --rm -it --name $(CONTAINER_NAME) $(PORTS) $(IMAGE_NAME)

# Stop the running container
stop:
	podman stop $(CONTAINER_NAME)

# Remove the container image
clean:
	podman rmi $(IMAGE_NAME)

# Enter bash inside container
bash:
	podman exec -it $(CONTAINER_NAME) bash

# Run claude command inside container (usage: make claude CMD="your command here")
claude:
	podman run --rm -it -v $(PWD):/workspace -w /workspace $(PORTS) $(IMAGE_NAME) claude $(CMD)

# Test all installed tools
test:
	podman exec $(CONTAINER_NAME) node --version
	podman exec $(CONTAINER_NAME) ttyd --version
	podman exec $(CONTAINER_NAME) kubectl version --client
	podman exec $(CONTAINER_NAME) terraform --version
	podman exec $(CONTAINER_NAME) helm version
	podman exec $(CONTAINER_NAME) yq --version
	podman exec $(CONTAINER_NAME) jq --version
	podman exec $(CONTAINER_NAME) envsubst --version
	podman exec $(CONTAINER_NAME) overmind --version
	podman exec $(CONTAINER_NAME) claude --version

# Test overmind process management
test-overmind:
	podman exec $(CONTAINER_NAME) overmind ps

# Restart terminal process
restart-terminal:
	podman exec $(CONTAINER_NAME) overmind restart terminal

# Validate container is running
validate:
	podman ps | grep $(CONTAINER_NAME)

# Validate Claude Code is installed, install if missing
validate-claude:
	@podman exec $(CONTAINER_NAME) bash -c 'if ! command -v claude >/dev/null 2>&1; then echo "Claude Code not found, installing..."; npm install -g @anthropic-ai/claude-code; echo "Claude Code installed successfully"; else echo "Claude Code is already installed: $$(claude --version)"; fi'

# Show container logs
logs:
	podman logs $(CONTAINER_NAME)

# Full deployment (build and run)
deploy: build run

# Full test cycle (build, run, test, stop)
test-cycle: build run test stop

# Test TLS certificate functionality
test-tls:
	podman exec $(CONTAINER_NAME) openssl x509 -in /home/agent/certs/cert.pem -text -noout
	podman exec $(CONTAINER_NAME) openssl x509 -in /home/agent/certs/cert.pem -checkend 86400 -noout

# Test HTTPS connectivity
test-https:
	curl -k -I https://localhost:7681

# Show help
help:
	@echo "Available targets:"
	@echo "  build           - Build the container image"
	@echo "  run             - Run container in detached mode"
	@echo "  run-interactive - Run container interactively"
	@echo "  stop            - Stop the running container"
	@echo "  clean           - Remove the container image"
	@echo "  bash            - Enter bash inside container"
	@echo "  claude CMD=\"..\" - Run claude command inside container"
	@echo "  test            - Test all installed tools"
	@echo "  test-overmind   - Test overmind process management"
	@echo "  test-tls        - Test TLS certificate functionality"
	@echo "  test-https      - Test HTTPS connectivity"
	@echo "  restart-terminal- Restart ttyd terminal"
	@echo "  validate        - Check if container is running"
	@echo "  validate-claude - Validate Claude Code installation, install if missing"
	@echo "  logs            - Show container logs"
	@echo "  deploy          - Build and run (full deployment)"
	@echo "  test-cycle      - Full test cycle (build, run, test, stop)"
	@echo "  help            - Show this help message"
