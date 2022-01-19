#!/bin/bash

set -e

export PATH=/odoo:$PATH

if [ -v PASSWORD_FILE ]; then
    PASSWORD="$(< $PASSWORD_FILE)"
fi

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" |cut -d " " -f3|sed 's/["\n\r]//g')
    fi;
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

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
            wait-for-psql.py ${DB_ARGS[@]} --timeout=30
            exec gosu odoo odoo-bin "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        wait-for-psql.py ${DB_ARGS[@]} --timeout=30
        exec gosu odoo odoo-bin "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1
