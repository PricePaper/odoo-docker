#!/bin/bash

set -e

export PATH=/odoo:$PATH

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo-bin process if not present in the config file
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if ! grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        DB_ARGS+=("--${param}")
        DB_ARGS+=("${value}")
   fi;
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

# Added for redis session database
#check_config "session_store_prefix" "$REDIS_SESSION_STORE_PREFIX"
#check_config "session_store_host" "$REDIS_SESSION_STORE_HOST"
#check_config "session_store_port" "REDIS_SESSION_STORE_PORT"
#check_config "session_store_dbindex" "REDIS_SESSION_STORE_DBINDEX"
#check_config "session_store_pass" "REDIS_SESSION_STORE_PASS"

# Make sure /var/lib/odoo is owned by Odoo user
# simply chown'ing the directory doesn't scale well
# so we don't want to do it unless its needed
ODOO_DIR_OWNER=$(stat -c '%U' /var/lib/odoo)
if [ $ODOO_DIR_OWNER != "odoo" ]; then
  chown -R odoo:odoo /var/lib/odoo
fi

case "$1" in
    -- | odoo-bin)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec gosu odoo odoo-bin "$@"
        else
            exec gosu odoo odoo-bin "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        exec gosu odoo odoo-bin "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1
