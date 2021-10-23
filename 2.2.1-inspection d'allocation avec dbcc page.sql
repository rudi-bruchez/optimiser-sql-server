DBCC TRACEON (3604);
GO

CREATE DATABASE testalloc;
GO
USE testalloc;

-- en-tête de fichier
DBCC PAGE (AdventureWorks, 1, 0, 3);
GO
-- page PFS
DBCC PAGE (AdventureWorks, 1, 1, 3);
GO
-- GAM
DBCC PAGE (AdventureWorks, 1, 2, 3);
GO
--SGAM
DBCC PAGE (testalloc, 1, 3, 3);
GO
-- DIFF
DBCC PAGE (testalloc, 1, 6, 3);
GO
-- ML
DBCC PAGE (testalloc, 1, 7, 3);
GO

CREATE TABLE #dbccpage (ParentObject sysname, Object sysname, Field sysname, Value sysname)
GO
INSERT INTO #dbccpage
EXEC ('DBCC PAGE (AdventureWorks, 1, 0, 3) WITH TABLERESULTS');
GO
SELECT * FROM #dbccpage
DBCC PAGE (AdventureWorks, 1, 652, 3) WITH TABLERESULTS;
GO

DBCC PAGE (AdventureWorks, 1, 652, 3)
SELECT OBJECT_NAME(402100473)
SELECT COUNT(*) FROM AdventureWorks.Purchasing.PurchaseOrderHeader -- ou AdventureWorks2008.Purchasing.PurchaseOrderHeader
DBCC PAGE (AdventureWorks, 1, 653, 3)
DBCC PAGE (AdventureWorks, 1, 8465, 3)
DBCC PAGE (AdventureWorks, 1, 8464, 3)

SELECT p.* 
FROM sys.allocation_units au
JOIN sys.partitions p ON au.container_id = p.partition_id
WHERE au.allocation_unit_id = 72057594052083712