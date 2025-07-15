-- Deduplication of the tx

MERGE ${project_id}.${dataset_id}.${bloclevel_table} AS target
USING (
    SELECT txhash AS txid,
           MIN(`timestamp`) AS first_seen_timestamp,
           MAX(`timestamp`) AS last_seen_timestamp,
           CURRENT_TIMESTAMP() AS deduplicated_at,
           CURRENT_TIMESTAMP() AS modified_at,
           CURRENT_TIMESTAMP() AS created_at
    FROM ${project_id}.${dataset_id}.${avro_table} 
    WHERE source IS NOT NULL
      AND dt = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) -- We work on yesterday's data
    GROUP BY txhash
) AS source
ON target.txid = source.txid

-- When record already exist, updating timestamps only when necessary
WHEN MATCHED AND source.last_seen_timestamp > target.last_seen_timestamp THEN
  UPDATE SET 
    last_seen_timestamp = source.last_seen_timestamp,
    modified_at = CURRENT_TIMESTAMP()

WHEN MATCHED AND source.first_seen_timestamp > target.first_seen_timestamp THEN
  UPDATE SET 
    first_seen_timestamp = source.first_seen_timestamp,
    modified_at = CURRENT_TIMESTAMP()

-- Inserting new records
WHEN NOT MATCHED THEN
  INSERT (txid, first_seen_timestamp, last_seen_timestamp, deduplicated_at, modified_at, created_at)
  VALUES (source.txid, source.first_seen_timestamp, source.last_seen_timestamp, source.deduplicated_at, source.modified_at, source.created_at);
