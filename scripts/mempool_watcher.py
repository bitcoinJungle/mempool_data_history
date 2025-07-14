#!/usr/bin/env python3

import os
import re
import time
import json
import logging
import signal
from datetime import datetime
from google.cloud import pubsub_v1
from concurrent import futures as concurrent_futures

# --------------------------
# Configuration
# --------------------------
PROJECT_ID = os.environ.get("PROJECT_ID")
TOPIC_ID = os.environ.get("TOPIC_ID")
LOG_FILE = "/home/bitcoin/.bitcoin/debug.log"

if not PROJECT_ID or not TOPIC_ID:
    raise EnvironmentError("PROJECT_ID and TOPIC_ID environment variables must be set")

# --------------------------
# Logging setup
# --------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)

# --------------------------
# Regex pattern to match AcceptToMemoryPool log lines
# --------------------------
pattern = re.compile(
    r'^(?P<timestamp>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z).*?'
    r'peer=(?P<peer_num>\d+): accepted (?P<txhash>[a-f0-9]{64}).*?'
    r'poolsz (?P<pool_size_txns>\d+) txn, (?P<pool_size_kb>\d+) kB'
)

# --------------------------
# Pub/Sub setup with batching
# --------------------------
batch_settings = pubsub_v1.types.BatchSettings(
    max_messages=100,
    max_bytes=5_000_000,
    max_latency=120,
)
publisher = pubsub_v1.PublisherClient(batch_settings=batch_settings)
topic_path = publisher.topic_path(PROJECT_ID, TOPIC_ID)
publish_futures = []
should_shutdown = False

def callback(future: pubsub_v1.publisher.futures.Future) -> None:
    try:
        message_id = future.result()
        logging.debug(f"Published message ID: {message_id}")
    except Exception as e:
        logging.error(f"Publish failed: {e}")

def handle_shutdown(signum, frame):
    global should_shutdown
    should_shutdown = True
    logging.info(f"Received shutdown signal ({signum}).")

# Register signal handlers
signal.signal(signal.SIGINT, handle_shutdown)
signal.signal(signal.SIGTERM, handle_shutdown)

def main():
    logging.info(f"Starting with PROJECT_ID={PROJECT_ID}, TOPIC_ID={TOPIC_ID}")

    logging.info(f"Monitoring {LOG_FILE} and publishing to {topic_path}")
    with open(LOG_FILE, 'r') as f:
        f.seek(0, 2)  # Go to the end of file

        while not should_shutdown:
            line = f.readline()
            if not line:
                time.sleep(0.1)
                continue

            match = pattern.search(line)
            if match:
                data = match.groupdict()
                message = {
                    "event_type": "mempool_accept",
                    "host": "GCP-bitcoin-node",
                    "timestamp": data["timestamp"],
                    "txhash": data["txhash"],
                    "peer_num": int(data["peer_num"]),
                    "pool_size_txns": int(data["pool_size_txns"]),
                    "pool_size_kb": int(data["pool_size_kb"]),
                    "source": "bitcoinJungle",
                    "dt": datetime.utcnow().strftime("%Y-%m-%d"),
                }

                message_data = json.dumps(message).encode("utf-8")
                publish_future = publisher.publish(topic_path, message_data)
                publish_future.add_done_callback(callback)
                publish_futures.append(publish_future)

                logging.info(f"Queued message txhash={message['txhash']}")

            # Clean up completed futures periodically
            publish_futures[:] = [f for f in publish_futures if not f.done()]

    # On shutdown: flush remaining messages
    logging.info("Shutting down. Waiting for remaining publishes...")
    done, not_done = concurrent_futures.wait(publish_futures, return_when=concurrent_futures.ALL_COMPLETED)
    for future in done:
        try:
            message_id = future.result()
            logging.info(f"Flushed message ID: {message_id}")
        except Exception as e:
            logging.error(f"Error while flushing: {e}")
    logging.info("Shutdown complete.")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logging.exception(f"Unhandled exception: {e}")

