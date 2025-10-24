DECLARE @days_back  INT         = 30;          -- change to 14, 60, 90, etc.
DECLARE @start_date DATETIME2   = DATEADD(DAY, - @days_back, SYSUTCDATETIME());

IF OBJECT_ID(N'tempdb..#bkp', N'U') IS NOT NULL             DROP TABLE #bkp;
IF OBJECT_ID(N'tempdb..#diff_pct', N'U') IS NOT NULL        DROP TABLE #diff_pct;
IF OBJECT_ID(N'tempdb..#log_pct', N'U') IS NOT NULL         DROP TABLE #log_pct;
IF OBJECT_ID(N'tempdb..#per_db', N'U') IS NOT NULL          DROP TABLE #per_db;
IF OBJECT_ID(N'tempdb..#per_db_weighted', N'U') IS NOT NULL DROP TABLE #per_db_weighted;

-- Get Key backup data
SELECT  database_name
,       type                        -- D=Full, I=Diff, L=Log
,       backup_start_date
,       backup_finish_date
,       compressed_backup_size      -- use compressed size for % calculations
,       compressed_backup_size / 1048576.0 AS AverageSizeMB
,       differential_base_lsn
,       first_lsn
,       last_lsn
,       checkpoint_lsn
INTO    #bkp
FROM    msdb.dbo.backupset
WHERE   backup_start_date   >= @start_date
AND     type                IN ('D','I','L');

CREATE INDEX idxDate    ON #bkp(database_name, type, backup_start_date);
CREATE INDEX idxChkpt   ON #bkp(database_name, checkpoint_lsn);

SELECT      database_name
,           FORMAT(AVG(AverageSizeMB), 'N2') AS AverageSizeMB
FROM        #bkp 
WHERE       type = 'D'
GROUP BY    database_name;

-- Latest FULL before each row’s start time (per DB)
WITH Fulls AS 
(
    SELECT  database_name
    ,       backup_finish_date      AS full_time
    ,       compressed_backup_size  AS full_bytes
    FROM    #bkp 
    WHERE   type = 'D'
) 
, BaselineFullPerDiff AS 
(
    SELECT      d.database_name
    ,           d.backup_start_date         AS diff_time
    ,           d.compressed_backup_size    AS diff_bytes
    ,           f.full_bytes
    FROM        #bkp d
    OUTER APPLY (
                SELECT TOP (1) f.full_bytes
                FROM        Fulls f
                WHERE       f.database_name = d.database_name
                AND         f.full_time     <= d.backup_start_date
                ORDER BY    f.full_time DESC
                ) f
    WHERE       d.type = 'I'
)
-- Results:
SELECT      'DIFF'                                                          AS metric
,           database_name
,           AVG(IIF(full_bytes > 0, 1.0 * diff_bytes / full_bytes, 0.0))    AS avg_daily_diff_pct
INTO        #diff_pct
FROM        BaselineFullPerDiff
GROUP BY    database_name;

WITH Fulls AS 
(
    SELECT  database_name
    ,       backup_finish_date      AS full_time
    ,       compressed_backup_size  AS full_bytes
    FROM    #bkp 
    WHERE   type = 'D'
) 
, LogDay AS 
-- Sum log bytes per DB per day
(
    SELECT      database_name
    ,           CAST(backup_start_date AS DATE) AS log_date
    ,           SUM(compressed_backup_size)     AS log_bytes
    FROM        #bkp
    WHERE       type = 'L'
    GROUP BY    database_name
    ,           CAST(backup_start_date AS DATE)
)
, BaselineFullPerLogDay AS 
-- Match each log day to the latest FULL before that day
(
    SELECT      l.database_name
    ,           l.log_date
    ,           l.log_bytes
    ,           f.full_bytes
    FROM        LogDay l
    OUTER APPLY (
                SELECT TOP (1) f.full_bytes
                FROM        Fulls f
                WHERE       f.database_name = l.database_name
                AND         f.full_time     <= DATEADD(DAY, 1, l.log_date)  -- full before end of that day
                ORDER BY    f.full_time DESC
                ) f
)
SELECT      'LOG'                                                       AS metric
,           database_name
,           AVG(IIF(full_bytes > 0, 1.0 * log_bytes / full_bytes, 0.0)) AS avg_daily_log_pct
INTO        #log_pct
FROM        BaselineFullPerLogDay
GROUP BY    database_name;


-- Combine per DB
SELECT          COALESCE(d.database_name, l.database_name)                          AS database_name
,               ISNULL(d.avg_daily_diff_pct, 0)                                     AS avg_daily_diff_pct
,               ISNULL(l.avg_daily_log_pct, 0)                                      AS avg_daily_log_pct
,               (ISNULL(d.avg_daily_diff_pct, 0) + ISNULL(l.avg_daily_log_pct, 0))  AS avg_daily_change_pct  -- total daily write %
INTO            #per_db
FROM            #diff_pct   d
FULL OUTER JOIN #log_pct    l ON d.database_name = l.database_name
ORDER BY        database_name;

-- Look up each DB's current FULL size to weight the estate average
WITH LatestFull AS 
(
SELECT  x.database_name
,       x.compressed_backup_size
,       ROW_NUMBER() OVER (PARTITION BY x.database_name ORDER BY x.backup_finish_date DESC) AS rn
FROM    #bkp x
WHERE   x.type = 'D'
)
SELECT      p.database_name
,           p.avg_daily_diff_pct
,           p.avg_daily_log_pct
,           p.avg_daily_change_pct
,           lf.compressed_backup_size AS latest_full_bytes
INTO        #per_db_weighted
FROM        #per_db     p
LEFT JOIN   LatestFull  lf  ON  p.database_name = lf.database_name 
                            AND lf.rn           = 1;

-- Estate-wide weighted averages (weights = latest full size)
SELECT  FORMAT(SUM(avg_daily_diff_pct * latest_full_bytes) / NULLIF(SUM(latest_full_bytes), 0) * 100, 'N5')     AS estate_avg_diff_pct
,       FORMAT(SUM(avg_daily_log_pct  * latest_full_bytes) / NULLIF(SUM(latest_full_bytes), 0) * 100, 'N5')     AS estate_avg_log_pct
,       FORMAT(SUM(avg_daily_change_pct * latest_full_bytes) / NULLIF(SUM(latest_full_bytes), 0) * 100, 'N5')   AS estate_avg_total_daily_pct
FROM    #per_db_weighted;
