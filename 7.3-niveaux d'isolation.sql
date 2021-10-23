----------------------
-- read uncommitted --
----------------------
SELECT * FROM Person.Contact WITH (READUNCOMMITTED);
-- ou
SELECT * FROM Person.Contact WITH (NOLOCK);
GO

---------------------
-- repeatable read --
---------------------
USE AdventureWorks
GO

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ

BEGIN TRAN

SELECT TOP 10 * FROM Sales.Currency
GO

------------------
-- serializable --
------------------
USE tempdb
GO

CREATE TABLE dbo.testSerializable 
    (nombre int, texte varchar(50) COLLATE French_BIN)
GO

INSERT INTO dbo.testSerializable VALUES (1, 'un')
INSERT INTO dbo.testSerializable VALUES (2, 'deux')
INSERT INTO dbo.testSerializable VALUES (3, 'trois')
INSERT INTO dbo.testSerializable VALUES (4, 'quatre')
GO

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

BEGIN TRAN

-- sans index
UPDATE dbo.testSerializable
SET texte = 'DEUX'
WHERE nombre = 2

-- requête sur sys.dm_tran_locks

ROLLBACK
GO

CREATE NONCLUSTERED INDEX nix$testSerializable$nombre
ON dbo.testSerializable (nombre)
GO

BEGIN TRAN

-- avec index
UPDATE dbo.testSerializable
SET texte = 'DEUX'
WHERE nombre = 2

-- requête sur sys.dm_tran_locks

ROLLBACK
GO

--------------
-- snapshot --
--------------
ALTER DATABASE sandbox SET ALLOW_SNAPSHOT_ISOLATION ON 
GO

USE sandbox;
GO

CREATE TABLE dbo.testSnapshot
    (nombre int, texte varchar(50) COLLATE French_BIN);
GO

INSERT INTO dbo.testSnapshot VALUES (1, 'un');
INSERT INTO dbo.testSnapshot VALUES (2, 'deux');
INSERT INTO dbo.testSnapshot VALUES (3, 'trois');
INSERT INTO dbo.testSnapshot VALUES (4, 'quatre');
GO

-- session 1
BEGIN TRAN;

UPDATE dbo.testSnapshot
SET texte = 'DEUX'
WHERE nombre = 2;

-- session 2
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
GO

-- une lecture génère une version
SELECT *
FROM dbo.testSnapshot
WHERE nombre = 2;
GO

SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

BEGIN TRAN;

SELECT *
FROM dbo.testSnapshot
WHERE nombre = 2;

SELECT session_id, transaction_id, elapsed_time_seconds
FROM sys.dm_tran_active_snapshot_database_transactions;

ROLLBACK;

---------------------------------------
-- quel est mon niveau d'isolation ? --
---------------------------------------
CREATE TABLE #setoption (so varchar(64), val varchar(64))

INSERT INTO #setoption (so, val)
EXEC ('DBCC USEROPTIONS')

SELECT val
FROM #setoption
WHERE so = 'isolation level'
GO

-- dans la session
SELECT transaction_isolation_level,
   CASE transaction_isolation_level
      WHEN 0 THEN 'Unspecified'
      WHEN 1 THEN 'ReadUncommitted'
      WHEN 2 THEN 'Readcommitted'
      WHEN 3 THEN 'Repeatable'
      WHEN 4 THEN 'Serializable'
      WHEN 5 THEN 'Snapshot' 
   END AS isolation_level_description
FROM sys.dm_exec_sessions
WHERE session_id = @@SPID

