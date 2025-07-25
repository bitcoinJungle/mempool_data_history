#!/bin/bash

# ----------------------------------------
# Update system and install dependencies
# ----------------------------------------
apt-get update && apt-get upgrade -y
apt-get install -y build-essential cmake pkgconf python3 python3-pip python3-venv \
                   libevent-dev libboost-dev libzmq3-dev git

# ----------------------------------------
# Create bitcoin user and directories
# ----------------------------------------
useradd -r -m -s /usr/sbin/nologin bitcoin
mkdir -p /home/bitcoin/project
chown -R bitcoin:bitcoin /home/bitcoin

# ----------------------------------------
# Build and install Bitcoin Core
# ----------------------------------------
cd /opt
git clone https://github.com/bitcoin/bitcoin.git
cd bitcoin
git checkout v29.0
cmake -B build -DENABLE_WALLET=OFF -DWITH_ZMQ=OFF
cmake --build build -j$(nproc)
ctest --test-dir build
chown -R bitcoin:bitcoin /opt/bitcoin

# ----------------------------------------
# Write bitcoin.conf
# ----------------------------------------
sudo -u bitcoin mkdir -p /home/bitcoin/.bitcoin
cat <<EOF > /home/bitcoin/.bitcoin/bitcoin.conf
server=1
prune=3000
dbcache=8192
debug=mempool
#debug=mempoolrej => TODO: Retrieve the mempoolrej logs
logthreadnames=1
logtimemicros=1
EOF
chown -R bitcoin:bitcoin /home/bitcoin/.bitcoin

# ----------------------------------------
# Create systemd service for bitcoind
# ----------------------------------------
cat <<EOF > /etc/systemd/system/bitcoind.service
[Unit]
Description=Bitcoin daemon
After=network.target

[Service]
Type=simple
User=bitcoin
ExecStart=/opt/bitcoin/build/bin/bitcoind -conf=/home/bitcoin/.bitcoin/bitcoin.conf -datadir=/home/bitcoin/.bitcoin
ExecStop=/opt/bitcoin/build/bin/bitcoin-cli -conf=/home/bitcoin/.bitcoin/bitcoin.conf -datadir=/home/bitcoin/.bitcoin stop
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ----------------------------------------
# Create Python virtual environment
# ----------------------------------------
sudo -u bitcoin python3 -m venv /home/bitcoin/project/venv
sudo -u bitcoin /home/bitcoin/project/venv/bin/python -m pip install --quiet --upgrade pip
sudo -u bitcoin /home/bitcoin/project/venv/bin/python -m pip install --quiet google-cloud-pubsub
# Require only for Option 2 : 
sudo -u bitcoin /home/bitcoin/project/venv/bin/python -m pip install --quiet fastavro google-cloud-storage

# ----------------------------------------------------------
# Option 1 : Send messages straight to Bigquery using pubsub
# ----------------------------------------------------------

# ----------------------------------------
# Download mempool_watcher.py from GCS
# ----------------------------------------
gsutil cp gs://${BUCKET_NAME}/scripts/mempool_watcher.py /home/bitcoin/project/mempool_watcher.py
chown bitcoin:bitcoin /home/bitcoin/project/mempool_watcher.py
chmod +x /home/bitcoin/project/mempool_watcher.py

# ------------------------------------------
# Create systemd service for mempool watcher
# ------------------------------------------
cat <<EOF > /etc/systemd/system/mempool-watcher.service
[Unit]
Description=Bitcoin mempool watcher (via venv)
After=network.target bitcoind.service
Requires=bitcoind.service

[Service]
Type=simple
User=bitcoin
Environment=PROJECT_ID=${PROJECT_ID}
Environment=TOPIC_ID=${TOPIC_ID}
WorkingDirectory=/home/bitcoin/project
ExecStart=/home/bitcoin/project/venv/bin/python mempool_watcher.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ---------------------------------------------
# Send messages as avrofiles to GCS
# ---------------------------------------------

# --------------------------------------------
# Download mempool-to-avro-watcher.py from GCS
# --------------------------------------------
gsutil cp gs://${BUCKET_NAME}/scripts/mempool_to_avrofiles_watcher.py /home/bitcoin/project/mempool_to_avrofiles_watcher.py
chown bitcoin:bitcoin /home/bitcoin/project/mempool_to_avrofiles_watcher.py
chmod +x /home/bitcoin/project/mempool_to_avrofiles_watcher.py

# -------------------------------------------------------
# Create systemd service for mempool to avrofiles watcher
# -------------------------------------------------------
cat <<EOF > /etc/systemd/system/mempool-to-avro-watcher.service
[Unit]
Description=Bitcoin mempool watcher sending avrofiles to GCP (via venv)
After=network.target bitcoind.service
Requires=bitcoind.service

[Service]
Type=simple
User=bitcoin
Environment=PROJECT_ID=${PROJECT_ID}
Environment=BUCKET_NAME=${BUCKET_NAME_DESTINATION}
Environment=HOSTNAME=${HOSTNAME}
WorkingDirectory=/home/bitcoin/project
ExecStart=/home/bitcoin/project/venv/bin/python mempool_to_avrofiles_watcher.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ----------------------------------------
# Enable and start both services
# ----------------------------------------
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable bitcoind
systemctl start bitcoind
systemctl enable mempool-to-avro-watcher
systemctl start mempool-to-avro-watcher

# ----------------------------------------------
# Option 1 : Send messages straight to Bigquery
# ----------------------------------------------
systemctl enable mempool-watcher
systemctl start mempool-watcher
