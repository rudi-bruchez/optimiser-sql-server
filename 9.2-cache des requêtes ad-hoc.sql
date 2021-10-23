SELECT    
    Name,    
    Type,    
    single_pages_kb,    
    single_pages_kb / 1024 AS Single_Pages_MB,    
    entries_count
FROM sys.dm_os_memory_cache_counters
WHERE type in ('CACHESTORE_SQLCP', 'CACHESTORE_OBJCP',
               'CACHESTORE_PHDR')
ORDER BY single_pages_kb DESC
GO

SELECT
    COUNT(*) as cnt,
    SUM(size_in_bytes) / 1024 as total_kb,
    MAX(usecounts) as max_usecounts,
    AVG(usecounts) as avg_usecounts,
    CASE GROUPING(cacheobjtype) 
        WHEN 1 THEN 'TOTAL' 
        ELSE cacheobjtype 
    END AS cacheobjtype,
    CASE GROUPING(objtype) 
        WHEN 1 THEN 'TOTAL' 
        ELSE objtype 
    END AS objtype
FROM sys.dm_exec_cached_plans
GROUP BY cacheobjtype, objtype
WITH ROLLUP
GO

SELECT *
FROM sys.dm_os_memory_objects 
WHERE type = 'MEMOBJ_SQLMGR'
GO

-- réutilisation des plans
SET CONCAT_NULL_YIELDS_NULL ON
GO
SELECT TOP 10 FirstName + ' ' + MiddleName + ' ' + LastName
FROM Person.Contact
GO

SET CONCAT_NULL_YIELDS_NULL OFF
GO
SELECT TOP 10 FirstName + ' ' + MiddleName + ' ' + LastName
FROM Person.Contact
GO

CREATE TABLE dbo.test (TestId int)
GO
ALTER USER isabelle WITH DEFAULT_SCHEMA = Person
ALTER USER paul WITH DEFAULT_SCHEMA = HumanResources
GO
CREATE TABLE dbo.test (TestId int)
GO
GRANT SELECT ON dbo.test TO paul
GRANT SELECT ON dbo.test TO isabelle
GO

EXECUTE AS USER = 'paul'
SELECT CURRENT_USER
GO
SELECT * FROM test
GO
REVERT
GO

EXECUTE AS USER = 'isabelle'
SELECT CURRENT_USER
GO
SELECT * FROM test
GO
REVERT
GO

SELECT st.text, qs.sql_handle, qs.plan_handle
FROM sys.dm_exec_query_stats qs 
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.sql_handle
GO

SELECT st.text, qs.sql_handle, qs.plan_handle, pa.attribute, pa.value
FROM sys.dm_exec_query_stats qs 
CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) st
OUTER APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa
WHERE qs.sql_handle = 0x020000002F5CC820E0CC946DD76094543CF7AA299904C81A
and pa.is_cache_key = 1
ORDER BY pa.attribute
GO

DBCC FREEPROCCACHE
GO

SET CONCAT_NULL_YIELDS_NULL ON
GO
SELECT TOP 10 FirstName + ' ' + MiddleName + ' ' + LastName
FROM Person.Contact
GO

SET CONCAT_NULL_YIELDS_NULL OFF
GO
SELECT TOP 10 FirstName + ' ' + MiddleName + ' ' + LastName
FROM Person.Contact
GO

-- plusieurs plan_handle pour le même sql_handle
SELECT
    cp.usecounts, 
    cp.size_in_bytes, 
    st.text
FROM sys.dm_exec_cached_plans cp
OUTER APPLY sys.dm_exec_sql_text (cp.plan_handle) st
JOIN sys.dm_exec_query_stats qs ON qs.plan_handle = cp.plan_handle
GO

-------------------------------
-- cache des requêtes ad-hoc --
-------------------------------
DBCC FREEPROCCACHE
GO
SELECT * FROM dbo.test
GO
SELECT * FROM  dbo.test
GO
SELECT * FROM dbo.TEST
GO
select * from dbo.test
GO
SELECT
    cp.usecounts, 
    cp.size_in_bytes, 
    st.text
FROM sys.dm_exec_cached_plans cp
OUTER APPLY sys.dm_exec_sql_text (cp.plan_handle) st
JOIN sys.dm_exec_query_stats qs ON qs.plan_handle = cp.plan_handle
GO

SELECT * FROM Person.Contact WHERE ContactId = 20
GO
SELECT * FROM Person.Contact WHERE ContactId = 40
GO

SELECT * FROM Person.Contact WHERE LastName = 'Allen'
GO
SELECT * FROM Person.Contact WHERE LastName = 'Ackerman'
GO

ALTER DATABASE AdventureWorks SET PARAMETERIZATION FORCED

-- pour revenir à l'état par défaut :
ALTER DATABASE AdventureWorks SET PARAMETERIZATION SIMPLE

-- SQL server 2008
EXEC sp_configure 'show advanced options',1
RECONFIGURE
EXEC sp_configure 'optimize for ad hoc workloads',1
RECONFIGURE

-- SQL dynamique paramétré
DBCC FREEPROCCACHE
GO
DECLARE @sql varchar(8000)

SET @sql = 'SELECT * FROM Person.Contact WHERE LastName = ''Allen'''
EXECUTE (@sql)
SET @sql = 'SELECT * FROM Person.Contact WHERE LastName = ''Ackerman'''
EXECUTE (@sql)
GO

DECLARE @sql nvarchar(4000)

SET @sql = 'SELECT * FROM Person.Contact WHERE LastName = @LastName'
EXECUTE sp_executesql @sql, N'@LastName NVARCHAR(80)', @LastName = 'Allen'
EXECUTE sp_executesql @sql, N'@LastName NVARCHAR(80)', @LastName = 'Ackerman'
GO

SELECT
	cp.usecounts, 
	cp.size_in_bytes, 
	st.text
FROM sys.dm_exec_cached_plans cp
OUTER APPLY sys.dm_exec_sql_text (cp.plan_handle) st
JOIN sys.dm_exec_query_stats qs ON qs.plan_handle = cp.plan_handle
GO

