-- DMV sys.dm_os_buffer_descriptors
SELECT * FROM sys.dm_os_buffer_descriptors WHERE is_modified = 1;

-- vues de gestion dynamique
SELECT * 
FROM sys.system_objects
WHERE name LIKE 'dm_%' ORDER BY name;

-- recovery interval
EXEC sp_configure 'show advanced option', '1';
RECONFIGURE;
EXEC sp_configure 'recovery interval', '3';
RECONFIGURE WITH OVERRIDE;
EXEC sp_configure 'show advanced option', '1';

-- contenu du journal de transactions
SELECT * FROM sys.fn_dblog(DB_ID(),NULL);

-- vider le journal
ALTER DATABASE AdventureWorks SET RECOVERY SIMPLE;
-- ou 
ALTER DATABASE AdventureWorks2008 SET RECOVERY SIMPLE;
GO
CHECKPOINT;
-- ou, pour SQL Server 2005
BACKUP LOG AdventureWorks WITH TRUNCATE_ONLY;

-- analysons le journal de transactions
UPDATE Sales.Currency
SET Name = Name
WHERE CurrencyCode = 'ALL'

UPDATE Sales.Currency
SET Name = 'Lek2'
WHERE CurrencyCode = 'ALL'

