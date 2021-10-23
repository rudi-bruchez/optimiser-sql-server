SELECT object_name(s.object_id) as tbl, 
       i.name as idx, 
       range_scan_count + singleton_lookup_count as [pages lues],
       leaf_insert_count+leaf_update_count+ leaf_delete_count 
         as [écritures sur noeud feuille],
       leaf_allocation_count as [page splits sur noeud feuille],
       nonleaf_insert_count + nonleaf_update_count + 
         nonleaf_delete_count as [écritures sur noeuds intermédiaires],
       nonleaf_allocation_count 
         as [page splits sur noeuds intermédiaires]
FROM sys.dm_db_index_operational_stats (DB_ID(),NULL,NULL,NULL) s
JOIN sys.indexes i 
       ON i.object_id = s.object_id and i.index_id = s.index_id
WHERE objectproperty(s.object_id,'IsUserTable') = 1
ORDER BY [pages lues] DESC;
GO

-- index manquants
SELECT object_name(object_id) as objet, d.*, s.*
FROM sys.dm_db_missing_index_details d 
INNER JOIN sys.dm_db_missing_index_groups g
    ON d.index_handle = g.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats s
    ON g.index_group_handle = s.group_handle
WHERE database_id = db_id()
ORDER BY s.user_seeks DESC, object_id;
GO

SELECT	
    'CREATE INDEX nix$' + lower(object_name(object_id)) + '$' 
    + REPLACE(REPLACE(REPLACE(COALESCE(equality_columns, 
      inequality_columns), ']', ''), '[', ''), ', ', '_')
    + ' ON ' + statement + ' (' + COALESCE(equality_columns,
      inequality_columns) + ') INCLUDE (' + included_columns + ')',
    object_name(object_id) as objet, d.*, s.*
FROM sys.dm_db_missing_index_details d 
JOIN sys.dm_db_missing_index_groups g
    ON d.index_handle = g.index_handle
JOIN sys.dm_db_missing_index_group_stats s
    ON g.index_group_handle = s.group_handle
WHERE database_id = db_id()
ORDER BY s.user_seeks DESC, objet;
GO
