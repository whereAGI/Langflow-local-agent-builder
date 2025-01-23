#!/bin/bash
# ====== INSTALL DEPENDENCIES ======
apt update -y
apt install -y curl python3 python3-pip python3-venv sudo
# ====== INSTALL OLLAMA ======
curl -fsSL https://ollama.com/install.sh | sh
sudo -u root nohup ollama serve > /workspace/ollama.log 2>&1 &
# Download models (e.g., llama3, mistral)
ollama pull llama3 &
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
# ====== FINALIZE PERMISSIONS ======
chmod -R 777 /workspace