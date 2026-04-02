#!/bin/bash
# Start a local Nomad cluster: 1 server + 2 clients
# Usage: ./nodes/start-cluster.sh
# Stop:  ./nodes/stop-cluster.sh

set -e

echo "==> Cleaning up old data dirs..."
rm -rf /tmp/nomad
mkdir -p /tmp/nomad/{server,client1,client2,volumes/nomad-ops}

echo "==> Building CA bundle for Docker containers..."
docker run --rm alpine cat /etc/ssl/certs/ca-certificates.crt > /tmp/nomad/volumes/nomad-ops/ca-certificates.crt 2>/dev/null
security find-certificate -a -p /Library/Keychains/System.keychain >> /tmp/nomad/volumes/nomad-ops/ca-certificates.crt 2>/dev/null
security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain >> /tmp/nomad/volumes/nomad-ops/ca-certificates.crt 2>/dev/null

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Starting Nomad server..."
nomad agent -config="$SCRIPT_DIR/server.hcl" &
SERVER_PID=$!
echo "    Server PID: $SERVER_PID"

# Wait for server to be ready
echo "==> Waiting for server to start..."
for i in $(seq 1 15); do
  if nomad server members &>/dev/null; then
    echo "    Server is ready."
    break
  fi
  sleep 1
done

echo "==> Starting Nomad client 1..."
nomad agent -config="$SCRIPT_DIR/client1.hcl" &
CLIENT1_PID=$!
echo "    Client 1 PID: $CLIENT1_PID"

echo "==> Starting Nomad client 2..."
nomad agent -config="$SCRIPT_DIR/client2.hcl" &
CLIENT2_PID=$!
echo "    Client 2 PID: $CLIENT2_PID"

# Save PIDs for stop script
echo "$SERVER_PID" > /tmp/nomad/server.pid
echo "$CLIENT1_PID" > /tmp/nomad/client1.pid
echo "$CLIENT2_PID" > /tmp/nomad/client2.pid

sleep 3

echo ""
echo "==> Cluster is running!"
echo "    UI:     http://127.0.0.1:4646/ui"
echo ""
echo "==> Node status:"
nomad node status

echo ""
echo "Run ./nodes/stop-cluster.sh to shut down."
