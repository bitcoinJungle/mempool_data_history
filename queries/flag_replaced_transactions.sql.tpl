MERGE ${project_id}.${dataset_id}.${bloclevel_table} AS target
USING (
  SELECT
    replace_txhash AS txid,
    txhash AS replaced_by
  FROM ${project_id}.${dataset_id}.${avro_table} 
  WHERE source IS NOT NULL
    AND dt = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
    AND replace_txhash IS NOT NULL
) AS source
ON target.txid = source.txid
  AND target.last_seen_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY) -- helps prune partitions

WHEN MATCHED THEN
  UPDATE SET
    replaced_by = source.replaced_by,
    modified_at = CURRENT_TIMESTAMP();
