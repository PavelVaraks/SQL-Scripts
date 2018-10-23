DECLARE @name VARCHAR(50) -- database name 
DECLARE @path VARCHAR(256) -- path for backup files 
DECLARE @fileName VARCHAR(256) -- filename for backup 
DECLARE @fileDate VARCHAR(50) -- used for file name
declare @srvname varchar(20) -- Servername
declare @servicename varchar(20) -- @@SERVICENAME
DECLARE @dirpath NVARCHAR(256) -- @path + @srvname + '\Full\' + @name 
DECLARE @datepath NVARCHAR(256) 
declare @PrimaryReplicas bit
Set @primaryReplicas = (SELECT top 1 is_primary_replica from sys.dm_hadr_database_replica_states where database_state is not null)

IF @PrimaryReplicas = 0
BEGIN
-- specify database backup directory
SET @path = 'C:\ClusterStorage\Backup\' 
select @servicename = @@SERVICENAME
select @srvname = REPLACE ( @@SERVERNAME, '\'+@servicename, '')
-- specify filename format
SELECT @fileDate = 'D' + CONVERT(VARCHAR(50),GETDATE(),105) + '_' +'T' + REPLACE(CONVERT(VARCHAR(50),GETDATE(),108),':','-')

SELECT @datepath = CONVERT(VARCHAR(50),GETDATE(),105)


DECLARE db_cursor CURSOR FOR 
SELECT name 
FROM master.dbo.sysdatabases 
WHERE name NOT IN ('master','model','msdb','tempdb') -- exclude these databases


OPEN db_cursor 
FETCH NEXT FROM db_cursor INTO @name 


WHILE @@FETCH_STATUS = 0 

BEGIN 
set @fileName = @path + @servicename +'\Secondary\' + @name + '\' + @name + '_' + @fileDate + '.BAK'
set @dirpath = @path + @servicename +'\Secondary\' + @name + '\'

EXECUTE master.dbo.xp_create_subdir @dirpath

BACKUP DATABASE @name TO DISK = @fileName WITH COMPRESSION, copy_only


FETCH NEXT FROM db_cursor INTO @name 
END 
CLOSE db_cursor 
DEALLOCATE db_cursor

end

Else
BEGIN
-- specify database backup directory
SET @path = 'C:\ClusterStorage\BackUp\' 
select @servicename = @@SERVICENAME
select @srvname = REPLACE ( @@SERVERNAME, '\'+@servicename, '')
-- specify filename format
SELECT @fileDate = 'D' + CONVERT(VARCHAR(50),GETDATE(),105) + '_' +'T' + REPLACE(CONVERT(VARCHAR(50),GETDATE(),108),':','-')

SELECT @datepath = CONVERT(VARCHAR(50),GETDATE(),105)


DECLARE db_cursor CURSOR FOR 
SELECT name 
FROM master.dbo.sysdatabases 
WHERE name NOT IN ('master','model','msdb','tempdb') -- exclude these databases


OPEN db_cursor 
FETCH NEXT FROM db_cursor INTO @name 
sys025_sql_a$
sys025_sql_c$


WHILE @@FETCH_STATUS = 0 

BEGIN 
set @fileName = @path + @servicename +'\Primary\' + @name + '\' + @name + '_' + @fileDate + '.BAK'
set @dirpath = @path + @servicename +'\Primary\' + @name + '\'

EXECUTE master.dbo.xp_create_subdir @dirpath

BACKUP DATABASE @name TO DISK = @fileName WITH COMPRESSION 


FETCH NEXT FROM db_cursor INTO @name 
END 


CLOSE db_cursor 
DEALLOCATE db_cursor
end