# Standalone Mininet Docker Container

A ready-to-use Docker container with Mininet and Ryu controller for SDN development and testing.

**✅ Apple Silicon Compatible** - This container is fully tested and optimized for Apple Silicon (M1/M2/M3/M4) Macs.

_Created by [Amirreza Alibeigi](https://github.com/amirreza225)_

## Features

- **Mininet**: Full mininet installation for network emulation
- **Ryu Controller**: SDN controller framework pre-installed
- **Network Tools**: iperf, ping, curl, and other network utilities
- **Development Environment**: Python 3, pip, git, vim, nano
- **Privileged Mode**: Full network capabilities for creating virtual networks
- **Host Networking**: Direct access to host network interfaces
- **Persistent Storage**: Projects directory mounted for code persistence
- **Apple Silicon Support**: Optimized for M1/M2/M3/M4 Macs with full compatibility
- **Ready Examples**: Pre-built controller and topology examples included
- **X11 Display Forwarding**: xterm and Wireshark work out of the box on macOS via XQuartz

## Quick Start

### 1. Build the Container

```bash
./docker-run.sh build
```

### 2. Run the Container

```bash
./docker-run.sh run
```

### 3. Test Mininet

Inside the container:

```bash
# Test basic mininet functionality
sudo mn --test pingall

# Create simple topology
sudo mn --topo single,3 --controller remote,ip=127.0.0.1,port=6653

# In mininet prompt:
mininet> pingall
mininet> h1 ping h2
mininet> exit
```

### 4. Test with Included Examples

```bash
# Terminal 1: Start example Ryu controller
ryu-manager examples/simple_controller.py

# Terminal 2: In new shell (./docker-run.sh shell)
python3 examples/simple_topology.py

# Test connectivity in mininet prompt:
mininet> pingall
mininet> exit
```

## Available Commands

```bash
./docker-run.sh build     # Build Docker image
./docker-run.sh run       # Start container interactively
./docker-run.sh shell     # Enter running container
./docker-run.sh stop      # Stop container
./docker-run.sh status    # Show container status
./docker-run.sh logs      # View container logs
./docker-run.sh clean     # Remove container and image
./docker-run.sh help      # Show help
```

## Container Features

### Pre-installed Software

- Ubuntu 20.04 base (ARM64/AMD64 compatible)
- Mininet 2.3+ (built from source for Apple Silicon)
- Python 3.8+
- Ryu SDN Controller 4.34
- Open vSwitch (auto-started)
- Network utilities (iperf, ping, curl, wget, tcpdump)
- Development tools (git, vim, nano)
- X11 GUI tools: **xterm**, **Wireshark**, x11-apps (xclock, xeyes)
- Example SDN controller and topology files

### Network Configuration

- **Privileged mode**: Required for creating network namespaces
- **Host networking**: Direct access to host network interfaces
- **Port exposure**: 6653 (OpenFlow), 8080 (REST API), 8000 (Web server)

### File Persistence

- `/app/projects/` - Mounted from host `./projects/` directory
- Store your SDN projects here for persistence across container restarts

## Usage Examples

### Basic Mininet Testing

```bash
# Simple topology test
sudo mn --test pingall

# Custom topology
sudo mn --topo tree,depth=2,fanout=3

# With bandwidth limits
sudo mn --link tc,bw=10

# Linear topology with 4 switches
sudo mn --topo linear,4
```

### SDN Controller Development

```bash
# 1. Create a simple controller (in projects/ directory)
# 2. Start controller in one terminal
cd /app/projects
ryu-manager my_controller.py

# 3. Start mininet in another terminal
sudo mn --controller remote,ip=127.0.0.1,port=6653
```

### Load Testing

```bash
# Start iperf server on host h2
mininet> h2 iperf -s &

# Generate traffic from h1 to h2
mininet> h1 iperf -c 10.0.0.2 -t 30

# UDP traffic with specific bandwidth
mininet> h1 iperf -c 10.0.0.2 -u -b 100M -t 30
```

## Project Integration

To use this container with your existing SDN projects:

1. **Copy project files** to the `projects/` directory:

   ```bash
   cp -r /path/to/your/sdn/project ./projects/
   ```

2. **Start container**:

   ```bash
   ./docker-run.sh run
   ```

3. **Navigate to your project**:

   ```bash
   cd /app/projects/your-project
   ```

4. **Run your SDN application**:

   ```bash
   # Start controller
   ryu-manager your_controller.py

   # In another terminal
   ./docker-run.sh shell
   sudo python3 your_topology.py
   ```

## Display Forwarding — xterm & Wireshark on macOS (Apple Silicon)

On Apple Silicon (and Intel) Macs, Docker Desktop runs inside a Linux VM.
This means the traditional Unix X11 socket approach does **not** work from inside
the container. Instead, you forward the display over TCP to **XQuartz** running
on your Mac.

This container already ships with **xterm**, **Wireshark**, and the standard X11
apps (`xclock`, `xeyes`) pre-installed, and `docker-run.sh` sets the correct
`DISPLAY` value automatically. You only need to do the one-time host setup below.

### One-time macOS host setup

**Step 1 — Install XQuartz**

```bash
brew install --cask xquartz
```

After installation **log out and log back in** (or reboot) so XQuartz registers
its socket correctly.

**Step 2 — Allow network connections in XQuartz**

Open **XQuartz → Settings → Security** and tick
**"Allow connections from network clients"**.
Restart XQuartz after saving this setting.

**Step 3 — Allow localhost connections**

In a regular Mac Terminal (not inside Docker), run:

```bash
xhost +localhost
```

You need to repeat this whenever XQuartz is restarted (add it to your shell
profile to make it permanent).

### Start the container

Use the normal run command — `docker-run.sh` detects macOS automatically and
passes `DISPLAY=host.docker.internal:0` to the container:

```bash
./docker-run.sh run
```

### Test X11 inside the container

```bash
xclock &      # A clock should appear on your Mac — X11 is working
xterm &       # Opens a standalone terminal window on your Mac
wireshark &   # Launches the Wireshark GUI on your Mac
```

### Use xterm and Wireshark from Mininet

```bash
# Open interactive xterm windows for individual hosts
mininet> xterm h1 h2

# Capture and inspect traffic on a specific host with Wireshark (GUI if DISPLAY is available)
mininet> h1 wireshark &

# Or start capture on h1's interface from the CLI
mininet> h1 wireshark -i h1-eth0 &
```

In headless Linux environments (no `DISPLAY`), the `wireshark` command
automatically falls back to `tshark` so capture commands still work.

### Troubleshooting display issues

| Symptom | Fix |
|---------|-----|
| `Error: Can't open display` | Make sure XQuartz is running and you ran `xhost +localhost` |
| Headless Linux / CI runner (no GUI) | Use `h1 wireshark -i h1-eth0` as usual; it automatically falls back to `tshark` |
| Window appears then closes | XQuartz Security setting "Allow network clients" may not be enabled — restart XQuartz after enabling it |
| `Authorization required` | Run `xhost +localhost` again in a Mac Terminal |
| Works but very slow | Normal for the first launch; subsequent windows open faster |

---

## Troubleshooting

### Container Won't Start

```bash
# Check Docker is running
docker info

# Rebuild image
./docker-run.sh clean
./docker-run.sh build
```

### Network Issues

```bash
# Clean mininet state
sudo mn -c

# Restart Open vSwitch if needed
service openvswitch-switch restart

# Check if ports are available
netstat -tlnp | grep 6653
```

### Apple Silicon Specific

```bash
# If you see architecture warnings, rebuild:
./docker-run.sh clean
./docker-run.sh build

# The container uses multi-arch Ubuntu base for compatibility
```

### Permission Issues

```bash
# The container runs as root for network privileges
# Files created in projects/ will be owned by root
# To fix ownership on host:
sudo chown -R $USER:$USER ./projects/
```

## Advanced Usage

### Custom Controller Ports

```bash
# Start controller on custom port
ryu-manager --ofp-tcp-listen-port 6654 controller.py

# Connect mininet to custom port
sudo mn --controller remote,ip=127.0.0.1,port=6654
```

### Multiple Controllers

```bash
# Primary controller
ryu-manager --ofp-tcp-listen-port 6653 primary.py &

# Secondary controller
ryu-manager --ofp-tcp-listen-port 6654 secondary.py &

# Mininet with failover
sudo mn --controller remote,ip=127.0.0.1,port=6653 \
        --controller remote,ip=127.0.0.1,port=6654
```

### Web Interface Access

```bash
# If your controller has a web interface on port 8080
# Access from host browser: http://localhost:8080
```

## Container Management

### Persistent Container

```bash
# Run container in background
docker run -d --privileged --name mininet-dev \
  --network host \
  -v "$(pwd)/projects:/app/projects" \
  mininet-standalone sleep infinity

# Enter when needed
docker exec -it mininet-dev bash
```

### Resource Monitoring

```bash
# Monitor container resources
docker stats mininet-dev

# View container processes
docker exec mininet-dev ps aux
```

This standalone container provides a complete SDN development environment that can be used independently or integrated with existing projects.

---

## Author

**Amirreza Alibeigi**

- GitHub: [@amirreza225](https://github.com/amirreza225)
- Politecnico di Milano

_This container was developed as part of advanced SDN research and provides a reliable, cross-platform environment for Software Defined Networking development and education._
