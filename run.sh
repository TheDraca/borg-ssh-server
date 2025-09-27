#!/bin/bash

echo "[INIT] Starting SSH container..."
set -e

SSH_USER="containerusr"
SSH_UID=${SSH_UID:-1001}
SSH_GID=${SSH_GID:-1001}
USER_HOME="/home/$SSH_USER"
SSHD_CONFIG="/etc/ssh/sshd_config"


# Generate a random password if none is provided
if [ -z "$SSH_PASS" ]; then
    echo "[INIT] No SSH_PASS provided — generating a random password"
    SSH_PASS=$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 16)
    echo "[INFO] Generated SSH password for $SSH_USER: $SSH_PASS"
fi


# Create group if GID doesn't exist
if ! getent group "$SSH_GID" >/dev/null; then
    echo "[INIT] Creating group '$SSH_USER' with GID $SSH_GID"
    addgroup -g "$SSH_GID" "$SSH_USER"
else
    # Get existing group name with that GID
    EXISTING_GROUP=$(getent group "$SSH_GID" | cut -d: -f1)
    echo "[INFO] Reusing existing group '$EXISTING_GROUP' with GID $SSH_GID"
    SSH_USER_GROUP="$EXISTING_GROUP"
fi

# If the USER group already existed then use it, otherwise use the username
USER_GROUP="${SSH_USER_GROUP:-$SSH_USER}"

# Create the user if it doesn't exist
if ! id "$SSH_USER" >/dev/null 2>&1; then
    echo "[INIT] Creating user '$SSH_USER'"
    adduser -D -u "$SSH_UID" -G "$USER_GROUP" -h "$USER_HOME" "$SSH_USER"
    echo "$SSH_USER:$SSH_PASS" | chpasswd
fi

# Create .ssh directory
mkdir -p "$USER_HOME/.ssh"
chown "$SSH_USER:$USER_GROUP" "$USER_HOME/.ssh"
chmod 700 "$USER_HOME/.ssh"

# Handle multiple public keys
if [ -n "$SSH_PUBLIC_KEYS" ]; then
    echo "[INIT] Public keys provided – enabling key-based only authentication"
    
    # Split by newline or comma
    echo "$SSH_PUBLIC_KEYS" | tr ',' '\n' > "$USER_HOME/.ssh/authorized_keys"
    
    chown "$SSH_USER:$USER_GROUP" "$USER_HOME/.ssh/authorized_keys"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"

    echo "[INFO] Authorized SSH keys:"
    cat "$USER_HOME/.ssh/authorized_keys"
fi

# Only configure SSHD if it hasn't been set up before
if [ ! -f "$SSHD_CONFIG" ] || ! grep -q "# CONFIGURED_BY_ENTRYPOINT" "$SSHD_CONFIG"; then
    echo "[INIT] Generating SSHD config..."
    
    cat > "$SSHD_CONFIG" <<EOF
# CONFIGURED_BY_ENTRYPOINT
Port 22
ListenAddress 0.0.0.0
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Authentication
$( [ -n "$SSH_PUBLIC_KEYS" ] && echo "PasswordAuthentication no" || echo "PasswordAuthentication yes" )
PubkeyAuthentication yes
PermitRootLogin no

# Security hardening
MaxAuthTries 3
MaxSessions 2
AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
TCPKeepAlive no
Compression no
UseDNS no
EOF
else
    echo "[INIT] Reusing existing sshd_config"
fi

# Generate SSH host keys if they don't already exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "[INIT] Generating SSH host keys..."
    ssh-keygen -A
else
    echo "[INFO] SSH host keys already exist – skipping generation"
fi

#Give user access to /mnt
chown "$SSH_USER:$USER_GROUP" "/mnt"
chmod 775 "/mnt"

# Start SSH server
echo "[INFO] Starting SSH server..."
exec /usr/sbin/sshd -D