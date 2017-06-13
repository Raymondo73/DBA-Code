DECLARE @DATE DATE = GETDATE() -2

SELECT  [executions].[folder_name]
      , [executions].[project_name]
      , [executions].[package_name]
      , [executable_statistics].[execution_path]
      , DATEDIFF(minute, [executable_statistics].[start_time], [executable_statistics].[end_time]) AS execution_time
FROM [SSISDB].[catalog].[executions]
INNER JOIN [SSISDB].[catalog].[executable_statistics]
    ON [executions].[execution_id] = [executable_statistics].[execution_id]
WHERE [executions].[start_time] >= @DATE
and [executions].project_name = 'satsuma.HDS.etl'
ORDER BY execution_time desc
Merge EPT - Satsuma_src_Merge_PAN_SCHEDULES:Finished, 01:26:42, Elapsed time: 00:18:18.047.

DECLARE @DATE DATE = GETDATE() -2

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
FROM        catalog.operation_messages	MSG
JOIN		catalog.operations			OPR	ON OPR.operation_id = MSG.operation_id
WHERE		start_time			> @DATE 
and			message				like '%:Finish%' 
and			message				not like 'INSERT Record SQL Task:Finished%'
and			message_source_type <> 30
and			message_source_type <> 50
and			OPR.object_name		= 'satsuma.HDS.etl'
--ORDER BY message_time DESC
ORDER BY execution_time DESC