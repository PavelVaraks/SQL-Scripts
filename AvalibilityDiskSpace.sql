declare @subject nvarchar(100)
declare @msg nvarchar(100)
declare @DiskName nvarchar(5)
	create table #SpaceFree
(Drive nvarchar(255),
 AvailableSpace nvarchar(255),
 AvailableInPercent nvarchar(255)
)
insert into #SpaceFree
SELECT DISTINCT
			s.volume_mount_point [Drive],
			'FreeSpace' =case 
			WHEN (s.available_bytes / 1099511627776) > 1
			THEN CAST(CAST(s.available_bytes / 1099511627776 as decimal(6,2)) AS Varchar(14)) + ' TB'
			WHEN (s.available_bytes / 1073741824) > 1
			THEN CAST(CAST(s.available_bytes / 1073741824 as decimal(6,1)) AS Varchar(14)) + ' GB' 
			Else ''
			END
			,(available_bytes/1024/1024)/((total_bytes/1024/1024)/100) as 'Свободно %'
		FROM 
			sys.master_files f
			CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) s
CREATE TABLE #SpaceFreeC (
	drive char,
	[free] int
)
insert into #SpaceFreeC
EXEC master..xp_fixeddrives
IF
 (select count(*) from #SpaceFree
 where AvailableInPercent between 20 and 10 ) > 0
 Begin
 print 'НадоОтправитьWarning место осталось меньше 20%'
Set @DiskName = (select top 1 Drive from #SpaceFree)
Set @subject= '[WARNING] Free Disk space for drive '+@DiskName+' is less < 20% on Windows Server ' + '"'+ (select convert(nvarchar(200), SERVERPROPERTY('ServerName'),2))+'"'
Set @msg= '[WARNING] Free Disk space for drive '+@DiskName+' is less < 20% on Windows Server ' + '"'+ (select convert(nvarchar(200), SERVERPROPERTY('ServerName'),2))+'"'
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = 'AlertSystem',
@recipients = 'p.varaks@fcod.nalog.ru',
@subject = @Subject,
@body = @msg,
@body_format = 'HTML'
 END
--Алерт, диск меньше 10%
 IF
  (select count(*) from #SpaceFree
 where AvailableInPercent < 10) > 0 
Begin
 print 'НадоОтправитьWarning место осталось меньше 10%'
Set @DiskName = (select top 1 Drive from #SpaceFree)
Set @subject= '[CRITICAL] Free Disk space for drive '+@DiskName+' is less < 10% on Windows Server ' + '"'+ (select convert(nvarchar(200), SERVERPROPERTY('ServerName'),2))+'"'
Set @msg= '[CRITICAL] Free Disk space for drive '+@DiskName+' is less < 10% on Windows Server ' + '"'+ (select convert(nvarchar(200), SERVERPROPERTY('ServerName'),2))+'"'
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = 'AlertSystem',
@recipients = 'p.varaks@fcod.nalog.ru',
@subject = @Subject,
@body = @msg,
@body_format = 'HTML'
END
 
--ОтправкаАлертаМестоНаДиске"C"Меньше 5GB
   IF
(Select count(*) from #SpaceFreeC
 where free < 5 * 1024
 and drive ='C') > 0
 Begin
Set @subject= '[WARNING] Free Disk space for drive "C" is less < 5GB on Windows Server ' + '"'+ (select convert(nvarchar(200), SERVERPROPERTY('ServerName'),2))+'"'
Set @msg= '[WARNING] Free Disk space for drive "C" is less < 5GB on Windows Server ' + '"'+ (select convert(nvarchar(200), SERVERPROPERTY('ServerName'),2))+'"'
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = 'AlertSystem',
@recipients = 'p.varaks@fcod.nalog.ru',
@subject = @Subject,
@body = @msg,
@body_format = 'HTML'
END
Else
Print 'Всё Ок''эй'
drop table #spaceFree	
drop table #SpaceFreeC
