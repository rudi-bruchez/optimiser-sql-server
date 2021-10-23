-- configuration de l'attente de libération des verrous
SET LOCK_TIMEOUT 1000;
SELECT @@LOCK_TIMEOUT as lock_timeout;
GO

----------------------
-- dm_os_wait_stats --
----------------------

-- on remet les compteurs à zéro
dbcc sqlperf('sys.dm_os_wait_stats', clear)


-- dans la session 1
BEGIN TRAN

UPDATE Sales.Currency
SET Name = 'Franc Francais'
WHERE CurrencyCode = 'EUR'

-- dans la session 2
BEGIN TRAN

SELECT * 
FROM Sales.Currency WITH (TABLOCK)
WHERE CurrencyCode = 'CHF'
GO

-- les pages verrouillées
DBCC TRACEON (3604)
DBCC PAGE (AdventureWorks, 1, 295, 0)
DBCC PAGE (AdventureWorks, 1, 2101, 0)
GO


