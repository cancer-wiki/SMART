#!/bin/bash
# Set up SMART on this machine:
#   1. copy the 20 agents and their reference files to ~/.claude/agents/
#   2. install the R packages
#   3. install the Python packages
#   4. install the command-line tools the pipeline calls (jq, pdftotext)
#
# Usage:
#   bash setup.sh                 # everything
#   bash setup.sh --agents-only   # only step 1 (e.g. after editing an agent)
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- 1. Agents ---
echo "[1/4] Installing agents to ~/.claude/agents/ ..."
mkdir -p ~/.claude/agents/Ref
cp "$SCRIPT_DIR"/agents/*.md ~/.claude/agents/
cp -r "$SCRIPT_DIR"/Ref/* ~/.claude/agents/Ref/
echo "      Installed $(ls "$SCRIPT_DIR"/agents/*.md | wc -l | tr -d ' ') agents."

if [ "${1:-}" = "--agents-only" ]; then
  echo "Done."
  exit 0
fi

# --- 2. R packages ---
echo "[2/4] Installing R packages (this can take a while the first time)..."
if command -v Rscript >/dev/null 2>&1; then
  Rscript "$SCRIPT_DIR/install_R_packages.R"
else
  echo "      ERROR: Rscript not found. Install R (https://cran.r-project.org) and re-run."
  exit 1
fi

# --- 3. Python packages ---
echo "[3/4] Installing Python packages..."
if command -v python3 >/dev/null 2>&1; then
  python3 -m pip install -r "$SCRIPT_DIR/requirements.txt"
else
  echo "      ERROR: python3 not found. Install Python 3 and re-run."
  exit 1
fi

# --- 4. Command-line tools (jq, pdftotext) ---
echo "[4/4] Installing command-line tools..."
install_tool() {   # $1 = command, $2 = Homebrew package, $3 = apt package
  if command -v "$1" >/dev/null 2>&1; then
    echo "      ok       $1"
  elif command -v brew >/dev/null 2>&1; then
    brew install "$2"
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install -y "$3"
  else
    echo "      MISSING  $1  (install the '$2' package with your system's package manager)"
  fi
}
install_tool jq        jq      jq
install_tool pdftotext poppler poppler-utils

missing=0
for tool in claude jq pdftotext; do
  command -v "$tool" >/dev/null 2>&1 || { echo "      MISSING  $tool"; missing=1; }
done
command -v claude >/dev/null 2>&1 || echo "      Install the Claude Code CLI: https://docs.anthropic.com/en/docs/claude-code"
command -v paperclip >/dev/null 2>&1 || echo "      Note: paperclip not found (optional, only used when definitions cite external papers)"

echo ""
if [ "$missing" = 0 ]; then
  echo "Setup complete."
else
  echo "Setup finished, but some tools above are missing."
fi
