
-- Windows Logins -----------------------------
SELECT  login_name
,       host_name
,       program_name
,       login_time
,       last_request_start_time
,		last_request_end_time
FROM	sys.dm_exec_sessions
WHERE	is_user_process = 1;

-- AD Has DB Access ----------------------------------
SELECT      l.name					AS LoginName
,           dp.name					AS DBUserName
,           dp.type_desc			AS DBUserType
,           dp.create_date
,           dp.modify_date
,           sp.permission_name
,			sp.state_desc			AS PermissionState
FROM		sys.database_principals		dp
LEFT JOIN	sys.server_principals		l	ON dp.sid			= l.sid
LEFT JOIN	sys.database_permissions	sp	ON dp.principal_id	= sp.grantee_principal_id
WHERE		dp.type IN ('S', 'U', 'G')   -- SQL, Windows user, Windows group
ORDER BY	dp.name;
