SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT	PVT.DatabaseName
,		ISNULL(FORMAT(PVT.[1], '##,##.#0'), 0)	AS Jan
,		ISNULL(FORMAT(PVT.[2], '##,##.#0'), 0)	AS Feb
,		ISNULL(FORMAT(PVT.[3], '##,##.#0'), 0)	AS Mar
,		ISNULL(FORMAT(PVT.[4], '##,##.#0'), 0)	AS Apr
,		ISNULL(FORMAT(PVT.[5], '##,##.#0'), 0)	AS May
,		ISNULL(FORMAT(PVT.[6], '##,##.#0'), 0)	AS Jun
,		ISNULL(FORMAT(PVT.[7], '##,##.#0'), 0)	AS Jul
,		ISNULL(FORMAT(PVT.[8], '##,##.#0'), 0)	AS Aug
,		ISNULL(FORMAT(PVT.[9], '##,##.#0'), 0)	AS Sep
,		ISNULL(FORMAT(PVT.[10], '##,##.#0'), 0)	AS Oct
,		ISNULL(FORMAT(PVT.[11], '##,##.#0'), 0)	AS Nov
,		ISNULL(FORMAT(PVT.[12], '##,##.#0'), 0)	AS [Dec]
FROM	(
		SELECT		database_name											AS DatabaseName
		,			DATEPART(month, backup_start_date)						AS BackupDate
		,			CONVERT(NUMERIC(10, 2), AVG(backup_size / 1048576.0))	AS AvgSizeMB
		FROM		msdb.dbo.backupset
		WHERE		database_name NOT IN ('master', 'msdb', 'model', 'tempdb')
		AND			[type]								= 'D'
		AND			DATEPART(year, backup_start_date)	= DATEPART(year, GETDATE())
		GROUP BY	database_name
		,			backup_start_date
		) AS BCKSTAT
PIVOT	(AVG(BCKSTAT.AvgSizeMB) FOR BCKSTAT.BackupDate IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])) AS PVT
ORDER BY PVT.DatabaseName;


