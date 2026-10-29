#!/bin/bash
# Launch a vulnerable GitLab CE instance for CVE testing.
# Usage: ./run.sh 19.4.1 [port]
set -e

VERSION="${1:?Usage: $0 VERSION [PORT]}"
PORT="${2:-8080}"
NAME="gl-${VERSION//./-}"
IMAGE="gitlab/gitlab-ce:${VERSION}-ce.0"

echo "[*] Starting GitLab CE ${VERSION} on port ${PORT} (container: ${NAME})"
echo "[*] First boot takes 5-15 minutes..."

docker run -d \
    --name "${NAME}" \
    --hostname "${NAME}" \
    --memory 6.5g \
    --shm-size 256m \
    -p "${PORT}:80" \
    -e GITLAB_ROOT_PASSWORD="Lab_Root_Passw0rd!" \
    -e GITLAB_OMNIBUS_CONFIG="
        puma['worker_processes'] = 1;
        sidekiq['max_concurrency'] = 0;
        prometheus_monitoring['enable'] = false;
        postgresql['shared_buffers'] = '128MB';
        postgresql['max_worker_processes'] = 2;
    " \
    "${IMAGE}"

echo "[*] Waiting for GitLab to become ready..."
for i in $(seq 1 120); do
    if curl -sf "http://127.0.0.1:${PORT}/users/sign_in" > /dev/null 2>&1; then
        echo "[+] GitLab CE ${VERSION} ready at http://127.0.0.1:${PORT}"
        echo "    Container: ${NAME}"
        echo "    Password:  Lab_Root_Passw0rd!"
        exit 0
    fi
    printf "\r    waiting... %d/120" "$i"
    sleep 5
done
echo "[-] Timeout waiting for GitLab"
exit 1
