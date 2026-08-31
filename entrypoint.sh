#!/bin/sh
set -e

USER_DATA_DIR="${CUSTOM_USER_DATA_DIR:-/usr/src/wpp-server/userDataDir}"

echo "Cleaning stale Chromium lock files from ${USER_DATA_DIR}..."

if [ -d "$USER_DATA_DIR" ]; then
    find "$USER_DATA_DIR" -name "Singleton*" -print -exec rm -rf {} +
fi

echo "🚀 Starting WPPConnect..."

node dist/server.js &

SERVER_PID=$!

echo "⏳ Waiting for WPPConnect API..."

until node -e "
fetch('http://localhost:21465/api-docs')
    .then(r => process.exit(r.ok ? 0 : 1))
    .catch(() => process.exit(1))
"; do
    sleep 1
done

echo "📡 Sending wakeup webhook..."

echo "WPP_WAKEUP=${WPP_WAKEUP}"

node -e "
fetch('${WPP_WAKEUP}', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json'
    }
})
.then(async r => {
    console.log('Wakeup response:', r.status, await r.text());
    if (!r.ok) process.exit(1);
})
.catch(err => {
    console.error('Erro ao enviar wakeup:', err);
    process.exit(1);
});
"

echo "✅ Wakeup sent!"

wait $SERVER_PID