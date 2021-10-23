EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

EXEC sp_configure 'affinity mask';
EXEC sp_configure 'max degree of parallelism';
EXEC sp_configure 'cost threshold for parallelism';

-- maxdop
EXEC sp_configure 'max degree of parallelism', 2;

SELECT c.LastName, c.FirstName, e.Title
FROM HumanResources.Employee AS e 
JOIN Person.Contact AS c ON e.ContactID = c.ContactID
OPTION (MAXDOP 2);

-- attentes
SELECT 
    SUM(signal_wait_time_ms) as signal_wait_time_ms,
    CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms)
        AS NUMERIC(20,2)) as [%signal (cpu) waits],
    SUM(wait_time_ms - signal_wait_time_ms) as resource_wait_time_ms,
    CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / 
        SUM (wait_time_ms) AS NUMERIC(20,2)) as [%resource waits]
FROM sys.dm_os_wait_stats;

-- types d'attentes
SELECT wait_type, (wait_time_ms * .001) as wait_time_seconds 
FROM sys.dm_os_wait_stats 
GROUP BY wait_type, wait_time_ms
ORDER BY wait_time_ms DESC;

-- par ordonnanceur
SELECT scheduler_id, current_tasks_count, runnable_tasks_count
FROM sys.dm_os_schedulers
WHERE scheduler_id < 255;

