#!/bin/bash

ODOO_VERSION=15.0

# remove old copy
sudo rm -rf sources/{odoo-cloud-platform,odoo,enterprise} 2> /dev/null

# Get current directory and make temp directory
CWD=${PWD}
TMPDIR=$(mktemp -d)

# download new sources
cd ${TMPDIR}
git clone --depth=1 -b ${ODOO_VERSION} git@github.com:camptocamp/odoo-cloud-platform.git
git clone --depth=1 -b ${ODOO_VERSION} git@github.com:odoo/odoo.git
git clone --depth=1 -b ${ODOO_VERSION} git@github.com:odoo/enterprise.git

# remove git data
rm -rf {odoo,enterprise,odoo-cloud-platform}/{.git,.github}

# relocate to original directory
mv ${TMPDIR}/* ${CWD}/sources/
mv -f ${CWD}/sources/odoo-cloud-platform/* ${CWD}/sources/addons
rm -rf ${CWD}/sources/odoo-cloud-platform
cd ${CWD}
