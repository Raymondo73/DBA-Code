SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT		j.name													AS JobName
,			msdb.dbo.agent_datetime(h.run_date, h.run_time)			AS RunDateTime
,			CONVERT(VARCHAR, (h.run_duration / 10000)) + 'h ' +  
			CONVERT(VARCHAR, (h.run_duration / 100 % 100)) + 'm ' + 
			CONVERT(VARCHAR, (h.run_duration % 100)) + 's'			AS RunDurationHoursMinsSec
,			CASE	WHEN h.run_Status = 0
						THEN 'Failed'
					WHEN h.run_status = 1
						THEN 'Success'					
					WHEN h.run_status = 2
						THEN 'Retry'
					WHEN h.run_status = 3
						THEN 'Cancelled'
			END														AS RunStatus
FROM		msdb.dbo.sysjobs		j 
JOIN		msdb.dbo.sysjobhistory	h	ON j.job_id = h.job_id 
WHERE		j.[enabled] = 1  --Only Enabled Jobs
AND			j.name		= 'Satsuma Incremental Load (1am)'
AND			h.step_id	= 0
ORDER BY	JobName
,			RunDateTime DESC;


SELECT		j.name									AS JobName
,			s.step_id								AS Step
,			s.step_name								AS StepName
,			MIN((h.run_duration / 10000 * 3600 + 
				(run_duration / 100) % 100 * 60 + 
				run_duration%100 + 31 ) / 60)		AS LowestMin
,			AVG((h.run_duration / 10000 * 3600 + 
				(run_duration / 100) % 100 * 60 + 
				run_duration % 100 + 31 ) / 60)		AS AverageMin
,			MAX((h.run_duration / 10000 * 3600 + 
				(run_duration / 100) % 100 * 60 + 
				run_duration % 100 + 31 ) / 60)		AS HighestMin
,			CONVERT(DECIMAL(5,2), STDEV((h.run_duration / 10000 * 3600 + 
				(run_duration / 100) % 100 * 60 + 
				run_duration%100 + 31 ) / 60))		AS stdevMin
FROM		msdb.dbo.sysjobs		j 
JOIN		msdb.dbo.sysjobsteps	s	ON j.job_id		= s.job_id
JOIN		msdb.dbo.sysjobhistory	h	ON s.job_id		= h.job_id 
										AND s.step_id	= h.step_id 
										AND h.step_id	!= 0
WHERE		j.enabled		= 1   
AND			j.name			= 'Satsuma Incremental Load (1am)' 
AND			h.run_date		>= 20170525
GROUP BY	j.Name, s.step_id, s.step_name
ORDER BY	Step ASC;



