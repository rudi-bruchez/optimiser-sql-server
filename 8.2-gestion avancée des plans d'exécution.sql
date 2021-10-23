-- forcer un algorithme de jointure... à éviter !
SELECT * 
FROM Sales.Customer c
JOIN Sales.CustomerAddress ca
	ON c.CustomerID = ca.CustomerID
WHERE TerritoryID = 5
OPTION (MERGE JOIN);
GO

-- indicateur de niveau d'isolation
SELECT FirstName, LastName
FROM Person.Contact WITH (READUNCOMMITTED);

-- readpast
CREATE TABLE dbo.ReadPast (nombre int not null)

INSERT INTO dbo.ReadPast (nombre) VALUES (1)
INSERT INTO dbo.ReadPast (nombre) VALUES (2)
INSERT INTO dbo.ReadPast (nombre) VALUES (3)
INSERT INTO dbo.ReadPast (nombre) VALUES (4)
INSERT INTO dbo.ReadPast (nombre) VALUES (5)

BEGIN TRAN
UPDATE dbo.ReadPast SET nombre = -nombre
WHERE nombre = 3

-- dans une autre session
SELECT * 
FROM dbo.ReadPast WITH (READPAST)
GO

---------------------
-- guides de plans --
---------------------
CREATE PROCEDURE dbo.GetContactsForPlanGuide
   @LastName nvarchar(50) = NULL
AS BEGIN
   SET NOCOUNT ON

   SELECT FirstName, LastName
   FROM Person.Contact
   WHERE LastName LIKE @LastName;
END
GO

EXEC dbo.GetContactsForPlanGuide 'Abercrombie'

EXEC dbo.GetContactsForPlanGuide '%'
-- pas bon
GO

EXEC sys.sp_create_plan_guide 
   @name = N'Guide$GetContactsForPlanGuide$OptimizeForAll',
   @stmt = N'SELECT FirstName, LastName
             FROM Person.Contact
             WHERE LastName LIKE @LastName',
   @type = N'OBJECT',
   @module_or_batch = N'dbo.GetContactsForPlanGuide',
   @params = NULL,
   @hints = N'OPTION (OPTIMIZE FOR (@LastName = ''%''))'

EXEC dbo.GetContactsForPlanGuide '%'
-- mieux !
GO
-- suppression
SELECT * FROM sys.plan_guides
EXEC sys.sp_control_plan_guide
   @Operation = N'DROP',
   @Name = N'Guide$GetContactsForPlanGuide$OptimizeForAll' 
GO
