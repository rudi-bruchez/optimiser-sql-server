-- curseur
DECLARE cur CURSOR FAST_FORWARD
FOR SELECT ContactId FROM Person.Contact ORDER BY ContactId

DECLARE @CurrentContactID int
OPEN cur

FETCH NEXT FROM cur INTO @CurrentContactID
WHILE (@@fetch_status <> -1)
BEGIN
   IF (@@fetch_status <> -2)
      PRINT @CurrentContactID
	
   FETCH NEXT FROM cur INTO @CurrentContactID
END

CLOSE cur
DEALLOCATE cur
GO

-- boucle
DECLARE @CurrentContactID int
         
SELECT TOP 1 @CurrentContactID = ContactId
FROM  Person.Contact ORDER BY ContactId

WHILE 1 = 1 BEGIN
    PRINT @CurrentContactID
           
    SELECT TOP 1 @CurrentContactID = ContactID
    FROM  Person.Contact
    WHERE ContactID > @CurrentContactID

    IF @@ROWCOUNT = 0 BREAK

END -- WHILE
GO

-- concaténation
DECLARE @str VARCHAR(MAX)

SELECT @str = COALESCE(@str + ', ', '') + LastName
FROM Person.Contact
GROUP BY LastName
ORDER BY LastName

SELECT @str
GO

-- séparations et pivots
CREATE TABLE #citations (
    auteur varchar(50), 
    phrase varchar (1000)
)

INSERT INTO #citations
SELECT 'Guitry', 'Il y a des gens sur qui on peut compter. Ce sont généralement des gens dont on n''a pas besoin' UNION ALL
SELECT 'Cioran', 'Un homme ennuyeux est un homme incapable de s''ennuyer' UNION ALL
SELECT 'Talleyrand', 'Les mécontents, ce sont des pauvres qui réfléchissent'

SELECT auteur, 
    NullIf(SubString(' ' + phrase + ' ' , id , 
    CharIndex(' ' , ' ' + phrase + ' ' , id) - ID) , '') AS mot 
FROM (SELECT ROW_NUMBER() OVER (ORDER BY NEWID()) as id
FROM sys.system_views) tally
CROSS JOIN #citations
WHERE id <= Len(' ' + Phrase + ' ') AND SubString(' ' + Phrase + ' ' , id - 1, 1) = ' '
GO

SELECT
    th1.TransactionID,
    th1.ActualCost,
    SUM(th2.ActualCost) AS TotalCumule
FROM Production.TransactionHistory th1
JOIN Production.TransactionHistory th2 ON th2.TransactionID <= th1.TransactionID
    AND th2.TransactionDate = '20030901'
WHERE th1.TransactionDate = '20030901'
GROUP BY th1.TransactionID, th1.ActualCost
ORDER BY th1.TransactionID
GO

--Récursivité
WITH employeeCTE AS
(
    SELECT e.EmployeeId, c.FirstName, c.LastName, 1 as niveau,
        CAST(N'lui-même' as nvarchar(100)) as boss
    FROM HumanResources.Employee e
    JOIN Person.Contact c ON e.ContactID = c.ContactID
    WHERE e.ManagerID IS NULL

    UNION ALL

    SELECT e.EmployeeId, c.FirstName, c.LastName, niveau + 1,
        CAST(m.FirstName + ' ' + m.LastName as nvarchar(100))
    FROM HumanResources.Employee e
    JOIN Person.Contact c ON e.ContactID = c.ContactID
    JOIN employeeCTE m ON m.EmployeeId = e.ManagerId
)
SELECT FirstName, LastName, niveau, boss FROM EmployeeCTE;
GO

-- HierarchyID
SELECT o1.EmployeeName, o1.EmployeeID.GetLevel() as level, 
    o2.EmployeeName as boss 
FROM HumanResources.Organization o1
JOIN HumanResources.Organization o2 
    ON o2.EmployeeID = o1.EmployeeID.GetAncestor(1)
WHERE hierarchyid::GetRoot().IsDescendantOf(o1.EmployeeId)= 12

-- ... représentation intervallaire. http://sqlpro.developpez.com/cours/arborescence/.

--Mises à jour
CREATE TABLE dbo.testloop (
   id int NOT NULL IDENTITY (1,1) PRIMARY KEY CLUSTERED,
   nombre int NULL,
   groupe int NOT NULL
)
GO

INSERT INTO dbo.testloop (groupe)
SELECT TOP (10) 1 FROM sys.system_objects  UNION ALL
SELECT TOP (20) 2 FROM sys.system_objects  UNION ALL
SELECT TOP (15) 3 FROM sys.system_objects
GO

DECLARE @i int
SET @i = 0

UPDATE dbo.testloop
SET @i = @i + 1,
    nombre = @i
GO

SELECT * FROM dbo.testloop
GO

--à l'aide d'une expression de table :
WITH cteTestLoop AS (
   SELECT
      id,
      ROW_NUMBER() OVER(ORDER BY id) as rownumber
   FROM dbo.testloop
)
UPDATE tl
SET nombre = ctl.rownumber
FROM dbo.testloop tl
JOIN cteTestLoop ctl ON tl.id = ctl.id;
GO
