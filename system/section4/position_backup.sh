#!/bin/bash
BACKUP_DIR="/backup/logical_backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Backup positions table
pg_dump -U postgres -d stockbroker_db -t positions > $BACKUP_DIR/positions_$TIMESTAMP.sql

# Remove backups older than 30 days
find $BACKUP_DIR -name "positions_*.sql" -mtime +30 -delete

# Log completion
echo "Positions table backup completed at $(date)" >> /var/log/postgresql/backup.log