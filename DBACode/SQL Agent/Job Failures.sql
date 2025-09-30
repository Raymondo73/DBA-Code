SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

USE msdb;
GO

-- Failed Jobs
SELECT      j.name                                                                              AS JobName
,           h.step_id
,           h.step_name
,           h.sql_message_id
,           h.sql_severity
,           h.message                                                                           AS ErrorMessage
,           h.run_date
,           STUFF(STUFF(RIGHT('000000' + CAST(h.run_time AS VARCHAR(6)),6),5,0,':'),3,0,':')    AS RunTime
FROM        msdb.dbo.sysjobs        j
JOIN        msdb.dbo.sysjobhistory  h   ON j.job_id = h.job_id
WHERE       h.run_status    = 0  -- 0 = Failed
AND         h.run_date      >= CONVERT(INT, CONVERT(CHAR(8), DATEADD(DAY, -30, GETDATE()), 112))  -- last 30 days
AND         h.instance_id   IN  (
                                SELECT      MAX(instance_id)
                                FROM        msdb.dbo.sysjobhistory
                                GROUP BY    job_id
                                )
ORDER BY    h.run_date DESC
,           h.run_time DESC;


-- Failed Steps
SELECT      j.name                                          AS JobName
,           h.step_id
,           h.step_name
,           h.sql_message_id
,           h.sql_severity
,           h.message                                       AS ErrorMessage
,           msdb.dbo.agent_datetime(h.run_date, h.run_time) AS RunDateTime
FROM        msdb.dbo.sysjobhistory  h
JOIN        msdb.dbo.sysjobs        j ON j.job_id = h.job_id
WHERE       h.step_id       > 0           -- step rows only
AND         h.run_status    = 0        -- failed
AND         h.run_date      >= CONVERT(INT, CONVERT(CHAR(8), DATEADD(DAY, -30, GETDATE()), 112))  -- last 30 days
ORDER BY    RunDateTime DESC
,           j.name
,           h.step_id;
