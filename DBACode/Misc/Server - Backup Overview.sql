/* Backups by DB with last file, avg size, and success/failure counts
   - Change @Since to control the time window
*/
DECLARE @Since DATETIME = DATEADD(DAY, -30, GETDATE());

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

WITH raw AS 
(
SELECT      b.database_name
,           CASE b.type WHEN 'D' THEN 'Full'
                        WHEN 'I' THEN 'Differential'
                        WHEN 'L' THEN 'Log' 
            END                                                                 AS backup_type
,           b.backup_start_date
,           b.backup_finish_date
,           ISNULL(NULLIF(b.compressed_backup_size, 0), b.backup_size)          AS backup_size_bytes 
,           b.is_damaged
,           b.media_set_id
,           mf.physical_device_name
,           mf.device_type
,           IIF(b.backup_finish_date IS NOT NULL AND b.is_damaged = 0, 1, 0)    AS succeeded 
,           IIF(b.backup_finish_date IS NULL OR b.is_damaged = 1, 1, 0)         AS failed    
FROM        msdb.dbo.backupset          b
LEFT JOIN   msdb.dbo.backupmediafamily  mf  ON mf.media_set_id = b.media_set_id
WHERE       b.type              IN ('D','I','L')
AND         b.backup_start_date >= @Since
),
agg AS 
(
SELECT      database_name
,           backup_type
,           COUNT(1)                                AS total_count  
,           SUM(succeeded)                          AS success_count
,           SUM(failed)                             AS failed_count 
,           AVG(CONVERT(BIGINT, backup_size_bytes)) AS avg_bytes    
FROM        raw
GROUP BY    database_name
,           backup_type
)
SELECT      @@SERVERNAME                                    AS ServerName
,           a.database_name
,           IIF(d.database_id <= 4, 'System', 'User')       AS DBCategory
,           a.backup_type
,           a.total_count
,           a.success_count
,           a.failed_count
,           CONVERT(DECIMAL(18,2), a.avg_bytes / 1048576.0) AS avg_backup_size_mb 
,           ls.last_success_finish                          AS last_success_finish 
,           ls.device_type_desc                             AS device_type
,           ls.friendly_location                            AS device_type_desc
FROM        agg                   a           
LEFT JOIN   master.sys.databases  d ON d.name = a.database_name
OUTER APPLY (
            SELECT TOP (1)  r.backup_finish_date                                                            AS last_success_finish
            ,               r.physical_device_name                                                          AS last_file_location
            ,               CASE r.device_type  WHEN 2 THEN 'Disk'
                                                WHEN 5 THEN 'Tape'
                                                WHEN 7 THEN 'Virtual Device (VDI)'
                                                WHEN 9 THEN 'URL (Azure)'
                                                ELSE CONCAT('DeviceType ', r.device_type)
                            END                                                                             AS device_type_desc
            ,               CASE    WHEN r.device_type = 2 AND r.physical_device_name LIKE '%\%' 
                                        THEN    LEFT(r.physical_device_name, LEN(r.physical_device_name) 
                                                    - CHARINDEX('\', REVERSE(r.physical_device_name)) + 1)
                                    WHEN r.device_type = 9 THEN r.physical_device_name  -- Azure URL
                                    WHEN r.device_type = 7 THEN '(VDI – backup via 3rd-party tool)'
                                    WHEN r.device_type = 5 THEN r.physical_device_name  -- Tape
                                    ELSE r.physical_device_name
                            END                                                                             AS friendly_location 
            FROM            raw r
            WHERE           r.database_name = a.database_name
            AND             r.backup_type   = a.backup_type
            AND             r.succeeded     = 1
            ORDER BY        r.backup_finish_date DESC
            ) ls
ORDER BY    a.database_name
,           a.backup_type;
