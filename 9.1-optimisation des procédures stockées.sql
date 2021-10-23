-- done_in_proc
SET NOCOUNT ON

-- ou
EXEC sp_configure 'user options', 512
RECONFIGURE
GO

IF @@OPTIONS & 512 = 512
   PRINT 'SET NOCOUNT est à ON';
GO

-----------------
-- compilation --
-----------------

SELECT definition 
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('dbo.uspGetBillOfMaterials')
GO

SELECT OBJECT_DEFINITION(OBJECT_ID('sys.sql_modules'))
-- ou
SELECT definition FROM sys.system_sql_modules 
WHERE Object_Id = OBJECT_ID('sys.sql_modules')
GO

SELECT cp.usecounts, cp.size_in_bytes, st.text, 
    DB_NAME(st.dbid) as db, 
    OBJECT_SCHEMA_NAME(st.objectid, st.dbid) + '.' 
        + OBJECT_NAME(st.objectid, st.dbid) as object, 
    qp.query_plan, cp.cacheobjtype, cp.objtype
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
GO

-- dm_os_memory_cache_entries. Exemple de requête :
SELECT 	
    DB_NAME(st.dbid) as db, 
    OBJECT_SCHEMA_NAME(st.objectid, st.dbid) + '.' 
        + OBJECT_NAME(st.objectid, st.dbid) as object,
    cp.objtype, cp.usecounts, cp.size_in_bytes,
    ce.disk_ios_count, ce.context_switches_count,
    ce.pages_allocated_count, ce.original_cost, ce.current_cost
FROM sys.dm_exec_cached_plans cp
JOIN sys.dm_os_memory_cache_entries ce
    on cp.memory_object_address = ce.memory_object_address
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
GO

-- on vide les caches
CHECKPOINT
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
GO

SELECT DB_ID('AdventureWorks')
DBCC FLUSHPROCINDB (5)
GO

-------------------------
-- paramètres typiques --
-------------------------
--créons un index pour aider la recherche
CREATE NONCLUSTERED INDEX [nix$Person_Contact$LastName] 
ON [Person].[Contact] (LastName)
GO

-- 2 lignes à retourner
SELECT FirstName, LastName, EmailAddress
FROM Person.Contact
WHERE LastName LIKE 'Ackerman'

-- 911 lignes à retourner
SELECT FirstName, LastName, EmailAddress
FROM Person.Contact
WHERE LastName LIKE 'A%'
GO

CREATE PROCEDURE Person.GetContactByLastName
    @LastNameStart nvarchar(50)
AS BEGIN
    SET NOCOUNT ON

    SELECT FirstName, LastName, EmailAddress
    FROM Person.Contact
    WHERE LastName LIKE @LastNameStart
END
GO

EXEC Person.GetContactByLastName 'A%'
GO

SELECT cp.size_in_bytes, qp.query_plan
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
WHERE 
  st.dbid = DB_ID('Adventureworks') AND 
   st.objectid = OBJECT_ID('Adventureworks.Person.GetContactByLastName')
GO

-- procédure avec utilisation directe du paramètre
CREATE PROCEDURE dbo.GetContactsParameter
   @LastName nvarchar(50) = NULL
AS BEGIN
   SET NOCOUNT ON

   SELECT FirstName, LastName FROM Person.Contact
   WHERE LastName LIKE @LastName;
END
GO
-- procédure avec variable locale
CREATE PROCEDURE dbo.GetContactsLocalVariable
   @LastName nvarchar(50) = NULL
AS BEGIN
   SET NOCOUNT ON

   DECLARE @MyLastName nvarchar(50)
   SET @MyLastName = @LastName

   SELECT FirstName, LastName FROM Person.Contact
   WHERE LastName LIKE @MyLastName;
END
GO

-- utilisation
EXEC dbo.GetContactsParameter @LastName = 'Abercrombie'
GO
EXEC dbo.GetContactsLocalVariable @LastName = 'Abercrombie'
GO

EXEC dbo.GetContactsParameter @LastName = '%'
GO
EXEC dbo.GetContactsLocalVariable @LastName = '%'
GO

-----------------------------
-- forcer la recompilation --
-----------------------------
CREATE PROCEDURE dbo.GetContactsParameter
   @LastName nvarchar(50) = NULL
AS BEGIN
   SET NOCOUNT ON

   SELECT FirstName, LastName
   FROM Person.Contact
   WHERE LastName LIKE @LastName
   OPTION (RECOMPILE);
END
GO

SELECT FirstName, LastName
FROM Person.Contact
WHERE LastName LIKE @LastName
OPTION (OPTIMIZE FOR (@LastName = '%'));
GO

CREATE PROCEDURE Person.GetContactsByWhatever
    @NamePartType tinyint,
    @NamePart nvarchar(50)
AS BEGIN
    SET NOCOUNT ON

    IF (@NamePartType = 1)
        SELECT FirstName, LastName, EmailAddress
        FROM Person.Contact
        WHERE FirstName LIKE @NamePart
    ELSE IF (@NamePartType = 2)
        SELECT FirstName, LastName, EmailAddress
        FROM Person.Contact
        WHERE LastName LIKE @NamePart
    ELSE IF (@NamePartType = 3)
        SELECT FirstName, LastName, EmailAddress
        FROM Person.Contact
        WHERE EmailAddress LIKE @NamePart
END
GO

-- recompilation par utilisation de tables temporaires
ALTER PROC dbo.testtemptable
    @nbInserts smallint = 1
AS BEGIN
    DECLARE @i smallint
    SET @i = 1

    CREATE TABLE #t (
        id int identity(1,1) PRIMARY KEY NONCLUSTERED, 
        col char(8000) NOT NULL DEFAULT ('e'))

    WHILE @i <= @nbInserts BEGIN
        INSERT INTO #t DEFAULT VALUES
        SELECT * FROM #t WHERE col = 'e' OR id > 20
        SET @i = @i + 1
    END
END
GO

EXEC dbo.testtemptable
GO

-- keep plan
SELECT * FROM #t WHERE col = 'e' OR id > 20
OPTION (KEEP PLAN)
GO


