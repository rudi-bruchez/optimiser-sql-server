CREATE DATABASE testdb
GO
ALTER DATABASE testdb SET RECOVERY SIMPLE
GO

USE testdb

CREATE TABLE dbo.testIndex (
    codeLong char(900) NOT NULL PRIMARY KEY NONCLUSTERED,
    codeCourt smallint NOT NULL,
    texte char(7150) NOT NULL DEFAULT ('O')
)
GO

DECLARE @v int
SET @v = 1
WHILE (@v <= 8000) BEGIN
    INSERT INTO dbo.testIndex (codeLong, codeCourt) 
    SELECT CAST(@v as char(10)), @v

    SET @v = @v + 1		
END
GO

CREATE UNIQUE INDEX uq$testIndex$codeCourt ON dbo.testIndex (codeCourt)

SELECT name, index_id, type_desc 
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.testIndex')

/* -- résultat
name                      index_id    type_desc
-------------------------- ----------- ------------
NULL                      0           HEAP
PK__testIndex__0425A276   2           NONCLUSTERED
uq$testIndex$codeCourt    3           NONCLUSTERED

*/

SELECT index_depth, index_level, page_count, record_count 
FROM sys.dm_db_index_physical_stats(
     DB_ID(), OBJECT_ID('dbo.testIndex'), 2, NULL, 'DETAILED') 

/* -- résultat
index_depth index_level page_count           record_count
----------- ----------- -------------------- --------------------
6           0           1441                 8000
6           1           321                  1441
6           2           72                   321
6           3           16                   72
6           4           3                    16
6           5           1                    3
*/

SELECT index_depth, index_level, page_count, record_count 
FROM sys.dm_db_index_physical_stats(
     DB_ID(), OBJECT_ID('dbo.testIndex'), 3, NULL, 'DETAILED') 

/* -- résultat
index_depth index_level page_count           record_count
----------- ----------- -------------------- --------------------
2           0           14                   8000
2           1           1                    14
*/
GO

SET STATISTICS IO ON

SELECT * FROM dbo.testIndex WHERE CodeLong = '49'
-- Table 'testIndex'. Scan count 0, logical reads 7
SELECT * FROM dbo.testIndex WHERE CodeCourt = 49
-- Table 'testIndex'. Scan count 0, logical reads 3
GO

SELECT * FROM dbo.testIndex WHERE CodeLong = '49';
GO

CREATE TABLE #ind (
    PageFID bigint,  
    PagePID bigint,
    IAMFID bigint,
    IAMPID bigint,
    ObjectID bigint,
    IndexID bigint,
    PartitionNumber bigint,
    PartitionID bigint,
    iam_chain_type varchar(20),
    PageType int,
    IndexLevel int,
    NextPageFID bigint,
    NextPagePID bigint,
    PrevPageFID bigint,
    PrevPagePID bigint
)
GO

INSERT INTO #ind
EXEC ('DBCC IND(''testdb'', ''dbo.testIndex'', 2)')

SELECT * FROM #ind WHERE IndexLevel = 5

-- comment résoudre cette requête avec un index
SET STATISTICS IO ON
SELECT * FROM dbo.testIndex WHERE code = '49'
/*
Table 'testIndex'. Scan count 0, logical reads 7
*/

DBCC TRACEON (3604);
GO

DBCC PAGE (testdb, 1, 8238, 3)
/*
FileId PageId      Row    Level  ChildFileId ChildPageId codeLong (key)
------ ----------- ------ ------ ----------- ----------- ----------
1      8238        0      5      1           4179        NULL      
1      8238        1      5      1           8239        253       
1      8238        2      5      1           1122        45        
*/
-- row, key 45, ChildPageId : 1122
DBCC PAGE (testdb, 1, 1122, 3)
/*
FileId PageId      Row    Level  ChildFileId ChildPageId codeLong (key)
------ ----------- ------ ------ ----------- ----------- ----------
1      1122        0      4      1           4180        45        
1      1122        1      4      1           9582        487       
1      1122        2      4      1           9121        55        
[...]
*/
-- row, key 487, ChildPageId : 9582
DBCC PAGE (testdb, 1, 9582, 3)
/*
FileId PageId      Row    Level  ChildFileId ChildPageId codeLong (key)
------ ----------- ------ ------ ----------- ----------- ----------
1      9582        0      3      1           9122        487       
1      9582        1      3      1           9207        495       
1      9582        2      3      1           9368        504       
[...]
*/
-- row, key 487, ChildPageId : 9122
DBCC PAGE (testdb, 1, 9122, 3)
/*
FileId PageId      Row    Level  ChildFileId ChildPageId codeLong (key)
------ ----------- ------ ------ ----------- ----------- ----------
1      9122        0      2      1           9039        487       
1      9122        1      2      1           9076        489       
1      9122        2      2      1           9123        491       
1      9122        3      2      1           9160        493       
*/
-- row, key 489, ChildPageId : 9076
DBCC PAGE (testdb, 1, 9076, 3)
/*
FileId PageId      Row    Level  ChildFileId ChildPageId codeLong (key)
------ ----------- ------ ------ ----------- ----------- ----------
1      9076        0      1      1           9073        489       
1      9076        1      1      1           9075        4897      
1      9076        2      1      1           3623        49        
1      9076        3      1      1           9079        4906
*/
-- row, key 49, ChildPageId : 3623
DBCC PAGE (testdb, 1, 3623, 3)
/*
FileId PageId      Row    Level  codeLong (key) HEAP RID           
------ ----------- ------ ------ ---------------------------------
1      3623        0      0      49             0x380C000001000000
1      3623        1      0      490            0x590E000001000000
1      3623        2      0      4900           0x8C23000001000000
[...]
*/
GO


