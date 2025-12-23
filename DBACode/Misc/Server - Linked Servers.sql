EXEC sp_helpserver;


SELECT	name
,		data_source
,		provider_string
FROM	sys.servers
WHERE	is_linked = 1;