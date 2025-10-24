SELECT TOP 30		
			DB_NAME(DB_ID())										AS DatabaseName
,			s.Name													AS SchemaName
,			t.NAME													AS TableName
,			FORMAT(SUM(p.rows), '##,##0')							AS [RowCount]
,			((SUM(a.total_pages) * 8) / 1024) / 1024				AS TotalSpaceGB
,			((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024	AS UnusedSpaceMB
FROM		sys.tables				t
JOIN		sys.indexes				i	ON	t.OBJECT_ID		= i.object_id
JOIN		sys.partitions			p	ON	i.object_id		= p.OBJECT_ID 
										AND i.index_id		= p.index_id
JOIN		sys.allocation_units	a	ON	p.partition_id	= a.container_id
LEFT JOIN	sys.schemas				s	ON	t.schema_id		= s.schema_id
WHERE		t.NAME NOT		LIKE 'dt%' 
AND			t.is_ms_shipped = 0
AND			i.OBJECT_ID		> 255 
GROUP BY	t.Name, s.Name, p.Rows
ORDER BY	(SUM(a.total_pages) * 8) / 1024 DESC
,			s.Name
,			t.name;