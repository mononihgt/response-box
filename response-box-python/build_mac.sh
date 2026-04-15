#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$ROOT"
APP_NAME="reaction-box-psychopy-mac"

# 1) Use existing project venv (.venv)
VENV="$ROOT/.venv"
if [ ! -d "$VENV" ]; then
  echo "[!] 未找到 $VENV，请先创建：python3 -m venv .venv && source .venv/bin/activate && pip install -r packaging_requirements.txt"
  exit 1
fi
source "$VENV/bin/activate"
# ensure venv binaries are first
export PATH="$VENV/bin:$PATH"
# Prefer official PyPI to avoid镜像 SSL问题，可通过环境变量覆盖
export PIP_INDEX_URL="${PIP_INDEX_URL:-https://pypi.org/simple}"

"$VENV/bin/python" -m pip install --upgrade pip
"$VENV/bin/python" -m pip install -r "$ROOT/packaging_requirements.txt"

# 2) Clean previous build
rm -rf "$ROOT/dist/$APP_NAME" "$ROOT/dist/$APP_NAME.app" "$ROOT/dist/$APP_NAME".zip "$ROOT/build"

# 3) Build (ONEDIR for better dependency loading with PsychoPy)
pyinstaller \
  --clean --noconfirm \
  --onedir --windowed \
  --name "$APP_NAME" \
  --paths "$PROJECT" \
  --collect-all psychopy \
  --collect-all pyglet \
  --collect-all pandas \
  --collect-all numpy \
  "$PROJECT/experiment_psychopy.py"

# 4) Zip the binary for sharing
cd "$ROOT/dist"
if [ -f "$APP_NAME" ]; then
  zip -r "$APP_NAME.zip" "$APP_NAME"
fi

echo "Mac build finished: $ROOT/dist/$APP_NAME (and .zip)"
