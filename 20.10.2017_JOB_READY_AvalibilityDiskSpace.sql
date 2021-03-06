
declare @jobID nvarchar(255)
set @jobID = ( 


select job_id from msdb.dbo.sysjobs
where name='CheckDiskSpace'
)
EXEC msdb.dbo.sp_delete_job @job_id=@jobID, @delete_unused_schedule=1
GO


USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'CheckDiskSpace', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
select @jobId
GO
declare @servername nvarchar(255)
set @servername = convert(nvarchar(255),SERVERPROPERTY('servername'),2)
EXEC msdb.dbo.sp_add_jobserver @job_name=N'CheckDiskSpace', @server_name = @servername
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'CheckDiskSpace', @step_name=N'CheckDiskSpace', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @subject nvarchar(100)
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
			''FreeSpace'' =case 
			WHEN (s.available_bytes / 1099511627776) > 1
			THEN CAST(CAST(s.available_bytes / 1099511627776 as decimal(6,2)) AS Varchar(14)) + '' TB''
			WHEN (s.available_bytes / 1073741824) > 1
			THEN CAST(CAST(s.available_bytes / 1073741824 as decimal(6,1)) AS Varchar(14)) + '' GB'' 
			Else ''''
			END
			,(available_bytes/1024/1024)/((total_bytes/1024/1024)/100) as ''Свободно %''
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
 print ''НадоОтправитьWarning место осталось меньше 20%''
Set @DiskName = (select top 1 Drive from #SpaceFree)
Set @subject= ''[WARNING] Free Disk space for drive ''+@DiskName+'' is less < 20% on Windows Server '' + ''"''+ (select convert(nvarchar(200), SERVERPROPERTY(''ServerName''),2))+''"''
Set @msg= ''[WARNING] Free Disk space for drive ''+@DiskName+'' is less < 20% on Windows Server '' + ''"''+ (select convert(nvarchar(200), SERVERPROPERTY(''ServerName''),2))+''"''
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = ''AlertSystem'',
@recipients = ''dbashift@fcod.nalog.ru'',
@subject = @Subject,
@body = @msg,
@body_format = ''HTML''
 END
--Алерт, диск меньше 10%
 IF
  (select count(*) from #SpaceFree
 where AvailableInPercent < 10) > 0 
Begin
 print ''НадоОтправитьWarning место осталось меньше 10%''
Set @DiskName = (select top 1 Drive from #SpaceFree)
Set @subject= ''[CRITICAL] Free Disk space for drive ''+@DiskName+'' is less < 10% on Windows Server '' + ''"''+ (select convert(nvarchar(200), SERVERPROPERTY(''ServerName''),2))+''"''
Set @msg= ''[CRITICAL] Free Disk space for drive ''+@DiskName+'' is less < 10% on Windows Server '' + ''"''+ (select convert(nvarchar(200), SERVERPROPERTY(''ServerName''),2))+''"''
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = ''AlertSystem'',
@recipients = ''dbashift@fcod.nalog.ru'',
@subject = @Subject,
@body = @msg,
@body_format = ''HTML''
END
 
--ОтправкаАлертаМестоНаДиске"C"Меньше 5GB
   IF
(Select count(*) from #SpaceFreeC
 where free < 5 * 1024
 and drive =''C'') > 0
 Begin
Set @subject= ''[WARNING] Free Disk space for drive "C" is less < 5GB on Windows Server '' + ''"''+ (select convert(nvarchar(200), SERVERPROPERTY(''ServerName''),2))+''"''
Set @msg= ''[WARNING] Free Disk space for drive "C" is less < 5GB on Windows Server '' + ''"''+ (select convert(nvarchar(200), SERVERPROPERTY(''ServerName''),2))+''"''
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = ''AlertSystem'',
@recipients = ''dbashift@fcod.nalog.ru'',
@subject = @Subject,
@body = @msg,
@body_format = ''HTML''
END
Else
Print ''Всё Ок''''эй''
drop table #spaceFree	
drop table #SpaceFreeC
', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'CheckDiskSpace', @step_name=N'purge_job_history', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @twosec nvarchar(25)
set @twosec = (select GETDATE()-0.001)
EXEC msdb.dbo.sp_purge_jobhistory  
@oldest_date=@twosec
,@job_name = ''CheckDiskSpace''

', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'CheckDiskSpace', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'CheckDiskSpace', @name=N'Every5Min', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20171020, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
