#! /bin/sh
WORKSPACE_DIR=${WORKSPACE:-/workspace}
LANGFLOW_PORT=3000
LANGFLOW_LOG="$WORKSPACE_DIR/langflow.log"

# Update Ollama
which curl || (apt-get update && apt-get install -y curl)
curl -fsSL https://ollama.com/install.sh | sh

# Update code-server
curl -fsSL https://code-server.dev/install.sh | sh

# Setup LangFlow
python3 -m venv "$WORKSPACE_DIR/langflow-env"
. "$WORKSPACE_DIR/langflow-env/bin/activate"

pip install langflow[all]

langflow run --host 0.0.0.0 --port "$LANGFLOW_PORT" --log-level debug > "$LANGFLOW_LOG" 2>&1 &

# Wait for services
sleep 10
chmod -R 775 "$WORKSPACE_DIR"

echo "Setup complete! Access:"
echo "VS Code: http://localhost:8080"
echo "LangFlow: http://localhost:$LANGFLOW_PORT"
echo "Ollama API: http://localhost:11434"