#!/bin/bash
#!/bin/bash

set -Eeuo pipefail

# Project configuration
PROJECT_DIR="/opt/infrastructure-backup"
SOURCE_DIR="$PROJECT_DIR/data/application"
BACKUP_DIR="$PROJECT_DIR/backups"

# AWS configuration
S3_BUCKET="sheerssh-infrastructure-backup-2026"

# Generate timestamp
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

BACKUP_FILE="application_backup_${TIMESTAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "================================"
echo "Starting Infrastructure Backup"
echo "================================"

# Check source directory
if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: Source directory not found!"
    exit 1
fi

# Check AWS authentication
aws sts get-caller-identity > /dev/null

# Create compressed backup
tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
    -C "$(dirname "$SOURCE_DIR")" \
    "$(basename "$SOURCE_DIR")"

# Generate checksum
sha256sum "$BACKUP_DIR/$BACKUP_FILE" \
    > "$BACKUP_DIR/$BACKUP_FILE.sha256"

echo "Local backup created successfully!"

# Upload backup to S3
echo "Uploading backup to Amazon S3..."

aws s3 cp "$BACKUP_DIR/$BACKUP_FILE" \
    "s3://$S3_BUCKET/backups/$BACKUP_FILE" \
    --sse AES256

aws s3 cp "$BACKUP_DIR/$BACKUP_FILE.sha256" \
    "s3://$S3_BUCKET/backups/$BACKUP_FILE.sha256" \
    --sse AES256

echo "Backup uploaded successfully!"

echo "================================"
echo "BACKUP COMPLETED SUCCESSFULLY"
echo "================================"

