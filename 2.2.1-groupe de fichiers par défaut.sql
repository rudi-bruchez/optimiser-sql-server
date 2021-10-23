SELECT * 
FROM sys.filegroups
WHERE is_default = 1;
-- ou
SELECT FILEGROUPPROPERTY('PRIMARY', 'IsDefault')