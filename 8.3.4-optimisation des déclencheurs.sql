-- un déclencheur erroné
CREATE TRIGGER atr_d$sales_currency$archive 
ON sales.currency
AFTER DELETE
AS BEGIN
   DECLARE @CurrencyCode NCHAR(3),
           @Name NVARCHAR(50),	
           @DeletedDate smalldatetime

   SELECT  @CurrencyCode = CurrencyCode,
           @Name = Name,
           @DeletedDate = CURRENT_TIMESTAMP
   FROM Deleted

   INSERT INTO sales.currencyArchive
      (CurrencyCode, Name, DeletedDate)
   VALUES
      (@CurrencyCode, @Name, @DeletedDate)
END
GO

-- déclenché même si :
DELETE FROM sales.currency WHERE CurrencyCode = 'FRF';
-- ou plus simplement :
DELETE FROM sales.currency WHERE 1 = 0;
GO

-- éviter que le déclencheur puisse renvoyer un résultat
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'disallow results from triggers', 1;
RECONFIGURE;
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;
GO

-- clause OUTPUT
DELETE FROM sales.currency2
OUTPUT deleted.CurrencyCode, deleted.Name, CURRENT_TIMESTAMP
INTO sales.currencyArchive;
GO

-- exemple de déclencheur
ALTER TRIGGER atr_iu$sales_CurrencyHistory$checkConsistency
ON sales.CurrencyHistory
FOR INSERT, UPDATE 
AS BEGIN
   IF @@ROWCOUNT = 0 RETURN
   SET NOCOUNT ON

   IF EXISTS (
      SELECT 1
      FROM sales.CurrencyHistory ch WITH (READUNCOMMITTED)
      JOIN inserted i 
         ON ch.CurrencyCode = i.CurrencyCode AND
            ch.fromDate <> i.fromDate
      WHERE
         ( ch.fromDate BETWEEN i.fromDate AND i.toDate OR
           ch.toDate   BETWEEN i.fromDate AND i.toDate ) OR
         ( i.fromDate  BETWEEN ch.fromDate AND ch.toDate OR
           i.toDate    BETWEEN ch.fromDate AND ch.toDate )
         ) 
   BEGIN
      RAISERROR ('Des dates d''historique se chevauchent !', 16, 10)
      RETURN
   END
END
GO
