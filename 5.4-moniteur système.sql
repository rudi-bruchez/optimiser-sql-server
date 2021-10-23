-- dm_db_index_physical_stats
SELECT 
    OBJECT_NAME(object_id) as ObjectName, index_type_desc, 
    record_count, forwarded_record_count, 
    (forwarded_record_count / record_count)*100 as 
        forwarded_record_ratio
FROM sys.dm_db_index_physical_stats(
    DB_ID('AdventureWorks'), 
    NULL, NULL, NULL, DEFAULT)
WHERE forwarded_record_count IS NOT NULL;
GO

SELECT max_workers_count
FROM sys.dm_os_sys_info;
GO

-- lightweight pooling
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'lightweight pooling', 1;
RECONFIGURE;
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;
GO

-- lecture de compteurs
SELECT instance_name,
	cntr_value as LogFileUsedSize
FROM sys.dm_os_performance_counters 
WHERE counter_name = 'Log File(s) Used Size (KB)';
GO
