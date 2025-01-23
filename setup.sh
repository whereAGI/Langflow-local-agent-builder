#!/bin/bash

# Exit on error
set -e

# ====== CREATE WORKSPACE ======
WORKSPACE_DIR=${WORKSPACE:-/workspace}
mkdir -p $WORKSPACE_DIR
cd $WORKSPACE_DIR

# ====== INSTALL DEPENDENCIES ======
apt update -y
apt install -y curl python3 python3-pip python3-venv sudo

# ====== INSTALL OLLAMA ======
curl -fsSL https://ollama.com/install.sh | sh
sudo -u root nohup ollama serve > $WORKSPACE_DIR/ollama.log 2>&1 &

# Wait for Ollama to start
sleep 5
if ! pgrep -x "ollama" > /dev/null; then
    echo "Error: Ollama failed to start"
    exit 1
fi

# ====== INSTALL VS CODE SERVER ======
curl -fsSL https://code-server.dev/install.sh | sh

# Generate random password if not provided
VSCODE_PASSWORD=${PASSWORD:-$(openssl rand -base64 12)}

# Start VS Code with root access and password
sudo -u root nohup code-server \
    --auth password \
    --port 8080 \
    --bind-addr 0.0.0.0 \
    --disable-telemetry \
    --password "$VSCODE_PASSWORD" \
    $WORKSPACE_DIR > $WORKSPACE_DIR/vscode.log 2>&1 &

# Wait for VS Code to start
sleep 5
if ! curl -s http://localhost:8080 > /dev/null; then
    echo "Error: VS Code server failed to start"
    exit 1
fi

# ====== INSTALL LANGFLOW ======
python3 -m venv $WORKSPACE_DIR/langflow-env
source $WORKSPACE_DIR/langflow-env/bin/activate
pip install langflow

# Start LangFlow
nohup langflow run \
    --host 0.0.0.0 \
    --port 3000 \
    --log-level debug \
    > $WORKSPACE_DIR/langflow.log 2>&1 &

# Wait for LangFlow to start
sleep 10
if ! curl -s http://localhost:3000 > /dev/null; then
    echo "Error: LangFlow failed to start"
    exit 1
fi

# ====== FINALIZE PERMISSIONS ======
chmod -R 777 $WORKSPACE_DIR

echo "Setup completed successfully!"
echo "Services running on:"
echo "- VS Code: http://localhost:8080 (Password: $VSCODE_PASSWORD)"
echo "- LangFlow: http://localhost:3000"
echo "- Ollama: Running locally"