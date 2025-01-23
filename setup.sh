#!/bin/bash

# Exit on error
set -e

# ====== CREATE WORKSPACE ======
mkdir -p /workspace
cd /workspace

# ====== INSTALL DEPENDENCIES ======
apt update -y
apt install -y curl python3 python3-pip python3-venv sudo

# ====== INSTALL OLLAMA ======
curl -fsSL https://ollama.com/install.sh | sh
sudo -u root nohup ollama serve > /workspace/ollama.log 2>&1 &

# Wait for Ollama to start
sleep 5
if ! pgrep -x "ollama" > /dev/null; then
    echo "Error: Ollama failed to start"
    exit 1
fi

# Download models
ollama pull llama2 &
ollama pull mistral &

# ====== INSTALL VS CODE SERVER ======
curl -fsSL https://code-server.dev/install.sh | sh

# Start VS Code with root access and password
sudo -u root nohup code-server \
    --auth password \
    --port 8080 \
    --bind-addr 0.0.0.0 \
    --disable-telemetry \
    /workspace > /workspace/vscode.log 2>&1 &

# Wait for VS Code to start
sleep 5
if ! curl -s http://localhost:8080 > /dev/null; then
    echo "Error: VS Code server failed to start"
    exit 1
fi

# ====== INSTALL LANGFLOW ======
python3 -m venv /workspace/langflow-env
source /workspace/langflow-env/bin/activate
pip install langflow

# Start LangFlow
nohup langflow run \
    --host 0.0.0.0 \
    --port 3000 \
    --log-level debug \
    > /workspace/langflow.log 2>&1 &

# Wait for LangFlow to start
sleep 10
if ! curl -s http://localhost:3000 > /dev/null; then
    echo "Error: LangFlow failed to start"
    exit 1
fi

# ====== FINALIZE PERMISSIONS ======
chmod -R 777 /workspace

echo "Setup completed successfully!"
echo "Services running on:"
echo "- VS Code: http://localhost:8080"
echo "- LangFlow: http://localhost:3000"
echo "- Ollama: Running locally"