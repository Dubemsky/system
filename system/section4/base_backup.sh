#!/bin/bash
BACKUP_DIR="/backup/base_backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Create a base backup
pg_basebackup -D $BACKUP_DIR/base_$TIMESTAMP -Ft -z -P -U postgres

# Remove backups older than 14 days
find $BACKUP_DIR -type d -name "base_*" -mtime +14 -exec rm -rf {} \;

# Log completion
echo "Base backup completed at $(date)" >> /var/log/postgresql/backup.log