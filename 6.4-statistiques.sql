SELECT *
FROM Production.TransactionHistory
WHERE ProductId = 800;
GO

SELECT *
FROM sys.indexes i
WHERE OBJECT_NAME(i.object_id);
GO

SELECT c.name as ColumnName, s.name as IndexName
FROM sys.stats s
JOIN sys.stats_columns sc ON s.object_id = sc.object_id 
                          AND s.stats_id  = sc.stats_id
JOIN sys.columns c ON s.object_id = c.object_id 
                   AND sc.column_id = c.column_id
WHERE s.name = 'IX_TransactionHistory_ProductId';
GO

SELECT COUNT(*)
FROM Production.TransactionHistory
WHERE ProductId = 800;
GO

DBCC FREEPROCCACHE 
GO
SET SHOWPLAN_XML ON
GO
SELECT *
FROM Production.TransactionHistory
WHERE ProductId = 800
GO
SET SHOWPLAN_XML OFF
GO

SELECT ProductId, COUNT(*)
FROM Production.TransactionHistory
GROUP BY ProductId;
GO

DBCC FREEPROCCACHE 
GO
SET SHOWPLAN_XML ON
GO
SELECT *
FROM Production.TransactionHistory
WHERE ProductId = 760
GO
SET SHOWPLAN_XML OFF
GO

SELECT * FROM sys.stats WHERE auto_created = 1;
GO

SELECT statblob
FROM sys.sysindexes;
GO

DBCC SHOW_STATISTICS ( 'Production.TralinsactionHistory', 
    X_TransactionHistory_ProductID)
GO

SELECT 1.00 / COUNT(DISTINCT ProductId))
FROM Production.TransactionHistory
GO

SELECT 1.00 / COUNT(*)
FROM Production.TransactionHistory
GO

SELECT CAST(1.00 as float) / COUNT(*)
FROM Production.TransactionHistory
GO

SELECT o.name AS table_name,
       p.index_id, 
       i.name AS index_name, 
       au.type_desc AS allocation_type, 
       au.data_pages, partition_number
FROM 	sys.allocation_units AS au
JOIN 	sys.partitions AS p ON au.container_id = p.partition_id
JOIN 	sys.objects AS o ON p.object_id = o.object_id
LEFT JOIN sys.indexes AS i 	ON p.index_id = i.index_id 
                            AND i.object_id = p.object_id
WHERE 	o.name = N'TransactionHistory'
ORDER BY o.name, p.index_id
GO

SET STATISTICS IO ON
GO
SELECT *
FROM Production.TransactionHistory 
	WITH (INDEX = IX_TransactionHistory_ProductID)
WHERE ProductId = 800
GO

SELECT *
FROM Production.TransactionHistory
WHERE ProductId = 800
GO

DBCC IND (AdventureWorks, 'Production.TransactionHistory', 1)
GO

-- maintenance
SELECT *
FROM sys.stats s
JOIN sys.stats_columns sc ON s.object_id = sc.object_id 
                        AND  s.stats_id  = sc.stats_id
JOIN sys.columns c ON s.object_id = c.object_id 
                        AND  sc.column_id = c.column_id
GO

SELECT  OBJECT_NAME(i.object_id) AS table_name, 
        i.name AS index_name, 
        STATS_DATE(i.object_id, i.index_id)
FROM sys.indexes AS i
WHERE OBJECT_NAME(i.object_id) = N'TransactionHistory'
GO

-- mise à jour
SELECT DATABASEPROPERTYEX('IsAutoUpdateStatistics') 
    -- pour consulter la valeur actuelle
ALTER DATABASE AdventureWorks SET AUTO_UPDATE_STATISTICS [ON|OFF] 
    -- pour modifier la valeur
GO
