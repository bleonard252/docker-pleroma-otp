#!/bin/bash

chown -R pleroma /etc/pleroma
chmod -R 777 /etc/pleroma
chown -R pleroma /var/lib/pleroma
chmod -R 777 /var/lib/pleroma
chown -R postgres /var/lib/postgresql
chmod -R 700 /var/lib/postgresql
service postgresql start
sudo -u pleroma /bin/bash /entrypoint.sh
