docker-compose logs web | grep '_read_file reading /var/lib/odoo/filestore/ppt-apps15' | awk '{print $11;}' | sed -E 's/(.*ppt-apps15\/)(.*)/\2/' | uniq 
