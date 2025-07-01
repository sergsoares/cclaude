# Makefile for Claude Agent Container Image

.PHONY: build run stop clean test validate

# Variables
IMAGE_NAME := claude-agent-image
CONTAINER_NAME := claude-agent
PORTS := -p 7681:7681 -p 8080:8080

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

# Test all installed tools
test:
	podman exec $(CONTAINER_NAME) node --version
	podman exec $(CONTAINER_NAME) ttyd --version
	podman exec $(CONTAINER_NAME) caddy version
	podman exec $(CONTAINER_NAME) kubectl version --client
	podman exec $(CONTAINER_NAME) terraform --version
	podman exec $(CONTAINER_NAME) helm version
	podman exec $(CONTAINER_NAME) yq --version
	podman exec $(CONTAINER_NAME) jq --version
	podman exec $(CONTAINER_NAME) envsubst --version
	podman exec $(CONTAINER_NAME) overmind --version

# Test overmind process management
test-overmind:
	podman exec $(CONTAINER_NAME) overmind ps

# Restart a specific process
restart-web:
	podman exec $(CONTAINER_NAME) overmind restart web

restart-terminal:
	podman exec $(CONTAINER_NAME) overmind restart terminal

# Validate container is running
validate:
	podman ps | grep $(CONTAINER_NAME)

# Show container logs
logs:
	podman logs $(CONTAINER_NAME)

# Full deployment (build and run)
deploy: build run

# Full test cycle (build, run, test, stop)
test-cycle: build run test stop

# Show help
help:
	@echo "Available targets:"
	@echo "  build           - Build the container image"
	@echo "  run             - Run container in detached mode"
	@echo "  run-interactive - Run container interactively"
	@echo "  stop            - Stop the running container"
	@echo "  clean           - Remove the container image"
	@echo "  bash            - Enter bash inside container"
	@echo "  test            - Test all installed tools"
	@echo "  test-overmind   - Test overmind process management"
	@echo "  restart-web     - Restart Caddy web server"
	@echo "  restart-terminal- Restart ttyd terminal"
	@echo "  validate        - Check if container is running"
	@echo "  logs            - Show container logs"
	@echo "  deploy          - Build and run (full deployment)"
	@echo "  test-cycle      - Full test cycle (build, run, test, stop)"
	@echo "  help            - Show this help message"