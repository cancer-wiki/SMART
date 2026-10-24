#!/bin/bash
# Install TransferAgent: copy agent definitions to ~/.claude/agents/
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing TransferAgent agents..."

# Create target directories
mkdir -p ~/.claude/agents/Ref

# Copy agent definitions
cp "$SCRIPT_DIR"/agents/*.md ~/.claude/agents/

# Copy reference subdirectories
if [ -d "$SCRIPT_DIR/Ref" ]; then
  cp -r "$SCRIPT_DIR"/Ref/* ~/.claude/agents/Ref/
fi

echo "Installed $(ls "$SCRIPT_DIR"/agents/*.md | wc -l) agents to ~/.claude/agents/"
echo "Done."
