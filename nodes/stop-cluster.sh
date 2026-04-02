#!/bin/bash
# Stop the local Nomad cluster

echo "==> Stopping Nomad agents..."

if [ -f /tmp/nomad/client1.pid ]; then
  kill "$(cat /tmp/nomad/client1.pid)" 2>/dev/null && echo "    Client 1 stopped." || echo "    Client 1 already stopped."
fi

if [ -f /tmp/nomad/client2.pid ]; then
  kill "$(cat /tmp/nomad/client2.pid)" 2>/dev/null && echo "    Client 2 stopped." || echo "    Client 2 already stopped."
fi

if [ -f /tmp/nomad/server.pid ]; then
  kill "$(cat /tmp/nomad/server.pid)" 2>/dev/null && echo "    Server stopped." || echo "    Server already stopped."
fi

# Clean up any remaining nomad processes
pkill -f "nomad agent" 2>/dev/null || true

echo "==> Cluster stopped."
