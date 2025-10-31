-- Operators + their email, per server
SELECT		SERVERPROPERTY('ServerName')	AS ServerName
,			o.name							AS OperatorName
,			o.email_address					AS OperatorEmail
FROM		msdb.dbo.sysoperators o
ORDER BY	o.name;


-- One row per SQL Agent job on this server
SELECT      SERVERPROPERTY('ServerName')                            AS ServerName
,           j.name                                                  AS JobName
,           SUSER_SNAME(j.owner_sid)                                AS OwnerName
,           op.name                                                 AS OperatorAssigned      -- NULL if none
,           IIF(j.enabled = 1, 'Yes', 'No')                         AS JobActive
,           msdb.dbo.agent_datetime (   NULLIF(js.last_run_date,0)
                                    ,   NULLIF(js.last_run_time,0)
                                    )                               AS LastRunDateTime       -- NULL if never ran
FROM        msdb.dbo.sysjobs        j
LEFT JOIN   msdb.dbo.sysoperators   op ON j.notify_email_operator_id    = op.id
LEFT JOIN   msdb.dbo.sysjobservers  js ON j.job_id                      = js.job_id
WHERE       j.name NOT LIKE '%-%-%-%-%'
ORDER BY    j.name;

