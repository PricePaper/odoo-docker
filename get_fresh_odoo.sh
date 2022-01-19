#!/bin/bash

ODOO_VERSION=15.0

# remove old copy
sudo rm -rf odoo enterprise 2> /dev/null

# download new sources
git clone --depth=1 -b ${ODOO_VERSION} git@github.com:odoo/odoo.git
git clone --depth=1 -b ${ODOO_VERSION} git@github.com:odoo/enterprise.git

# remove git data
rm -rf {odoo,enterprise}/{.git,.github}

# fix file ownership
sudo chown -R 23789:23789 odoo enterprise
