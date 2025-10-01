/*
File-level IO latency

Rule of thumb:
    Reads > 20 ms → IO subsystem might be struggling.
    Writes > 5 ms → potential log file / storage issue.
*/

SELECT      DB_NAME(vfs.database_id)                            AS DatabaseName
,           mf.name                                             AS LogicalName
,           mf.type_desc
,           vfs.num_of_reads
,           vfs.num_of_writes
,           vfs.io_stall_read_ms / NULLIF(vfs.num_of_reads,0)   AS AvgReadLatency_ms
,           vfs.io_stall_write_ms / NULLIF(vfs.num_of_writes,0) AS AvgWriteLatency_ms
FROM        sys.dm_io_virtual_file_stats(NULL, NULL)    vfs
JOIN        sys.master_files                            mf  ON  vfs.database_id = mf.database_id 
                                                            AND vfs.file_id     = mf.file_id
WHERE       vfs.database_id > 4
ORDER BY    AvgReadLatency_ms DESC
,           AvgWriteLatency_ms DESC;

-- Top queries by physical IO
-- Shows the "heaviest" queries on disk.
SELECT TOP 20   qs.total_physical_reads
,               qs.total_logical_reads
,               qs.total_logical_writes
,               qs.execution_count
,               qs.total_elapsed_time / qs.execution_count                              AS AvgElapsedTime_ms
,               SUBSTRING(qt.text, (qs.statement_start_offset/2) + 1,
                    ((CASE qs.statement_end_offset
                        WHEN -1 THEN DATALENGTH(qt.text)
                        ELSE qs.statement_end_offset END - qs.statement_start_offset)
                /2)+1)                                                                  AS QueryText
FROM            sys.dm_exec_query_stats qs
CROSS APPLY     sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY        qs.total_physical_reads DESC;