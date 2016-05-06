#!/bin/bash

set -ex
BASE='https://raw.githubusercontent.com/backer-and/FFiller/master'
TEMP=$(mktemp -d)

cd "$TEMP"
wget -q "$BASE/ffiller.sh"

sudo mkdir /opt/ffiller/
sudo mv ffiller.sh /opt/ffiller/
sudo chmod +x /opt/ffiller/ffiller.sh
sudo ln -s /opt/ffiller/ffiller.sh /usr/local/bin/ffiller

rm -r "$TEMP"
echo 'Done.'
