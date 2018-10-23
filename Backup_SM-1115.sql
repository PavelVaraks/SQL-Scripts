declare @command nvarchar(max)
set @command= 
'USE ?
IF DB_ID()> 4
BEGIN
declare @database nvarchar(100) 
set @database= DB_NAME()
declare @Path nvarchar(max)
declare @name nvarchar(100)
declare @servername nvarchar(100)
set @servername = convert(nvarchar(200), SERVERPROPERTY(''ServerName''),2)
set @name = @database +''-Full Database Backup''
set @Path = ''\\dpc.tax.nalog.ru\root\GRs\PK\gr015\''+@servername+''\SM-1115\''+@database+''.bak''
BACKUP DATABASE @database
TO  DISK =  @path
WITH  COPY_ONLY
,NOFORMAT
,NOINIT
,NAME = @name
,SKIP
,NOREWIND
,NOUNLOAD
,COMPRESSION
,buffercount = 16
,STATS = 5
END'
EXEC sp_MSforeachdb @command
