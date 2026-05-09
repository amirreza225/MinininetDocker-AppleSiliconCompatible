#!/bin/bash

# Startup script for Mininet Docker container
# Starts required services and provides interactive shell

echo "Starting Mininet Docker Container..."

# Start Open vSwitch services
echo "Starting Open vSwitch services..."
service openvswitch-switch start

# Wait a moment for services to initialize
sleep 2

# Verify OVS is running
echo "Verifying Open vSwitch..."
if ovs-vsctl show >/dev/null 2>&1; then
    echo "✓ Open vSwitch is running"
else
    echo "✗ Open vSwitch failed to start"
    echo "Attempting to restart..."
    service openvswitch-switch restart
    sleep 2
fi

# Clean up any previous mininet state
echo "Cleaning up previous mininet state..."
mn -c >/dev/null 2>&1 || true

echo "Services started successfully!"
echo ""
echo "Available commands:"
echo "  mn --test pingall                          # Quick connectivity test"
echo "  python3 examples/simple_topology.py        # Run example topology"
echo "  ryu-manager examples/simple_controller.py  # Start example controller"
echo ""
echo "X11 display commands (requires XQuartz + xhost +localhost on the Mac):"
echo "  xclock &                                   # Quick X11 test"
echo "  xterm &                                    # Open a terminal window"
echo "  wireshark &                                # Launch Wireshark GUI"
echo ""
echo "From the Mininet CLI:"
echo "  mininet> xterm h1 h2                       # Open xterms for h1 and h2"
echo "  mininet> h1 wireshark &                    # Capture traffic on host h1"
echo ""
echo "Container ready for SDN development!"
echo ""

# If arguments provided, execute them; otherwise start interactive bash
if [ $# -eq 0 ]; then
    exec /bin/bash
else
    exec "$@"
fi