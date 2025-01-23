#!/bin/bash
set -e

# Configuration
WORKSPACE_DIR=${WORKSPACE:-/workspace}
LANGFLOW_PORT=3000
LANGFLOW_LOG="$WORKSPACE_DIR/langflow.log"

# Update components
echo "Updating pre-installed components..."
echo "Updating Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

echo "Updating code-server..."
curl -fsSL https://code-server.dev/install.sh | sh

# Setup LangFlow
echo "Setting up LangFlow..."
python3 -m venv "$WORKSPACE_DIR/langflow-env"
source "$WORKSPACE_DIR/langflow-env/bin/activate"

echo "Installing LangFlow..."
pip install langflow[all]

echo "Starting LangFlow..."
nohup langflow run \
    --host 0.0.0.0 \
    --port "$LANGFLOW_PORT" \
    --log-level debug \
    > "$LANGFLOW_LOG" 2>&1 &

# Verify services
echo "Verifying services..."
if ! curl -s http://localhost:11434 > /dev/null; then
    echo "Error: Ollama not running!"
    exit 1
fi

if ! curl -s http://localhost:8080 > /dev/null; then
    echo "Error: code-server not running!"
    exit 1
fi

timeout=30
while ! curl -s http://localhost:$LANGFLOW_PORT > /dev/null; do
    sleep 1
    ((timeout--))
    if [ $timeout -eq 0 ]; then
        echo "Error: LangFlow failed to start"
        exit 1
    fi
done

# Final setup
chmod -R 775 "$WORKSPACE_DIR"
echo "========================================"
echo "Setup completed successfully!"
echo "Access endpoints:"
echo "- VS Code:    http://localhost:8080"
echo "- LangFlow:   http://localhost:$LANGFLOW_PORT"
echo "- Ollama API: http://localhost:11434"
echo "========================================"