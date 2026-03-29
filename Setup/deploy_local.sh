#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

if [ "$EUID" -ne 0 ]; then
    echo "Warning: You may need root for symlinks. Try: sudo ./deploy_local.sh"
    echo ""
fi

if command -v python3 &> /dev/null; then
    python3 deploy_local.py "$@"
else
    python deploy_local.py "$@"
fi
