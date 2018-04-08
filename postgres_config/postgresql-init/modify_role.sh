#!/bin/bash

/opt/rh/rh-postgresql96/root/bin/psql <<EOF
ALTER ROLE odoo WITH CREATEDB;
EOF
