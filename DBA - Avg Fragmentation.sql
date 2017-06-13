SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


DECLARE @DBID		INT 
,		@MaxDBID	INT;

SELECT	@DBID		= MIN(database_id)
,		@MaxDBID	= MAX(database_id)
FROM	sys.databases
WHERE	[name] NOT IN ('master', 'tempdb', 'model', 'msdb', 'Monitoring', 'SSISDB', 'DBS_Maintenance', 'DBSAdmin');

	CREATE TABLE #Index(	DatabaseName VARCHAR(50), SchemaName VARCHAR(50), TableName VARCHAR(100)
						,	IndexName VARCHAR(100), IndexType VARCHAR(100), AvgPageFrag DECIMAL(10,2)
						,	PageCounts INT);

WHILE @DBID <= @MaxDBID
BEGIN
	INSERT INTO #Index	
	SELECT	TOP 20 
			DB_NAME(ips.DATABASE_ID)							AS [Database Name]
	,		sch.name											AS [Schema Name]
	,		CONVERT(VARCHAR(100), OBJECT_NAME(IPS.OBJECT_ID))	AS [Table Name]
	,		ind.NAME											AS [Index Name]
	,		ips.INDEX_TYPE_DESC									AS [Index Type]
	,		ROUND(ips.AVG_FRAGMENTATION_IN_PERCENT, 2)			AS [Avg Page Fragmentation]
	,		ips.PAGE_COUNT										AS [Page Counts]
	FROM	sys.dm_db_index_physical_stats(@DBID,NULL,NULL,NULL,'LIMITED')	ips
	JOIN	sys.tables														tbl	ON	ips.object_id	= tbl.object_id
	JOIN	sys.schemas														sch	ON	tbl.schema_id	= sch.schema_id  
	JOIN	sys.indexes														ind ON	ips.index_id	= ind.index_id 
																				AND	ips.object_id	= ind.object_id
	JOIN	sys.dm_db_partition_stats										ps	ON	ps.object_id	= ips.object_id and
																					ps.index_id		= ips.index_id
	ORDER BY ips.avg_fragmentation_in_percent DESC

	SELECT	@DBID = MIN(database_id) 
	FROM	sys.databases
	WHERE	[name]		NOT IN ('master', 'tempdb', 'model', 'msdb', 'Monitoring', 'SSISDB', 'DBS_Maintenance', 'DBSAdmin')
	AND		database_id > @DBID;

	IF @DBID IS NULL SET @DBID = @MaxDBID + 1;

END


SELECT		* 
FROM		#Index 
WHERE		AvgPageFrag > 15 
AND			PageCounts	> 1000 
ORDER BY	AvgPageFrag DESC;
