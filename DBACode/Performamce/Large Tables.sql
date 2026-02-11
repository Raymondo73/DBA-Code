SELECT TOP 10000		
			DB_NAME(DB_ID())																	AS DatabaseName
,			s.name																				AS SchemaName
,			t.name																				AS TableName
,			FORMAT(p.rows, '##,##0')															AS [RowCount]
,			CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 2))						AS Used_MB
,			CAST(ROUND((SUM(a.total_pages) - SUM(a.used_pages)) / 128.00, 2) AS NUMERIC(36, 2)) AS Unused_MB
,			CAST(ROUND((SUM(a.total_pages) / 128.00), 2) AS NUMERIC(36, 2))						AS Total_MB
FROM		sys.tables				t
JOIN		sys.indexes				i	ON	t.object_id		= i.object_id
JOIN		sys.partitions			p	ON	i.object_id		= p.object_id 
										AND i.index_id		= p.index_id
JOIN		sys.allocation_units	a	ON	p.partition_id	= a.container_id
LEFT JOIN	sys.schemas				s	ON	t.schema_id		= s.schema_id
WHERE		t.name			NOT	LIKE 'dt%' 
AND			t.is_ms_shipped = 0
AND			i.object_id		> 255 
GROUP BY	t.name
,			s.name
,			p.rows
ORDER BY	CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 2)) DESC
,			s.name
,			t.name;
