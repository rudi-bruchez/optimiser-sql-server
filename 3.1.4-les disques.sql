SELECT
    vf.database_id,  
    vf.file_id,  
    vf.io_stall, 
    pio.io_pending_ms_ticks
FROM sys.dm_io_virtual_file_stats(NULL, NULL) vf
JOIN sys.dm_io_pending_io_requests pio 
ON vf.file_handle = pio.io_handle;

SELECT 
    UPPER(LEFT(mf.physical_name, 2)) as disk,  
    DB_NAME(vf.database_id) as db,  
    mf.name as file_name,
    vf.io_stall,
    vf.io_stall_read_ms,
    vf.io_stall_write_ms
FROM sys.dm_io_virtual_file_stats(NULL, NULL) vf
JOIN sys.master_files mf 
    ON vf.database_id = mf.database_id AND vf.file_id = mf.file_id
ORDER BY disk, db, file_name;
