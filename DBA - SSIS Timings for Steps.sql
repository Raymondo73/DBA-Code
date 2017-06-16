USE SSISDB;

-- User for @SSIS
SELECT	DISTINCT project_name
FROM	SSISDB.[catalog].executions;

DECLARE @DATE DATE			= GETDATE() -2
,		@SSIS VARCHAR(500)	= 'satsuma.etl';

SELECT  e.folder_name
,		e.project_name
,		e.package_name
,		es.execution_path
,		DATEDIFF(minute, es.start_time, es.end_time) AS execution_time
FROM	SSISDB.[catalog].executions				e
JOIN	SSISDB.[catalog].executable_statistics	es	ON e.execution_id = es.execution_id
WHERE	e.start_time	>= @DATE
AND		e.project_name	= @SSIS
ORDER BY execution_time DESC;



SELECT     CAST(MSG.message_time AS datetime)	AS message_time
,			CASE message_source_type
                WHEN 10 THEN 'Entry APIs, such as T-SQL and CLR Stored procedures'
                WHEN 20 THEN 'External process used to run package (ISServerExec.exe)'
                WHEN 30 THEN 'Package-level objects'
                WHEN 40 THEN 'Control Flow tasks'
                WHEN 50 THEN 'Control Flow containers'
                WHEN 60 THEN 'Data Flow task'
            END												AS message_source_type
,			CAST(start_time AS datetime)					AS start_time
,			OPR.object_name
,			message
,			LEFT(message, CHARINDEX(':', message) -1)		AS Block
,			CONVERT(TIME(0), LEFT(RIGHT(message, 13),12))	AS execution_time
FROM        SSISDB.[catalog].operation_messages	MSG
JOIN		SSISDB.[catalog].operations			OPR	ON OPR.operation_id = MSG.operation_id
WHERE		start_time			> @DATE 
and			message				like '%:Finish%' 
and			message				not like 'INSERT Record SQL Task:Finished%'
and			message_source_type <> 30
and			message_source_type <> 50
and			OPR.object_name		= @SSIS
--ORDER BY message_time DESC
ORDER BY execution_time DESC


