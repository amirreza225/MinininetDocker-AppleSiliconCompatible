#!/bin/bash

# Standalone Mininet Docker Management Script
# Usage: ./docker-run.sh [command]

CONTAINER_NAME="mininet-dev"
IMAGE_NAME="mininet-standalone"

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo "Error: Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Build the Docker image
build() {
    echo "Building Mininet Docker image..."
    docker build -t $IMAGE_NAME .
    echo "Build complete!"
}

# Determine the correct DISPLAY value for X11 forwarding.
# On macOS (Apple Silicon / Intel), Docker runs inside a VM so the
# Unix socket cannot be shared; use the TCP address via host.docker.internal.
# On Linux the existing DISPLAY environment variable works directly.
get_display() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "host.docker.internal:0"
    else
        echo "${DISPLAY:-:0}"
    fi
}

# Print X11 setup reminder when on macOS
print_display_hint() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo ""
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║  X11 Display Forwarding (xterm / Wireshark) on macOS        ║"
        echo "║                                                              ║"
        echo "║  One-time setup (only needed once):                         ║"
        echo "║  1. Install XQuartz:  brew install --cask xquartz           ║"
        echo "║     Then LOG OUT and back in (or reboot).                   ║"
        echo "║  2. Open XQuartz → Settings → Security                      ║"
        echo "║     ✓ Check \"Allow connections from network clients\"         ║"
        echo "║     Restart XQuartz after changing this setting.            ║"
        echo "║  3. In a Mac Terminal (not inside Docker):                  ║"
        echo "║       xhost +localhost                                       ║"
        echo "║                                                              ║"
        echo "║  Inside the container you can then run:                     ║"
        echo "║    xclock &          ← quick X11 test                       ║"
        echo "║    xterm &           ← open a terminal window               ║"
        echo "║    wireshark &       ← launch Wireshark GUI                 ║"
        echo "║                                                              ║"
        echo "║  From the Mininet prompt:                                    ║"
        echo "║    mininet> xterm h1 h2   ← open xterms for hosts h1, h2    ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo ""
    fi
}

# Run the container
run() {
    check_docker
    
    # Stop existing container if running
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo "Stopping existing container..."
        docker stop $CONTAINER_NAME
    fi
    
    # Remove existing container if exists
    if docker ps -aq -f name=$CONTAINER_NAME | grep -q .; then
        echo "Removing existing container..."
        docker rm $CONTAINER_NAME
    fi
    
    print_display_hint

    echo "Starting new Mininet container..."
    docker run -it --privileged \
        --name $CONTAINER_NAME \
        --network host \
        -e DISPLAY="$(get_display)" \
        -v "$(pwd)/projects:/app/projects" \
        -v "/lib/modules:/lib/modules:ro" \
        $IMAGE_NAME
}

# Enter running container
shell() {
    check_docker
    if ! docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo "Container $CONTAINER_NAME is not running. Starting it first..."
        run
    else
        echo "Entering container shell..."
        docker exec -it $CONTAINER_NAME /bin/bash
    fi
}

# Stop the container
stop() {
    check_docker
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo "Stopping container..."
        docker stop $CONTAINER_NAME
        echo "Container stopped"
    else
        echo "Container is not running"
    fi
}

# Show container status
status() {
    check_docker
    echo "Container status:"
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo "✓ Running"
        docker ps -f name=$CONTAINER_NAME --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "✗ Not running"
    fi
}

# Show container logs
logs() {
    check_docker
    docker logs $CONTAINER_NAME
}

# Clean up everything
clean() {
    check_docker
    echo "Cleaning up Docker resources..."
    
    # Stop and remove container
    if docker ps -aq -f name=$CONTAINER_NAME | grep -q .; then
        docker stop $CONTAINER_NAME 2>/dev/null
        docker rm $CONTAINER_NAME 2>/dev/null
        echo "Container removed"
    fi
    
    # Remove image
    if docker images -q $IMAGE_NAME | grep -q .; then
        docker rmi $IMAGE_NAME
        echo "Image removed"
    fi
    
    echo "Cleanup complete!"
}

# Show help
help() {
    echo "Standalone Mininet Docker Management Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  build    - Build the Docker image"
    echo "  run      - Run the container (builds if needed)"
    echo "  shell    - Enter container shell (starts if needed)"
    echo "  stop     - Stop the container"
    echo "  status   - Show container status"
    echo "  logs     - Show container logs"
    echo "  clean    - Remove container and image"
    echo "  help     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build         # Build the image"
    echo "  $0 run           # Start container interactively"
    echo "  $0 shell         # Open new shell in running container"
    echo ""
    echo "Quick Start:"
    echo "  1. $0 build      # Build the image first"
    echo "  2. $0 run        # Start container"
    echo "  3. Inside container: sudo mn --test pingall"
}

# Main script logic
case "${1:-help}" in
    build)   build ;;
    run)     run ;;
    shell)   shell ;;
    stop)    stop ;;
    status)  status ;;
    logs)    logs ;;
    clean)   clean ;;
    help)    help ;;
    *)       echo "Unknown command: $1"; help; exit 1 ;;
esac
