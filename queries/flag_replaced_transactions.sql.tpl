MERGE ${project_id}.${dataset_id}.${bloclevel_table} AS target
USING (
  SELECT
    replace_txhash AS txid,
    txhash AS replaced_by
  FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY replace_txhash ORDER BY dt DESC) AS row_num
    FROM ${project_id}.${dataset_id}.${avro_table} 
    WHERE source IS NOT NULL
      AND dt = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
      AND replace_txhash IS NOT NULL
    )
  WHERE row_num = 1
) AS source
ON target.txid = source.txid
  AND target.last_seen_timestamp BETWEEN TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY) AND CURRENT_TIMESTAMP() 

WHEN MATCHED THEN
  UPDATE SET
    replaced_by = source.replaced_by,
    modified_at = CURRENT_TIMESTAMP();
