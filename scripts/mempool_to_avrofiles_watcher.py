#!/usr/bin/env python3

import os
import re
import time
import logging
import signal
from datetime import datetime, timezone
from fastavro import writer, parse_schema
from google.cloud import storage

# --------------------------
# Configuration
# --------------------------
BUCKET_NAME = os.environ.get("BUCKET_NAME")
HOSTNAME = os.environ.get("HOSTNAME")
SOURCE = os.environ.get("SOURCE", "bitcoinJungle")
LOG_FILE = "/home/bitcoin/.bitcoin/debug.log"

if not BUCKET_NAME:
    raise EnvironmentError("BUCKET_NAME environment variable must be set")

# --------------------------
# Avro schema
# --------------------------
mempool_event_type_enum = {
    "type": "enum",
    "name": "event_type",
    "symbols": ["mempool_accept"],
}

mempool_activity_avro_schema = parse_schema({
    "doc": "Bitcoind mempool activity",
    "name": "Mempool",
    "type": "record",
    "fields": [
        {"name": "event_type", "type": mempool_event_type_enum},
        {"name": "host", "type": "string"},
        {"name": "timestamp", "type": {"type": "long", "logicalType": "timestamp-micros"}},
        {"name": "txhash", "type": "string"},
        {"name": "peer_num", "type": ["null", "int"]},
        {"name": "pool_size_txns", "type": ["null", "int"]},
        {"name": "pool_size_kb", "type": ["null", "int"]},
        {"name": "replace_txhash", "type": ["null", "string"]},
    ],
})

# --------------------------
# Regex pattern
# --------------------------
pattern = re.compile(
    r'^(?P<timestamp>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z).*?'
    r'peer=(?P<peer_num>\d+): accepted (?P<txhash>[a-f0-9]{64}).*?'
    r'poolsz (?P<pool_size_txns>\d+) txn, (?P<pool_size_kb>\d+) kB'
)

replacement_info_pattern = re.compile(
    r'replacing mempool tx (?P<old_tx>[A-Fa-f0-9]{64}).*?New tx (?P<new_tx>[A-Fa-f0-9]{64})'
)

# --------------------------
# Logging setup
# --------------------------
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

# --------------------------
# GCS setup
# --------------------------
storage_client = storage.Client()
bucket = storage_client.bucket(BUCKET_NAME)

# --------------------------
# Shutdown handling
# --------------------------
should_shutdown = False

def shutdown(signum=None, frame=None):
    global should_shutdown
    should_shutdown = True
    logging.info("Received shutdown signal.")

signal.signal(signal.SIGINT, shutdown)
signal.signal(signal.SIGTERM, shutdown)

# --------------------------
# Avro writing
# --------------------------
def flush_to_gcs(records):
    if not records:
        return

    now = datetime.now(timezone.utc)
    dt_str = now.strftime("%Y-%m-%d")
    timestamp_str = now.strftime("%Y-%m-%dT%H-%M-%S")
    filename = f"{HOSTNAME}.{timestamp_str}.avro"
    gcs_path = f"source={SOURCE}/dt={dt_str}/{filename}"
    local_path = f"/tmp/{filename}"

    with open(local_path, "wb") as out:
        writer(out, mempool_activity_avro_schema, records)

    blob = bucket.blob(gcs_path)
    blob.upload_from_filename(local_path)
    os.remove(local_path)
    logging.info(f"Uploaded {gcs_path} with {len(records)} records")

# --------------------------
# Main logic
# --------------------------
def main():
    current_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    logging.info(f"Watching {LOG_FILE}, writing Avro to bucket '{BUCKET_NAME}' under source={HOSTNAME}/dt={current_date}/")
    buffer = []
    flush_interval = 3600  # seconds
    last_flush = time.time()
    
    recent_replacements = {}  # new_txhash => old_txhash

    with open(LOG_FILE, 'r') as f:
        f.seek(0, 2)  # Seek to end

        while not should_shutdown:
            line = f.readline()
            if not line:
                time.sleep(0.1)
                continue
            
            # Match replacement info first
            replacement_info = replacement_info_pattern.search(line)
            if replacement_info:
                old_tx = replacement_info.group("old_tx")
                new_tx = replacement_info.group("new_tx")
                recent_replacements[new_tx] = old_tx
                continue

            # Match accept to mempool log
            match = pattern.search(line)
            if match:
                data = match.groupdict()
                dt_obj = datetime.strptime(data["timestamp"], "%Y-%m-%dT%H:%M:%S.%fZ").replace(tzinfo=timezone.utc)
                
                txid = data["txhash"]
                replace_txhash = recent_replacements.pop(txid, None)
                
                record = {
                    "event_type": "mempool_accept",
                    "host": HOSTNAME,
                    "timestamp": int(dt_obj.timestamp() * 1_000_000),
                    "txhash": txid,
                    "peer_num": int(data["peer_num"]),
                    "pool_size_txns": int(data["pool_size_txns"]),
                    "pool_size_kb": int(data["pool_size_kb"]),
                    "replace_txhash": replace_txhash,
                }
                buffer.append(record)

            if time.time() - last_flush > flush_interval:
                flush_to_gcs(buffer)
                buffer.clear()
                last_flush = time.time()

    flush_to_gcs(buffer)
    logging.info("Shutdown complete.")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logging.exception(f"Unhandled exception: {e}")