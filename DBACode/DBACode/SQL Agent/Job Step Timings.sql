SELECT		j.name									AS JobName
,			s.step_id								AS Step
,			s.step_name								AS StepName
,			((run_duration / 10000 * 3600 
				+ (run_duration / 100) % 100 * 60 
				+ run_duration %100 + 31 ) / 60)	AS RunDurationMinutes
FROM		msdb.dbo.sysjobs		j 
JOIN		msdb.dbo.sysjobsteps	s	ON j.job_id		= s.job_id
JOIN		msdb.dbo.sysjobhistory	h	ON s.job_id		= h.job_id 
										AND s.step_id	= h.step_id 
										AND h.step_id	!= 0
WHERE		j.enabled													= 1   
AND			j.name														= 'Satsuma Incremental Load (1am)' 
AND			CONVERT(DATE,  msdb.dbo.agent_datetime(run_date, run_time)) = CONVERT(DATE, GETDATE())
ORDER BY	Step ASC;


SELECT		j.name									AS JobName
,			s.step_id								AS Step
,			s.step_name								AS StepName
,			AVG(((run_duration / 10000 * 3600 
				+ (run_duration / 100) % 100 * 60 
				+ run_duration %100 + 31 ) / 60))	AS AvgRunDurationMinutes
,			MAX(((run_duration / 10000 * 3600 
				+ (run_duration / 100) % 100 * 60 
				+ run_duration %100 + 31 ) / 60))	AS MaxRunDurationMinutes
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



