SELECT map_value as Keyword 
FROM sys.dm_xe_map_values
WHERE name = 'keyword_map';
GO

CREATE EVENT SESSION masession
ON SERVER
ADD EVENT sqlos.async_io_requested
ADD EVENT sqlos.async_io_completed
ADD EVENT sqlserver.database_transaction_begin
ADD EVENT sqlserver.database_transaction_end
ADD TARGET package0.etw_classic_sync_target
    (SET default_etw_session_logfile_path = N'C:\temp\sqletw.etl');
GO

ALTER EVENT SESSION masession
ON SERVER
STATE = start
GO
