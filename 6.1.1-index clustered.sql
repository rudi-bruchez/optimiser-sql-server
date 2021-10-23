USE tempdb
GO

CREATE TABLE dbo.indexdemo (
	id int NOT NULL, 
	texte char(100) NOT NULL 
		DEFAULT (REPLICATE(CHAR(CEILING(RAND()*100)), 100))
);
GO

INSERT INTO dbo.indexdemo (id) VALUES (1)
INSERT INTO dbo.indexdemo (id) VALUES (2)
INSERT INTO dbo.indexdemo (id) VALUES (3)
INSERT INTO dbo.indexdemo (id) VALUES (4)
INSERT INTO dbo.indexdemo (id) VALUES (5)
INSERT INTO dbo.indexdemo (id) VALUES (6)
INSERT INTO dbo.indexdemo (id) VALUES (7)
INSERT INTO dbo.indexdemo (id) VALUES (8)
GO

SELECT * FROM dbo.indexdemo
GO

DELETE FROM dbo.indexdemo WHERE id = 4
INSERT INTO dbo.indexdemo (id) VALUES (9)
GO
SELECT * FROM dbo.indexdemo
GO

SELECT * FROM dbo.indexdemo ORDER BY id; 
GO

CREATE NONCLUSTERED INDEX nix$dbo_indexdemo$id
ON dbo.indexdemo (id ASC);
GO

SELECT * FROM dbo.indexdemo ORDER BY id;
GO

DROP INDEX nix$dbo_indexdemo$id
ON dbo.indexdemo;
GO

CREATE CLUSTERED INDEX cix$dbo_indexdemo$id
ON dbo.indexdemo (id ASC);
GO

SELECT * FROM dbo.indexdemo;
GO

DBCC IND ('tempdb', 'dbo.indexdemo', 0);
DBCC IND ('tempdb', 'dbo.indexdemo', 1);
GO

DECLARE @i int
SELECT @i = MAX(id)+1 FROM dbo.indexdemo;

WHILE @i <= 2000 BEGIN
    INSERT INTO dbo.indexdemo (id) SELECT @i;
    SET @i = @i + 1
END	

ALTER TABLE dbo.indexdemo
ADD petittexte CHAR(1) NULL;
GO
UPDATE dbo.indexdemo
SET petittexte =  CHAR(ASCII('a')+(id%26))
GO

CREATE NONCLUSTERED INDEX nix$dbo_indexdemo$petittexte1
ON dbo.indexdemo (petittexte ASC);
GO

SELECT * FROM dbo.indexdemo WHERE petittexte = 'c';
GO

DBCC IND ('tempdb', 'dbo.indexdemo', 4)
GO

DBCC TRACEON (3604);
DBCC PAGE (tempdb, 1, 218, 3);
GO

SELECT 
    i.index_id, i.name, i.type_desc, 
    i.is_primary_key, fill_factor,
    INDEX_COL(OBJECT_NAME(i.object_id), i.index_id, ic.index_column_id) 
        as column_name
FROM sys.indexes i
JOIN sys.index_columns ic 
    ON  i.object_id = ic.object_id
    AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('dbo.indexdemo')
ORDER BY i.index_id, ic.key_ordinal;
GO
