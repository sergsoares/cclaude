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