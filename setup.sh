#! /bin/bash
set -eo pipefail

# ====== BOOTSTRAP ======
apt-get update && apt-get install -y curl

# ====== DEBUGGING SETUP ======
exec > >(tee -a /workspace/setup.log) 2>&1
echo "====== STARTING SETUP ======"
date

# ====== ENVIRONMENT SETUP ======
export WORKSPACE_DIR=${WORKSPACE:-/workspace}
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# ====== INSTALL DEPENDENCIES ======
echo "Installing system dependencies..."
apt-get install -y python3 python3-pip python3-venv sudo netcat-openbsd

# ====== SERVICE CHECKS ======
check_port() {
    timeout=30
    while ! nc -z localhost $1; do
        sleep 1
        ((timeout--))
        if [ $timeout -eq 0 ]; then
            echo "Error: Service on port $1 failed to start"
            return 1
        fi
    done
}

# ====== MAIN SETUP ======
{
    echo "Updating components..."

    # Install VS Code Server
    echo "Installing VS Code..."
    curl -fsSL https://code-server.dev/install.sh | sh || { echo "VS Code install failed"; exit 1; }

    # Install Ollama
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh || { echo "Ollama install failed"; exit 1; }

    # Start Ollama
    echo "Starting Ollama..."
    nohup ollama serve > "$WORKSPACE_DIR/ollama.log" 2>&1 &
    check_port 11434

    # Start VS Code
    echo "Starting VS Code..."
    nohup code-server \
        --auth password \
        --port 8080 \
        --bind-addr 0.0.0.0 \
        --disable-telemetry \
        "$WORKSPACE_DIR" > "$WORKSPACE_DIR/vscode.log" 2>&1 &
    check_port 8080

    # Install LangFlow
    echo "Installing LangFlow..."
    python3 -m venv "$WORKSPACE_DIR/langflow-env"
    source "$WORKSPACE_DIR/langflow-env/bin/activate"
    pip install langflow[all] || { echo "LangFlow install failed"; exit 1; }

    # Start LangFlow
    echo "Starting LangFlow..."
    nohup langflow run \
        --host 0.0.0.0 \
        --port 3000 \
        --log-level debug > "$WORKSPACE_DIR/langflow.log" 2>&1 &
    check_port 3000

} || {
    echo "====== SETUP FAILED ======"
    exit 1
}

echo "====== SETUP COMPLETED ======"
echo "Access endpoints:"
echo "- VS Code:    http://localhost:8080"
echo "- LangFlow:   http://localhost:3000"
echo "- Ollama API: http://localhost:11434"