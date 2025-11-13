CREATE TABLE #FileSize
(
    dbName          NVARCHAR(128)
,   FileName        NVARCHAR(128)
,   PhysicalName    NVARCHAR(128)
,   type_desc       NVARCHAR(128)
,   CurrentSizeMB   DECIMAL(10,2)
,   FreeSpaceMB     DECIMAL(10,2)
);
    
INSERT INTO #FileSize
            (dbName, FileName, PhysicalName, type_desc, CurrentSizeMB, FreeSpaceMB)
EXEC        sp_msforeachdb 
            'use [?]; 
             SELECT DB_NAME() AS DbName
             ,      name AS FileName
             ,      physical_name AS PhysicalName
             ,      type_desc
             ,      size / 128.0 AS CurrentSizeMB
             ,      size / 128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT) / 128.0 AS FreeSpaceMB
             FROM   sys.database_files
             WHERE  type IN (0,1)
             --UNION
             --SELECT DB_NAME() AS DbName
             --,      name AS FileName
             --,      physical_name AS PhysicalName
             --,      type_desc
             --,      size / 128.0 AS CurrentSizeMB
             --,      size / 128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT) / 128.0 AS FreeSpaceMB
             --FROM   sys.master_files
             --WHERE  type IN (0,1);
             ';
    
SELECT  * 
FROM    #FileSize
--WHERE   dbName NOT IN ('distribution', 'master', 'model', 'msdb');
    
DROP TABLE #FileSize;


--select * from sys.master_files