SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT  s.name	[schema]
,		o.name	[table]
,		fk.name [foreign_key_no_index]
FROM	sys.foreign_keys	fk
JOIN	sys.objects			o ON o.[object_id] = fk.parent_object_id
JOIN	sys.schemas			s ON s.[schema_id] = o.[schema_id]
WHERE	o.is_ms_shipped = 0
AND		NOT EXISTS (	SELECT	ic.index_id
						FROM	sys.index_columns ic
						WHERE	EXISTS	(	SELECT	1
											FROM	sys.foreign_key_columns fkc
											WHERE	fkc.constraint_object_id	= fk.[object_id]
											AND		fkc.parent_object_id		= ic.[object_id]
											AND		fkc.parent_column_id		= ic.column_id 
										)
						GROUP BY ic.index_id
						HAVING	COUNT(1) = MAX(index_column_id)
						AND		COUNT(1) = (	SELECT	COUNT(1)
												FROM	sys.foreign_key_columns fkc
												WHERE	fkc.constraint_object_id = fk.[object_id] 
											) 
					)
ORDER BY o.[name], fk.[name];

