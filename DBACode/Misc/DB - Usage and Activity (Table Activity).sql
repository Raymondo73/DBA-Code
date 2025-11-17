/* Summarize per object (last activity + type) across ALL databases */
SET NOCOUNT ON;

WITH usage AS 
(
SELECT  DB_NAME(database_id) AS database_name
,       object_id
,       user_seeks
,       user_scans
,       user_lookups
,       user_updates
,       last_user_seek
,       last_user_scan
,       last_user_lookup
,       last_user_update
FROM    sys.dm_db_index_usage_stats
WHERE   database_id				> 4 -- exclude system DBs (master, msdb, model, tempdb)
AND		DB_NAME(database_id)	!= 'SQLMaint'
)
,   flatten AS 
(
SELECT  database_name
,       object_id
,       'READ_SEEK'     AS kind
,       user_seeks      AS cnt
,       last_user_seek  AS last_time 
FROM    usage
UNION ALL
SELECT  database_name
,       object_id
,       'READ_SCAN'
,       user_scans
,       last_user_scan          
FROM    usage
UNION ALL
SELECT  database_name
,       object_id
,       'READ_LOOKUP'
,       user_lookups
,       last_user_lookup        
FROM    usage
UNION ALL
SELECT  database_name
,       object_id
,       'WRITE'
,       user_updates
,       last_user_update        
FROM    usage
)
,   rollup AS 
(
SELECT      f.database_name
,           OBJECT_SCHEMA_NAME(f.object_id, DB_ID(f.database_name))		AS [schema_name]
,           OBJECT_NAME(f.object_id, DB_ID(f.database_name))			AS [object_name]
,           FORMAT(SUM(IIF(kind LIKE 'READ%', cnt, 0)), 'N0')			AS total_reads
,           FORMAT(SUM(IIF(kind = 'WRITE', cnt, 0)), 'N0')				AS total_writes
,           MAX(IIF(kind LIKE 'READ%', last_time, NULL))				AS last_read_time
,           MAX(IIF(kind = 'WRITE', last_time, NULL))					AS last_write_time
FROM        flatten f
GROUP BY    f.database_name
,           OBJECT_SCHEMA_NAME(f.object_id, DB_ID(f.database_name))
,           OBJECT_NAME(f.object_id, DB_ID(f.database_name))
)
SELECT      database_name
,           schema_name
,           object_name
,           total_reads
,           total_writes
,           last_read_time
,           last_write_time
FROM        rollup
ORDER BY    database_name
,			COALESCE(last_write_time, last_read_time) DESC
,           schema_name
,			object_name;
