#!/bin/bash

service postgresql start
sudo -u pleroma /bin/bash /entrypoint.sh
