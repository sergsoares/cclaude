#!/bin/bash

# Runtime TLS Certificate Generation and ttyd Startup Script
# Generates self-signed certificates and launches ttyd with TLS encryption

set -e

# Configuration from environment variables with defaults
CERT_COMMON_NAME=${CERT_COMMON_NAME:-"localhost"}
CERT_VALIDITY_DAYS=${CERT_VALIDITY_DAYS:-365}
CERT_KEY_SIZE=${CERT_KEY_SIZE:-4096}
TTYD_PORT=${TTYD_PORT:-7681}
TTYD_COMMAND=${TTYD_COMMAND:-"bash"}
CERT_DIR="/home/agent/certs"
CERT_FILE="$CERT_DIR/cert.pem"
KEY_FILE="$CERT_DIR/key.pem"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create certificate directory
create_cert_directory() {
    log_info "Creating certificate directory: $CERT_DIR"
    mkdir -p "$CERT_DIR"
    chmod 700 "$CERT_DIR"
}

# Check if certificate exists and is valid
check_existing_certificate() {
    if [[ -f "$CERT_FILE" && -f "$KEY_FILE" ]]; then
        log_info "Existing certificate found, checking validity..."
        
        # Check if certificate is still valid (not expired)
        if openssl x509 -checkend 86400 -noout -in "$CERT_FILE" >/dev/null 2>&1; then
            log_info "Existing certificate is valid, using it"
            return 0
        else
            log_warn "Existing certificate is expired or invalid, regenerating..."
            return 1
        fi
    else
        log_info "No existing certificate found, generating new one..."
        return 1
    fi
}

# Generate self-signed certificate
generate_certificate() {
    log_info "Generating self-signed certificate..."
    log_info "Common Name: $CERT_COMMON_NAME"
    log_info "Validity: $CERT_VALIDITY_DAYS days"
    log_info "Key Size: $CERT_KEY_SIZE bits"
    
    # Generate certificate and private key
    openssl req -x509 \
        -newkey rsa:$CERT_KEY_SIZE \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -days $CERT_VALIDITY_DAYS \
        -nodes \
        -subj "/CN=$CERT_COMMON_NAME/O=Claude Agent Container/C=US" \
        -addext "subjectAltName=DNS:localhost,DNS:$CERT_COMMON_NAME,IP:127.0.0.1,IP:0.0.0.0"
    
    if [[ $? -eq 0 ]]; then
        log_info "Certificate generated successfully"
    else
        log_error "Failed to generate certificate"
        exit 1
    fi
}

# Set proper permissions on certificate files
set_certificate_permissions() {
    log_info "Setting certificate file permissions..."
    chmod 600 "$KEY_FILE"   # Private key - owner read/write only
    chmod 644 "$CERT_FILE"  # Certificate - owner read/write, others read
    
    log_info "Certificate files secured"
}

# Validate certificate properties
validate_certificate() {
    log_info "Validating generated certificate..."
    
    # Check certificate details
    local cert_subject=$(openssl x509 -noout -subject -in "$CERT_FILE" | sed 's/subject=//')
    local cert_dates=$(openssl x509 -noout -dates -in "$CERT_FILE")
    
    log_info "Certificate Subject: $cert_subject"
    log_info "Certificate Validity: $cert_dates"
    
    # Verify certificate and key match
    local cert_modulus=$(openssl x509 -noout -modulus -in "$CERT_FILE" | openssl md5)
    local key_modulus=$(openssl rsa -noout -modulus -in "$KEY_FILE" | openssl md5)
    
    if [[ "$cert_modulus" == "$key_modulus" ]]; then
        log_info "Certificate and private key match - validation successful"
    else
        log_error "Certificate and private key do not match"
        exit 1
    fi
}

# Launch ttyd with TLS
launch_ttyd() {
    log_info "Starting ttyd with TLS encryption..."
    log_info "Port: $TTYD_PORT"
    log_info "Command: $TTYD_COMMAND"
    log_info "Certificate: $CERT_FILE"
    log_info "Private Key: $KEY_FILE"
    
    # Check if ttyd binary exists
    if ! command -v ttyd &> /dev/null; then
        log_error "ttyd binary not found"
        exit 1
    fi
    
    # Launch ttyd with SSL enabled
    exec ttyd \
        --ssl \
        --ssl-cert "$CERT_FILE" \
        --ssl-key "$KEY_FILE" \
        --port "$TTYD_PORT" \
        --writable \
        $TTYD_COMMAND
}

# Main execution
main() {
    log_info "=== Claude Agent Container - ttyd TLS Startup ==="
    log_info "Initializing TLS-enabled terminal server..."
    
    # Create certificate directory
    create_cert_directory
    
    # Check for existing valid certificate or generate new one
    if ! check_existing_certificate; then
        generate_certificate
        set_certificate_permissions
        validate_certificate
    fi
    
    # Launch ttyd with TLS
    launch_ttyd
}

# Trap signals for graceful shutdown
trap 'log_info "Shutting down ttyd..."; exit 0' SIGTERM SIGINT

# Execute main function
main "$@"