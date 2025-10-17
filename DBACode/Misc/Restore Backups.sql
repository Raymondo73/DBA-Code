-- Used with Ola Hallengren Backups

-- FULL with NORECOVERY
RESTORE DATABASE [MyDatabase]
FROM DISK = N'\\BackupShare\SQLBackups\MyDatabase\FULL\MyDatabase_FULL_20251017_010000.bak'
WITH NORECOVERY,
MOVE N'MyDatabase_Data' TO N'E:\SQLData\MyDatabase.mdf',
MOVE N'MyDatabase_Log' TO N'F:\SQLLogs\MyDatabase.ldf',
REPLACE;

-- Diferrential Backup (Optional if we only have Full and Logs)
RESTORE DATABASE [MyDatabase]
FROM DISK = N'\\BackupShare\SQLBackups\MyDatabase\DIFF\MyDatabase_DIFF_20251017_120000.bak'
WITH NORECOVERY;


-- Logs (all in sequence)
-- Repeat for each log in order until your target point
RESTORE LOG [MyDatabase]
FROM DISK = N'\\BackupShare\SQLBackups\MyDatabase\LOG\MyDatabase_LOG_20251017_121500.trn'
WITH NORECOVERY;

-- OR

-- Logs (Point in time)
RESTORE LOG [MyDatabase]
FROM DISK = N'\\BackupShare\SQLBackups\MyDatabase\LOG\MyDatabase_LOG_20251017_123000.trn'
WITH STOPAT = '2025-10-17T12:45:00', RECOVERY;


-- Bring DB online
RESTORE DATABASE [MyDatabase] WITH RECOVERY;

