-- partitionnement manuel
BEGIN TRANSACTION
BEGIN TRY
    SELECT *
    INTO Sales.SalesOrderHeader_Archive2002
    FROM Sales.SalesOrderHeader
    WHERE YEAR(OrderDate) = 2002

    DELETE
    FROM Sales.SalesOrderHeader
    WHERE YEAR(OrderDate) = 2002
	
    COMMIT TRANSACTION	
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
END CATCH
GO

BEGIN TRANSACTION
BEGIN TRY
    SELECT 
        0 as SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate
    INTO Sales.SalesOrderHeader_Archive2002
    FROM Sales.SalesOrderHeader
    WHERE 1 = 21

    DELETE
    FROM Sales.SalesOrderHeader
    OUTPUT DELETED.SalesOrderID, DELETED.RevisionNumber, 
        DELETED.OrderDate, DELETED.DueDate, DELETED.ShipDate 
        INTO Sales.SalesOrderHeader_Archive2002
    WHERE YEAR(OrderDate) = 2002
	
    COMMIT TRANSACTION	
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
END CATCH
GO

CREATE VIEW Sales.vSalesOrderHeaderWithArchives
AS 
    SELECT 
        SalesOrderID, RevisionNumber, OrderDate, DueDate, 
        ShipDate, 0 as Source
    FROM Sales.SalesOrderHeader
    UNION ALL
    SELECT 
        SalesOrderID, RevisionNumber, OrderDate, DueDate, 
        ShipDate, 2002 as Source
    FROM Sales.SalesOrderHeader_Archive2002
GO

SET STATISTICS IO ON
GO
SELECT * 
FROM Sales.vSalesOrderHeaderWithArchives
WHERE OrderDate BETWEEN '20020301' AND '20020401';
GO

ALTER TABLE Sales.SalesOrderHeader
WITH CHECK ADD CONSTRAINT chk$SalesOrderHeader$OrderDate CHECK (OrderDate NOT BETWEEN '20020101' AND '20021231 23:59:59.997');
GO
ALTER TABLE Sales.SalesOrderHeader_Archive2002
WITH CHECK ADD CONSTRAINT chk$SalesOrderHeader_Archive2002$OrderDate CHECK (OrderDate BETWEEN '20020101' AND '20021231 23:59:59.997');
GO

-- Partitionnement intégré
USE Master;

ALTER DATABASE AdventureWorks ADD FILEGROUP fg1;
ALTER DATABASE AdventureWorks ADD FILEGROUP fg2;
ALTER DATABASE AdventureWorks ADD FILEGROUP fg3;
GO
ALTER DATABASE AdventureWorks 
ADD FILE 
( NAME = data1,
  FILENAME = 'c:\temp\AdventureWorksd1.ndf',
  SIZE = 1MB, maxsize = 100MB, FILEGROWTH = 1MB)
TO FILEGROUP fg1;

ALTER DATABASE AdventureWorks
ADD FILE 
( NAME = data2,
  FILENAME = 'c:\temp\AdventureWorksd2.ndf',
  SIZE = 1MB, maxsize = 100MB, FILEGROWTH = 1MB)
TO FILEGROUP fg2;

ALTER DATABASE AdventureWorks
ADD FILE 
( NAME = data3,
  FILENAME = 'c:\temp\AdventureWorksd3.ndf',
  SIZE = 1MB, maxsize = 100MB, FILEGROWTH = 1MB)
TO FILEGROUP fg3;
GO

USE AdventureWorks;
GO
CREATE PARTITION FUNCTION pfOrderDate (datetime)
AS RANGE RIGHT
FOR VALUES ('20020101', '20030101');
GO

SELECT pf.name, pf.type_desc, pf.boundary_value_on_right, rv.boundary_id, rv.value, pf.create_date 
FROM sys.partition_functions pf
JOIN sys.partition_range_values rv ON pf.function_id = rv.function_id
ORDER BY rv.value;
GO

CREATE PARTITION SCHEME psOrderDate
AS PARTITION pfOrderDate 
TO (fg1, fg2, fg3);
GO

CREATE TABLE [Sales].[SalesOrderHeader_Partitionne](
	[SalesOrderID] [int] IDENTITY(1,1) NOT NULL,
	[RevisionNumber] [tinyint] NOT NULL,
	[OrderDate] [datetime] NOT NULL,
	[DueDate] [datetime] NOT NULL,
	[ShipDate] [datetime] NULL,
	[Status] [tinyint] NOT NULL,
	[OnlineOrderFlag] [bit] NOT NULL,
	[SalesOrderNumber]  AS (isnull(N'SO'+CONVERT([nvarchar](23),[SalesOrderID],(0)),N'*** ERROR ***')),
	[PurchaseOrderNumber] [dbo].[OrderNumber] NULL,
	[AccountNumber] [dbo].[AccountNumber] NULL,
	[CustomerID] [int] NOT NULL,
	[ContactID] [int] NOT NULL,
	[SalesPersonID] [int] NULL,
	[TerritoryID] [int] NULL,
	[BillToAddressID] [int] NOT NULL,
	[ShipToAddressID] [int] NOT NULL,
	[ShipMethodID] [int] NOT NULL,
	[CreditCardID] [int] NULL,
	[CreditCardApprovalCode] [varchar](15) NULL,
	[CurrencyRateID] [int] NULL,
	[SubTotal] [money] NOT NULL,
	[TaxAmt] [money] NOT NULL,
	[Freight] [money] NOT NULL,
	[TotalDue]  AS (isnull(([SubTotal]+[TaxAmt])+[Freight],(0))),
	[Comment] [nvarchar](128) NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_SalesOrderHeader_Partitionne_SalesOrderID] PRIMARY KEY NONCLUSTERED 
(
	[SalesOrderID] ASC
) ON psOrderDate(OrderDate)
) ON psOrderDate(OrderDate)
GO

INSERT INTO Sales.SalesOrderHeader_Partitionne
(    RevisionNumber, OrderDate, DueDate, ShipDate, Status, 
     OnlineOrderFlag, PurchaseOrderNumber,
     AccountNumber, CustomerID, ContactID, SalesPersonID, 
     TerritoryID, BillToAddressID,
     ShipToAddressID, ShipMethodID, CreditCardID, 
     CreditCardApprovalCode, CurrencyRateID,
     SubTotal, TaxAmt, Freight, Comment, rowguid, ModifiedDate
)
SELECT RevisionNumber, OrderDate, DueDate, ShipDate, 
    Status, OnlineOrderFlag, PurchaseOrderNumber,
    AccountNumber, CustomerID, ContactID, SalesPersonID, 
    TerritoryID, BillToAddressID,
    ShipToAddressID, ShipMethodID, CreditCardID, 
    CreditCardApprovalCode, CurrencyRateID,
    SubTotal, TaxAmt, Freight, Comment, rowguid, ModifiedDate
FROM Sales.SalesOrderHeader;
GO

SELECT	 object_name(object_id) AS Name,
       partition_id, 
       partition_number, 
       rows,
       allocation_unit_id, 
       type_desc,
       total_pages
FROM sys.partitions p JOIN sys.allocation_units a
   ON p.partition_id = a.container_id
WHERE object_id=object_id('Sales.SalesOrderHeader_Partitionne')
ORDER BY partition_number;
GO

SELECT 
	COUNT(*) as cnt,
	MAX(OrderDate) as MaxDate,
	MIN(OrderDate) as MinDate,
	$PARTITION.pfOrderDate(OrderDate) AS Partition
FROM Sales.SalesOrderHeader_Partitionne
GROUP BY $PARTITION.pfOrderDate(OrderDate)
ORDER BY Partition;
GO

ALTER TABLE Sales.SalesOrderHeader_Partitionne
SWITCH PARTITION 1
TO Sales.SalesOrderHeader_Old;
GO


