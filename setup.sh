#! /bin/bash
set -e
# ====== CONFIGURATION ======
WORKSPACE_DIR=${WORKSPACE:-/workspace}
LANGFLOW_PORT=3000
LANGFLOW_LOG="$WORKSPACE_DIR/langflow.log"

# ====== UPDATE EXISTING TOOLS ======
echo "Updating pre-installed components..."
# Update Ollama to latest version
echo "Updating Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# Update code-server (VS Code)
echo "Updating code-server..."
curl -fsSL https://code-server.dev/install.sh | sh

# ====== SETUP LANGFLOW ======
echo "Setting up LangFlow..."
# Create Python virtual environment
python3 -m venv "$WORKSPACE_DIR/langflow-env"
source "$WORKSPACE_DIR/langflow-env/bin/activate"

# Install LangFlow with GPU support
echo "Installing LangFlow..."
pip install langflow[all]

# Configure LangFlow to use existing Ollama
echo "Starting LangFlow..."
nohup langflow run \
    --host 0.0.0.0 \
    --port "$LANGFLOW_PORT" \
    --log-level debug \
    > "$LANGFLOW_LOG" 2>&1 &

# ====== VERIFY SERVICES ======
echo "Verifying services..."
# Check Ollama
if ! curl -s http://localhost:11434 > /dev/null; then
    echo "Error: Ollama not running!"
    exit 1
fi

# Check code-server
if ! curl -s http://localhost:8080 > /dev/null; then
    echo "Error: code-server not running!"
    exit 1
fi

# Check LangFlow
timeout=30
while ! curl -s http://localhost:$LANGFLOW_PORT > /dev/null; do
    sleep 1
    ((timeout--))
    if [ $timeout -eq 0 ]; then
        echo "Error: LangFlow failed to start"
        exit 1
    fi
done

# ====== FINAL SETUP ======
echo "Finalizing configuration..."
chmod -R 775 "$WORKSPACE_DIR"
echo "========================================"
echo "Setup completed successfully!"
echo "Access endpoints:"
echo "- VS Code:    http://localhost:8080"
echo "- LangFlow:   http://localhost:$LANGFLOW_PORT"
echo "- Ollama API: http://localhost:11434"
echo "========================================"