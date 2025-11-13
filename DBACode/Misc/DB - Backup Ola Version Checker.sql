DECLARE @VersionKeyword NVARCHAR(MAX) = '--// Version: ';

SELECT      sc.[name]                                                                                                               AS SchemaName
,           so.[name]                                                                                                               AS ObjectName
,           IIF(CHARINDEX(@VersionKeyword, OBJECT_DEFINITION(so.[object_id])) > 0 
                ,   SUBSTRING(OBJECT_DEFINITION(so.[object_id]), CHARINDEX(@VersionKeyword, OBJECT_DEFINITION(so.[object_id])) + LEN(@VersionKeyword) + 1, 19)
                ,   NULL
                )                                                                                                                   AS [Version]
,           CAST(CHECKSUM(CAST(OBJECT_DEFINITION(so.[object_id]) AS NVARCHAR(MAX)) COLLATE SQL_Latin1_General_CP1_CI_AS) AS BIGINT) AS [Checksum]
FROM        sys.objects so
JOIN        sys.schemas sc  ON so.[schema_id] = sc.[schema_id]
WHERE       sc.[name] = 'dbo'
AND         so.[name] IN ('CommandExecute', 'DatabaseBackup', 'DatabaseIntegrityCheck', 'IndexOptimize')
ORDER BY    sc.[name] ASC
,           so.[name] ASC;