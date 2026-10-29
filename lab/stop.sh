#!/bin/bash
# Stop and remove GitLab lab containers.
# Usage: ./stop.sh [VERSION]
set -e
if [ -n "$1" ]; then
    NAME="gl-${1//./-}"
    echo "[*] Stopping ${NAME}"
    docker rm -f "${NAME}" 2>/dev/null || true
else
    echo "[*] Stopping all gl-* containers"
    docker ps -a --filter "name=gl-" --format "{{.Names}}" | while read name; do
        echo "    removing ${name}"
        docker rm -f "${name}" 2>/dev/null || true
    done
fi
echo "[+] Done"
