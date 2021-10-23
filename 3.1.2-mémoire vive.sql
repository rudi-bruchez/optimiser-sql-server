-- dm_os_sys_info
SELECT
    CASE
        WHEN virtual_memory_in_bytes / 1024 / (2048*1024) < 1 
        THEN 'Pas activé'
        ELSE '/3GB'
    END
FROM sys.dm_os_sys_info;

-- AWE
sp_configure 'show advanced options', 1;
RECONFIGURE;
sp_configure 'awe enabled', 1;
RECONFIGURE;

-- pression sur la mémoire
SELECT    
    Name,    
    Type,    
    single_pages_kb,    
    single_pages_kb / 1024 AS Single_Pages_MB,    
    entries_count
FROM sys.dm_os_memory_cache_counters
ORDER BY single_pages_kb DESC;


SELECT bpool_commit_target, bpool_committed FROM sys.dm_os_sys_info;
GO
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
GO

/* nous créons premièrement des instructions de 
   SELECT pour chaque table d'AdventureWorks */
SELECT 'SELECT * FROM [' + TABLE_CATALOG + '].[' + TABLE_SCHEMA + '].[' + TABLE_NAME + '];' 
FROM AdventureWorks.INFORMATION_SCHEMA.TABLES;

/* pages validées du buffer */
SELECT bpool_committed, bpool_commit_target FROM sys.dm_os_sys_info;

-- nous avons copié ici le résultat de la génération de code
SELECT * FROM [AdventureWorks].[Production].[ProductProductPhoto];
/* […]? */
SELECT * FROM [AdventureWorks].[Production].[ProductPhoto];
GO

-- pages validées du buffer
SELECT bpool_committed, bpool_commit_target FROM sys.dm_os_sys_info;
GO

-- vidons le buffer
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
GO

-- pages validées du buffer
SELECT bpool_committed, bpool_commit_target FROM sys.dm_os_sys_info;
GO

-- dm_os_buffer_descriptors
SELECT page_type, count(*) as page_count, SUM(row_count) as row_count 
FROM sys.dm_os_buffer_descriptors
WHERE database_id = DB_ID('AdventureWorks')
GROUP BY page_type
ORDER BY page_type;
GO

USE AdventureWorks;
GO
SELECT	 object_name(p.object_id) AS ObjectName, 
       bd.page_type, 
       count(*) as page_count, 
       SUM(row_count) as row_count, 
       SUM(CAST(bd.is_modified as int)) as modified_pages_count 
FROM	sys.dm_os_buffer_descriptors bd 
JOIN	sys.Allocation_units a 
      ON bd.allocation_unit_id = a.allocation_unit_id 
JOIN	sys.partitions p 
      ON p.partition_id = a.container_id 
WHERE	bd.database_id = DB_ID('AdventureWorks') AND 
      object_name(p.object_id) NOT LIKE 'sys%' 
GROUP BY object_name(p.object_id), bd.page_type 
ORDER BY ObjectName, page_type;
GO


