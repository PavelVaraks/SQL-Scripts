SELECT s.[name] +'.'+t.[name]  AS table_name
 ,i.NAME AS index_name
 ,index_type_desc
 ,ROUND(avg_fragmentation_in_percent,2) AS avg_fragmentation_in_percent
 ,record_count AS table_record_count
 FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED') ips
INNER JOIN sys.tables t on t.[object_id] = ips.[object_id]
INNER JOIN sys.schemas s on t.[schema_id] = s.[schema_id]
INNER JOIN sys.indexes i ON (ips.object_id = i.object_id) AND (ips.index_id = i.index_id)
 where avg_fragmentation_in_percent > 5
ORDER BY avg_fragmentation_in_percent DESC




declare crs cursor local fast_forward for
select name from sys.databases
where database_id > 4
declare @cmd nvarchar(max), @db sysname
open crs
while 1=1
begin
    fetch next from crs into @db
    if @@FETCH_STATUS != 0 break
    set @cmd = 'use ['+@db+'];
SELECT s.[name] +''.''+t.[name]  AS table_name
 ,i.NAME AS index_name
 ,index_type_desc
 ,ROUND(avg_fragmentation_in_percent,2) AS avg_fragmentation_in_percent
 ,record_count AS table_record_count
 FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, ''SAMPLED'') ips
INNER JOIN sys.tables t on t.[object_id] = ips.[object_id]
INNER JOIN sys.schemas s on t.[schema_id] = s.[schema_id]
INNER JOIN sys.indexes i ON (ips.object_id = i.object_id) AND (ips.index_id = i.index_id)
 --where avg_fragmentation_in_percent > 30
ORDER BY avg_fragmentation_in_percent DESC
'
print @cmd
exec (@cmd)
END
close crs
deallocate crs