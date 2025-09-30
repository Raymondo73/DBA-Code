/*
    master → Holds instance metadata; if C: fails, SQL won’t start.
    msdb → Critical for SQL Agent jobs, backups, and history; space issues on C: can stop scheduling.
    model → Template for new DBs; corruption or space issues affect all new DB creation.
    tempdb → Heavy IO use; if on C:, competes with OS and risks performance bottlenecks.
    SSISDB → User DB for SSIS catalog; loss or corruption impacts deployments and package runs.

    Red flags:
        Tiny growth increments (1MB, 10%)
        Frequent autogrowth events in logs
*/

-- Data & log files with sizes and growth settings
SELECT      db_name(database_id)    AS DatabaseName
,           name                    AS FileName
,           mf.physical_name
,           type_desc               AS FileType
,           size * 8 / 1024         AS SizeMB
,           growth
,           CASE is_percent_growth 
                WHEN 1 THEN CAST(growth AS VARCHAR(10)) + '%'
                ELSE CAST(growth * 8 / 1024 AS VARCHAR(10)) + ' MB'
            END                     AS GrowthSetting
FROM        sys.master_files mf
ORDER BY    DatabaseName
,           FileType;
