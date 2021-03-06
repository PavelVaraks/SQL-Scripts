USE [msdb]
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[monitoring]' AND category_class=1)
EXEC msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[monitoring]'
if exists(select * from msdb.dbo.sysjobs where name = 'CheckAvailabilitySpace')
exec msdb.dbo.sp_delete_job @job_name = 'CheckAvailabilitySpace'
GO
DECLARE @jobId BINARY(16)
EXEC msdb.dbo.sp_add_job @job_name=N'CheckAvailabilitySpace', 
@enabled=1, 
@notify_level_eventlog=0, 
@notify_level_email=2, 
@notify_level_page=2, 
@delete_level=0, 
@category_name=N'[monitoring]', 
@owner_login_name=N'sa', 
@notify_email_operator_name=N'AlertSql', @job_id = @jobId OUTPUT
select @jobId
GO
declare @srvName nvarchar(200)
set @srvName = convert(nvarchar,SERVERPROPERTY('servername'),2)
EXEC msdb.dbo.sp_add_jobserver @job_name=N'CheckAvailabilitySpace', @server_name = @srvName
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'CheckAvailabilitySpace', @step_name=N'CheckAvailabilitySpace', 
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
declare @totalSpace nvarchar(255)
declare @FreeSpace nvarchar(255)
declare @AvailableInPercent nvarchar(255)
create table #SpaceFree
(Drive nvarchar(255),
TotalSpace nvarchar(255),
AvailableSpace nvarchar(255),
AvailableInPercent nvarchar(255)
)
insert into #SpaceFree
SELECT DISTINCT vs.volume_mount_point
,CONVERT(int,vs.total_bytes/1073741824.0) AS [Total Size (GB)]
,CONVERT(int, vs.available_bytes/1073741824.0) AS [Available Size (GB)]
,CONVERT(int, vs.available_bytes * 1. / vs.total_bytes * 100.) AS [Space Free %]
FROM sys.master_files AS f WITH (NOLOCK)
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs 
ORDER BY vs.volume_mount_point OPTION (RECOMPILE);
CREATE TABLE #SpaceFreeC (
drive char,
[free] int
)
insert into #SpaceFreeC
EXEC master..xp_fixeddrives
IF
(select count(*) from #SpaceFree
where AvailableInPercent between 15 and 20 ) > 0
Begin
set @totalSpace = (select TotalSpace from #SpaceFree where AvailableInPercent between 15 and 20 )
Set @DiskName = (select Drive from #SpaceFree where AvailableInPercent between 15 and 20 )
Set @AvailableInPercent = (select AvailableInPercent from #SpaceFree where AvailableInPercent between 15 and 20 )
set @FreeSpace= (select AvailableSpace from #SpaceFree where AvailableInPercent between 15 and 20 )
Set @subject= ''[WARNING] Free Disk space for drive ''+@DiskName+'' is less 20% on Windows Server '' + ''"''+ (select convert(nvarchar(200), SERVERPROPERTY(''ServerName''),2))+''"''
Set @msg= ''TotalSpace= ''+@totalSpace+''. FreeSpace ''+@FreeSpace+ ''. In percent ''+ @AvailableInPercent + ''%''
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = ''AlertSystem'',
@recipients = ''dbashift@fcod.nalog.ru'',
@subject = @Subject,
@body = @msg,
@body_format = ''HTML''
END
--�����, ���� ������ 15%
IF
(select count(*) from #SpaceFree
where AvailableInPercent < 15) > 0 
Begin
set @totalSpace = (select TotalSpace from #SpaceFree where AvailableInPercent < 15 )
Set @DiskName = (select Drive from #SpaceFree where AvailableInPercent < 15)
Set @AvailableInPercent = (select AvailableInPercent from #SpaceFree where AvailableInPercent < 15)
set @FreeSpace= (select AvailableSpace from #SpaceFree where AvailableInPercent < 15)
Set @subject= ''[CRITICAL] Free Disk space for drive ''+@DiskName+'' is less 15% on Windows Server '' + ''"''+ (select convert(nvarchar(200), SERVERPROPERTY(''ServerName''),2))+''"''
Set @msg= ''TotalSpace= ''+@totalSpace+''. FreeSpace ''+@FreeSpace+ ''. In percent ''+ @AvailableInPercent + ''%''
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = ''AlertSystem'',
@recipients = ''dbashift@fcod.nalog.ru'',
@subject = @Subject,
@body = @msg,
@body_format = ''HTML''
END
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
Print ''Disk Space Is Enough''
drop table #spaceFree 
drop table #SpaceFreeC', 
@database_name=N'master', 
@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'CheckAvailabilitySpace', @step_name=N'Purge_job_history', 
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
,@job_name = ''CheckAvailabilitySpace''', 
@database_name=N'master', 
@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'CheckAvailabilitySpace', 
@enabled=1, 
@start_step_id=1, 
@notify_level_eventlog=0, 
@notify_level_email=2, 
@notify_level_page=2, 
@delete_level=0, 
@description=N'', 
@category_name=N'[monitoring]', 
@owner_login_name=N'sa', 
@notify_email_operator_name=N'AlertSql', 
@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'CheckAvailabilitySpace', @name=N'Every10Min', 
@enabled=1, 
@freq_type=4, 
@freq_interval=1, 
@freq_subday_type=4, 
@freq_subday_interval=10, 
@freq_relative_interval=0, 
@freq_recurrence_factor=1, 
@active_start_date=20180101, 
@active_end_date=99991231, 
@active_start_time=0, 
@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO