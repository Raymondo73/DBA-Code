/*
	Identify inbound connections (who’s connecting)
	Run this during normal business hours or over time (snapshot regularly).
*/

SELECT		c.client_net_address
,			s.host_name
,			s.program_name
,			s.login_name
,			DB_NAME(s.database_id) AS database_name
,			s.status
,			s.last_request_end_time
FROM		sys.dm_exec_sessions        s
JOIN		sys.dm_exec_connections     c	ON s.session_id = c.session_id
WHERE		s.is_user_process = 1
ORDER BY	s.host_name
,			s.program_name;