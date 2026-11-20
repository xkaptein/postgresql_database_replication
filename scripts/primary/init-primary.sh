
#!/bin/bash

set -euo pipefail

echo "Initializing PostgreSQL primary..."

# Validate environment variables.
: "${POSTGRES_REPLICATION_USER:?Replication username is required}"
: "${POSTGRES_REPLICATION_PASSWORD:?Replication password is required}"

# Create replication user.
psql \
  --username "$POSTGRES_USER" \
  --dbname "$POSTGRES_DB" \
  --set=ON_ERROR_STOP=1 \
  --set=replication_user="$POSTGRES_REPLICATION_USER" \
  --set=replication_password="$POSTGRES_REPLICATION_PASSWORD" \
  <<'SQL'

CREATE ROLE :"replication_user"
WITH REPLICATION
LOGIN
PASSWORD :'replication_password';

SQL

# Allow replication connections.
echo "host replication ${POSTGRES_REPLICATION_USER} 0.0.0.0/0 scram-sha-256" \
  >> "$PGDATA/pg_hba.conf"

echo "Primary initialization completed successfully."
