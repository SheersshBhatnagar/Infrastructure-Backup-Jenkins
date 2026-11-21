
#!/bin/bash

set -Eeuo pipefail

# Project configuration
PROJECT_DIR="/opt/infrastructure-backup"
BACKUP_DIR="$PROJECT_DIR/backups"
RESTORE_DIR="$PROJECT_DIR/restore"

# AWS configuration
S3_BUCKET="sheerssh-infrastructure-backup-2026"

echo "================================"
echo "Starting Disaster Recovery"
echo "================================"

# Check if backup filename was provided
if [ $# -ne 1 ]; then
    echo "Usage: ./scripts/restore.sh BACKUP_FILENAME"
    exit 1
fi

BACKUP_FILE="$1"

# Prevent path traversal
if [[ "$BACKUP_FILE" == */* || "$BACKUP_FILE" == *".."* ]]; then
    echo "ERROR: Invalid backup filename"
    exit 1
fi

if [[ "$BACKUP_FILE" != application_backup_*.tar.gz ]]; then
    echo "ERROR: Invalid backup file format"
    exit 1
fi

mkdir -p "$BACKUP_DIR" "$RESTORE_DIR"

echo "Downloading backup from S3..."

# Download backup archive
aws s3 cp \
"s3://$S3_BUCKET/backups/$BACKUP_FILE" \
"$BACKUP_DIR/$BACKUP_FILE"

# Download checksum
aws s3 cp \
"s3://$S3_BUCKET/backups/$BACKUP_FILE.sha256" \
"$BACKUP_DIR/$BACKUP_FILE.sha256"

echo "Verifying backup integrity..."

# Verify checksum
(
    cd "$BACKUP_DIR"
    sha256sum -c "$BACKUP_FILE.sha256"
)

echo "Extracting backup..."

# Extract into a separate recovery directory
tar -xzf "$BACKUP_DIR/$BACKUP_FILE" \
-C "$RESTORE_DIR"

echo "================================"
echo "RECOVERY COMPLETED SUCCESSFULLY"
echo "Restored files are located at:"
echo "$RESTORE_DIR/application"
echo "================================"

