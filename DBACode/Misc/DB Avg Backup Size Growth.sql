SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT	PVT.DatabaseName
,		FORMAT(PVT.[1], '##,##.#0')		AS Jan
,		FORMAT(PVT.[2], '##,##.#0')		AS Feb
,		FORMAT(PVT.[3], '##,##.#0')		AS Mar
,		FORMAT(PVT.[4], '##,##.#0')		AS Apr
,		FORMAT(PVT.[5], '##,##.#0')		AS May
,		FORMAT(PVT.[6], '##,##.#0')		AS Jun
,		FORMAT(PVT.[7], '##,##.#0')		AS Jul
,		FORMAT(PVT.[8], '##,##.#0')		AS Aug
,		FORMAT(PVT.[9], '##,##.#0')		AS Sep
,		FORMAT(PVT.[10], '##,##.#0')	AS Oct
,		FORMAT(PVT.[11], '##,##.#0')	AS Nov
,		FORMAT(PVT.[12], '##,##.#0')	AS [Dec]
FROM	(
		SELECT		database_name											AS DatabaseName
		,			DATEPART(month, backup_start_date)						AS BackupDate
		,			CONVERT(NUMERIC(10, 2), AVG(backup_size / 1048576.0))	AS AvgSizeMB
		FROM		msdb.dbo.backupset
		WHERE		database_name NOT IN ('master', 'msdb', 'model', 'tempdb')
		AND			[type] = 'D'
		AND			DATEPART(year, backup_start_date) = DATEPART(year, GETDATE())
		GROUP BY	database_name
		,			backup_start_date
		) AS BCKSTAT
PIVOT	(AVG(BCKSTAT.AvgSizeMB) FOR BCKSTAT.BackupDate IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])) AS PVT
ORDER BY PVT.DatabaseName;


