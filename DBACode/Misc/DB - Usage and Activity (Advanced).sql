-- One-time create; adjust filename path and DB filter list as needed
CREATE EVENT SESSION [db_io_watch] ON SERVER

ADD EVENT sqlserver.database_file_read
(
    ACTION  ( sqlserver.client_hostname
            , sqlserver.username
            , sqlserver.database_name
            )
    WHERE   (   sqlserver.database_id IN    (   DB_ID(N'Branch')
                                            ,   DB_ID(N'CCMDData')
                                            ,   DB_ID(N'CCMStatisticalData')
                                            ,   DB_ID(N'TotalMobileIntegration')
                                            ,   DB_ID(N'WDHInteractive')
                                            ,   DB_ID(N'WebStatistics')
                                            )
            )
),
ADD EVENT sqlserver.database_file_write
(
    ACTION  (   sqlserver.client_hostname
            ,   sqlserver.username
            ,   sqlserver.database_name
            )
    WHERE   (   sqlserver.database_id IN    (   DB_ID(N'Branch')
                                            ,   DB_ID(N'CCMDData')
                                            ,   DB_ID(N'CCMStatisticalData')
                                            ,   DB_ID(N'TotalMobileIntegration')
                                            ,   DB_ID(N'WDHInteractive')
                                            ,   DB_ID(N'WebStatistics')
                                            )
            )
)
ADD TARGET package0.asynchronous_file_target
(
SET filename = N'C:\XE\db_io_watch.xel', metadatafile = N'C:\XE\db_io_watch.xem'
);
GO

ALTER EVENT SESSION [db_io_watch] ON SERVER STATE = START;



