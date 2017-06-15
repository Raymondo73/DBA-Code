create table dbo.source_data (id int primary key, data char(100) not null)
go
create table dbo.destination_pk (id int primary key, data char(100) not null)
go
insert into dbo.source_data (id,data)
select top 850000 row_number() over (order by sysdatetime()), 'blah blah' from master..spt_values a, master..spt_values b, master..spt_values c
go
sp_spaceused 'dbo.source_data'
go



SELECT COUNT(*)AS numrecords,
  CAST((COALESCE(SUM([Log Record LENGTH]), 0))
    / 1024. / 1024. AS NUMERIC(12, 2)) AS size_mb
FROM sys.fn_dblog(NULL, NULL) AS D
WHERE AllocUnitName = 'dbo.destination_pk' OR AllocUnitName LIKE 'dbo.destination_pk.%';

-- Breakdown of Log Record Types
SELECT Operation, Context,
  AVG([Log Record LENGTH]) AS AvgLen, COUNT(*) AS Cnt
FROM sys.fn_dblog(NULL, NULL) AS D
WHERE AllocUnitName = 'dbo.destination_pk' OR AllocUnitName LIKE 'dbo.destination_pk.%'
GROUP BY Operation, Context, ROUND([Log Record LENGTH], -2)
ORDER BY AvgLen, Operation, Context;

SELECT OBJECT_NAME(p.object_id) AS object_name
       , i.name AS index_name
       , ps.in_row_used_page_count
FROM sys.dm_db_partition_stats ps
JOIN sys.partitions p
       ON ps.partition_id = p.partition_id
JOIN sys.indexes i
       ON p.index_id = i.index_id
       AND p.object_id = i.object_id