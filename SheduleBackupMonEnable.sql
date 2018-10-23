create procedure SheduleBackupMonEnable
(@enabled bit)
as
declare @SCHEDULEID int
set @SCHEDULEID = (
select schedule_id from msdb.dbo.sysjobs_view as JI
left join msdb.dbo.sysjobschedules as SC on sc.job_id=ji.job_id
where name ='Checking_schedule_backups')

EXEC msdb.dbo.sp_update_schedule @schedule_id=@SCHEDULEID, 
		@enabled=@enabled