#!/bin/bash
#!/bin/bash

set -Eeuo pipefail

PROJECT_DIR="/opt/infrastructure-backup"
BACKUP_DIR="$PROJECT_DIR/backups"

echo "Starting local backup cleanup..."

# Remove backup archives older than 7 days
find "$BACKUP_DIR" -maxdepth 1 \
-type f -name 'application_backup_*.tar.gz' \
-mtime +7 -print -delete

# Remove corresponding checksum files
find "$BACKUP_DIR" -maxdepth 1 \
-type f -name 'application_backup_*.tar.gz.sha256' \
-mtime +7 -print -delete

echo "Local backup cleanup completed!"

