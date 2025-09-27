# borg-ssh-server
Simple Borg-compatible SSH server container for remote backups.

## Persistent Host Key
To prevent SSH host key regeneration on each container start, **mount `/etc/ssh` to a host path of your choosing**.

## Mount Point
To have a location for borg to write to, **mount `/mnt` to a host path**.

---

## Quick Start:
The following will spin up the container, using subdirectories in /srv/borg-ssh-server for storing data and use port 2000 for incoming clients with no public keys defined:

```bash
docker run -d \
  -p 2000:22 \
  -v /srv/borg-ssh-server/ssh:/etc/ssh \
  -v /srv/borg-ssh-server/data:/mnt \
  -e SSH_PUBLIC_KEYS="" \
  -e SSH_UID=2001 \
  -e SSH_GID=1001 \
  --name borg-ssh-server \
  ghcr.io/thedraca/borg-ssh-server:latest
```

---

## On the client:
Add the server with:
`ssh://containerusr@hostname.example.com:2000/mnt`