#!/bin/bash

# This is where ./bin/pleroma_ctl is
cd /opt/pleroma

if [ "$1" = "/bin/bash" ]; then
	/bin/bash
	return
fi

#/etc/init.d/postgresql restart

INST="$(cat /etc/pleroma/installed.txt)"
if [ $? -eq 1 ]; then
	INST=0
fi
if [ $INST -eq 0 ]; then #not set up
	./bin/pleroma_ctl instance gen --output /etc/pleroma/config.exs --output-psql /tmp/setup_db.psql
	sudo -u postgres psql -f /tmp/setup_db.psql
	./bin/pleroma_ctl migrate 
	./bin/pleroma daemon >/dev/null 2>/dev/null
	echo "Waiting 20 seconds to confirm successful server start..."
	sleep 20 && curl http://localhost:4000/api/v1/instance
	if [ $? -ne 0 ]; then
		while true; do
			echo "Retrying in 10 seconds..."
			sleep 10 && curl http://localhost:4000/api/v1/instance
			if [ $? -eq 0 ]; then
				break
			fi
		done
	fi
	./bin/pleroma_ctl config migrate_to_db

	# Admin User
	echo ""
	echo "=== Create Admin User ==="
	echo "This user will have access to the Pleroma Admin FE"
	echo "and have an admin badge."
	echo "This is probably also YOUR user!"
	echo "You'll get a link to paste in your browser"
	echo "so that once you restart the Pleroma container,"
	echo "you can set your password."
	echo "=== Create Admin User ==="
	read -p "Username: " UNM
	read -p "Email Address: " EML
	echo "=== Create Admin User ==="
	./bin/pleroma_ctl user new "$UNM" "$EML" --admin
	echo "=== Installation Done ==="
	echo "You should be ready to go!"
	echo "Restart the container and paste the above link"
	echo "into your browser. Make sure it points to where"
	echo "Pleroma is hosted (which should already match"
	echo "up with the link)!"
	echo "For documentation purposes, you'll always use"
	echo "the pleroma_ctl (or OTP) option if need be."
	echo "Have fun on your new Pleroma instance!"
	echo ""
	./bin/pleroma version > /etc/pleroma/installed.txt
	./bin/pleroma stop
	#shutdown now
else #run pleroma
	./bin/pleroma start_iex
fi
