UPDATE ${project_id}.${dataset_id}.${bloclevel_table} AS a
SET
  block_timestamp = t.block_timestamp,
  block_height = t.block_number,
  size = t.size,
  virtual_size = t.virtual_size,
  output_value = CAST(t.output_value AS INT64),
  fee = CAST(t.fee AS INT64),
  aggregated_at = CURRENT_TIMESTAMP(),
  aggregated_by = "longtail_blocklevel_update",
  modified_at = CURRENT_TIMESTAMP()
FROM `bigquery-public-data.crypto_bitcoin.transactions` t
WHERE a.block_timestamp IS NULL 
  AND a.aggregated_at IS NULL
  AND a.deduplicated_at IS NOT NULL  
  AND DATE(a.last_seen_timestamp) = DATE_SUB(CURRENT_DATE(), INTERVAL 8 DAY) 
  AND (
    (SELECT MAX(block_height) FROM ${project_id}.${dataset_id}.${bloclevel_table} WHERE aggregated_by = "longtail_blocklevel_update") IS NULL
    OR a.block_height >= (SELECT MAX(block_height) FROM ${project_id}.${dataset_id}.${bloclevel_table} WHERE aggregated_by = "longtail_blocklevel_update")
  )
  AND a.txid = t.hash
                 --  REPLACE THAT BY A FILTER ON deduplicated_at NOT NULL BUT aggregated_at NULL ? INSTEAD FOR 'RETRIEVED MODE IN CASE OF ISSUE'
  AND t.block_timestamp BETWEEN TIMESTAMP_ADD(a.last_seen_timestamp, INTERVAL 24 HOUR) AND TIMESTAMP_ADD(a.last_seen_timestamp, INTERVAL 7 DAY);  
                  -- Streamlined date range filtering, 
								  -- standard_blocklevel_update is requesting with TIMESTAMP_ADD(a.last_seen_timestamp, INTERVAL 1 HOUR) first 
                  -- assuming that most of the tx will be added to a bloc in a moment very close to the last_seen_timestamp
                  -- and then extended_blocklevel_update is executing the request with a bigger interval (24h)
                  -- and then longtail_blocklevel_update with an even bigger interval (7 days)
                  -- What is the median time currently for a tx to be added to a bloc ?
