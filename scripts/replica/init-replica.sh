
#!/bin/bash

set -e

PGDATA="${PGDATA:-/var/lib/postgresql/18/docker}"

PRIMARY_HOST="${POSTGRES_PRIMARY_HOST:-postgres-primary}"
PRIMARY_PORT="${POSTGRES_PRIMARY_PORT:-5432}"

REPLICATION_USER="${POSTGRES_REPLICATION_USER}"
REPLICATION_PASSWORD="${POSTGRES_REPLICATION_PASSWORD}"

REPLICATION_SLOT="postgres_replica_slot"

echo "Initializing PostgreSQL replica..."

# Ensure the PostgreSQL directory exists.
mkdir -p "$PGDATA"

# The custom entrypoint runs as root.
chown -R postgres:postgres /var/lib/postgresql

# If the replica has already been initialized, reuse it.
if [ -s "$PGDATA/PG_VERSION" ]; then
  echo "Existing replica data found. Skipping base backup."
else
  echo "Waiting for primary database..."

  until pg_isready -h "$PRIMARY_HOST" -p "$PRIMARY_PORT"; do
    sleep 3
  done

  echo "Creating replica from primary..."

  # Bootstrap the standby from the primary.
  gosu postgres env PGPASSWORD="$REPLICATION_PASSWORD" \
    pg_basebackup \
      -h "$PRIMARY_HOST" \
      -p "$PRIMARY_PORT" \
      -U "$REPLICATION_USER" \
      -D "$PGDATA" \
      -Fp \
      -Xs \
      -P \
      -R \
      -C \
      -S "$REPLICATION_SLOT" \
      -d "host=$PRIMARY_HOST port=$PRIMARY_PORT user=$REPLICATION_USER password=$REPLICATION_PASSWORD application_name=postgres-replica"
fi

echo "Starting PostgreSQL replica..."

exec /usr/local/bin/docker-entrypoint.sh postgres
