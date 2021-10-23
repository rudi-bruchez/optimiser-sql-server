SELECT session_id, wait_duration_ms, resource_description
FROM sys.dm_os_waiting_tasks
WHERE wait_type like 'PAGE%LATCH_%' AND resource_description like '2:%'
GO

SELECT *
FROM sys.dm_tran_active_snapshot_database_transactions
ORDER BY elapsed_time_seconds DESC;
GO

SELECT
  SUM(user_object_reserved_page_count)*8 as user_object_kb,
  SUM(internal_object_reserved_page_count)*8 as internal_object_kb,
  SUM(version_store_reserved_page_count)*8 as version_store_kb
FROM sys.dm_db_file_space_usage;
-- ou en Mo
SELECT
SUM(user_object_reserved_page_count)*1.0/128 as user_object_mb,
SUM(internal_object_reserved_page_count)*1.0/128 as internal_object_mb,
SUM(version_store_reserved_page_count)*1.0/128 as version_store_mb
FROM sys.dm_db_file_space_usage;
GO

SELECT * 
FROM sys.dm_db_session_space_usage
WHERE session_id = @@SPID;
GO

SELECT 
    tsu.*,
    DB_NAME(er.database_id) as db,
    er.cpu_time, er.reads, er.writes, er.row_count, 
    eqp.query_plan
FROM sys.dm_db_task_space_usage tsu
JOIN sys.dm_exec_requests er 
    ON tsu.session_id = er.session_id AND 
       tsu.request_id = er.request_id
CROSS APPLY sys.dm_exec_query_plan(er.plan_handle) eqp;
GO

-- changer l'emplacement de tempdb
ALTER DATABASE tempdb MODIFY FILE (name = tempdev, filename = 'E:\Sqldata\tempdb.mdf')
GO
ALTER DATABASE tempdb MODIFY FILE (name = templog, filename = 'E:\Sqldata\templog.ldf')
GO


