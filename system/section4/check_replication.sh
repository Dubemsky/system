#!/bin/bash
# Check replication lag
lag=$(psql -U postgres -c "SELECT pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS lag FROM pg_stat_replication;" | grep -v row | grep -v -- -- | grep -v lag)

# Alert if lag exceeds threshold (50MB)
if [ "$lag" -gt 50000000 ]; then
    echo "WARNING: Replication lag exceeds threshold: $lag bytes"
    # Send alert (email/SMS/etc.)
    echo "Replication lag alert: $lag bytes at $(date)" | mail -s "DB Replication Lag Alert" admin@example.com
fi