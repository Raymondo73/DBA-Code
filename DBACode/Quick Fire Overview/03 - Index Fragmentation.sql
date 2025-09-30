-- Red flag: High fragmentation with large page counts.

-- Top 20 fragmented indexes >30% on tables >1000 pages
SELECT TOP 20   dbschemas.[name]                        AS SchemaName
,               dbtables.[name]                         AS TableName
,               dbindexes.[name]                        AS IndexName
,               indexstats.avg_fragmentation_in_percent
,               indexstats.page_count
FROM            sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED')    indexstats
JOIN            sys.tables                                                              dbtables    ON  dbtables.[object_id]     = indexstats.[object_id]
JOIN            sys.schemas                                                             dbschemas   ON  dbtables.[schema_id]     = dbschemas.[schema_id]
JOIN            sys.indexes                                                             dbindexes   ON  dbindexes.[object_id]    = indexstats.[object_id]
                                                                                                    AND indexstats.index_id      = dbindexes.index_id
WHERE           indexstats.database_id                  = DB_ID()
AND             indexstats.page_count                   > 1000
AND             indexstats.avg_fragmentation_in_percent > 30
ORDER BY        indexstats.avg_fragmentation_in_percent DESC;
