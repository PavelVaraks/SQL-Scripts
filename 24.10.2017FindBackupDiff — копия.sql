 --Курсор перебора типа бэкапов
declare @BackupType nvarchar(255)
declare @BackupTypeCase nvarchar(255)
declare @BackupUser nvarchar(255)
declare cursorUser CURSOR FOR
select  distinct user_name from msdb.dbo.backupset
Open cursorUser
FETCH NEXT FROM cursorUser INTO @BackupUser
WHILE @@FETCH_STATUS = 0
BEGIN
declare cursorTypeBackup CURSOR FOR
select distinct type from msdb.dbo.backupset
where type in ('L','D','I')
OPEN cursorTypeBackup
FETCH NEXT FROM cursorTypeBackup INTO @BackupType
WHILE @@FETCH_STATUS = 0
Begin
--Курсор перебора имени баз данных
declare @name nvarchar(255)
DECLARE db_cursor CURSOR FOR 
SELECT name 
FROM master.dbo.sysdatabases 
WHERE name NOT IN ('master','model','msdb','tempdb')
OPEN db_cursor 
FETCH NEXT FROM db_cursor INTO @name
WHILE @@FETCH_STATUS = 0  
BEGIN
--Загрузка во временную таблицу вторую строку
with cte as
(
select top 2 *
,ROW_NUMBER() over (order by  backup_finish_date desc) as RowNumber
from msdb.dbo.backupset
where database_name=@name
and
type=@BackupType
and 
(
 user_name not like '%DPC\%'
  or 
  user_name like '%netbackup%'
  or
  user_name like '%svc_sqlais%'	
)
and user_name=@BackupUser


order by backup_finish_date desc
) 

SELECT *
INTO #BackUpDIFFTempBackupset
FROM

  (
  
select 
	 backup_set_id
	,backup_start_date
	,backup_finish_date
	,type
	,database_name
	,server_name from cte where RowNumber=2
   
  ) 
  as data
     
  select *
  INTO #BackUpDIFFTempBackupset2
  FROM 
  ( 
  select
   top 1
    backup_set_id
	,backup_start_date
	,backup_finish_date
	,type
	,database_name
	,server_name
	,DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date) as 'TimeDiffInSecond'
	,'ПромежутокМеждуБэкапами'=
	CASE
--Дни
WHEN DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date) >= 86400
THEN
CAST(DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date)/86400%86400 AS VARCHAR(4)) + ' Days '+ CAST(DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date)/3600%24 AS VARCHAR(4)) + ' h '+CAST(DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date)/60%60 AS VARCHAR(4)) + ' min ' +CAST(DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date)%60 AS VARCHAR(4)) +' sec '
--Часы
WHEN DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date) >= 3600
THEN
CAST(DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date)/3600%3600 AS VARCHAR(4)) + ' h '+CAST(DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date)/60%60 AS VARCHAR(4)) + ' min ' +CAST(DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date)%60 AS VARCHAR(4)) +' sec '
--Минуты 
WHEN DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date) >60
THEN CAST(DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date)/60%60 AS VARCHAR(4))+ ' min '+CAST(DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date)%60 AS VARCHAR(4)) + ' sec'
--секунды 
WHEN DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date) < 60
THEN CAST(DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date)%60 AS VARCHAR(4)) + ' sec '
		Else 'can not show'
		END
from msdb.dbo.backupset
where database_name=@name
and
type=@BackupType
and 
(
 user_name not like '%DPC\%'
  or 
  user_name like '%netbackup%'
    or
  user_name like '%svc_sqlais%'	
)
and user_name=@BackupUser

  order by backup_finish_date desc
  ) as Data2

  
  declare @DataDiffBackups int
 set @DataDiffBackups = (select TimeDiffInSecond from #BackUpDIFFTempBackupset2)


--Задаем время срабатывания+300 сек(5 минут)
--Если разница между промежутками между бэкапов + 5 минут
declare @AlarmTime int
set @AlarmTime=@DataDiffBackups

declare @seconddiffBackups int
set @seconddiffBackups = @AlarmTime-(select DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE()))

declare @Subject nvarchar(255)
DECLARE @tableHTML  NVARCHAR(MAX) 
--Если разница между бэкапами меньше 0 но не меньше 3х дней(259 200 секунд)
--IF @seconddiffBackups between 0 and  -259200
declare @USecondaryReplica bit
declare @versionSQL nvarchar(255)
set @USecondaryReplica = null
set @versionSql =Convert(nvarchar,SERVERPROPERTY('ProductVersion'))
IF @versionSql > '10.50.6220.0'
set @USecondaryReplica=(select is_primary_replica from sys.dm_hadr_database_replica_states AS RS
left join sys.databases as DB on RS.database_id=Db.database_id
where is_primary_replica =1
and DB.name=@name)
else
set @USecondaryReplica=1
if @seconddiffBackups < 0
and @USecondaryReplica =1
BEGIN
set @BackupTypeCase=Case @BackupType
WHEN 'L'
THEN 'Logs'
WHEN 'D'
THEN 'Full'
WHEN 'I'
THEN 'Differential'
ELSE ''
END
BEGIN
--Задаем Тему
set @Subject= 'WARNING! BACKUP '+@BackupTypeCase+' DataBases ['+(select database_name from #BackUpDIFFTempBackupset2)+']  on SQL Server ['+(convert(nvarchar(50),serverproperty('Servername'),2))+'] not success run '+ 
(select  
INSECOND=CASE
--Дни
WHEN DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE()) >= 86400
THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE())/86400%86400 AS VARCHAR(4)) + ' Day '+ CAST(DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date)/3600%24 AS VARCHAR(4)) + ' h '+CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE())/60%60 AS VARCHAR(4)) + ' min ' +CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE())%60 AS VARCHAR(4)) +' sec '
--Часы
WHEN DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE()) >= 3600
THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE())/3600%3600 AS VARCHAR(4)) + ' h '+CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE())/60%60 AS VARCHAR(4)) + ' min ' +CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE())%60 AS VARCHAR(4)) +' sec '
--Минуты 
WHEN DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE()) >60
THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE())/60%60 AS VARCHAR(4))+ ' min '+CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE())%60 AS VARCHAR(4)) + ' sec'
--секунды 
WHEN DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE()) < 60
THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE()) AS VARCHAR(50)) + ' sec '
		Else 'can not show'
		END
 from #BackUpDIFFTempBackupset2
 )

 --Задаем  tableHTML
 SET @tableHTML = 
N'<style type="text/css">
#box-table
{
font-family: "Lucida Sans Unicode", "Lucida Grande", Sans-Serif;
font-size: 12px;
text-align: center;
border-collapse: collapse;
border-top: 7px solid #9baff1;
border-bottom: 7px solid #9baff1;
}
#box-table th
{
font-size: 13px;
font-weight: normal;
background: #b9c9fe;
border-right: 2px solid #9baff1;
border-left: 2px solid #9baff1;
border-bottom: 2px solid #9baff1;
color: #039;
}
#box-table td
{
border-right: 1px solid #aabcfe;
border-left: 1px solid #aabcfe;
border-bottom: 1px solid #aabcfe;
color: #669;
}
tr:nth-child(odd) { background-color:#eee; }
tr:nth-child(even) { background-color:#fff; } 
</style>'+ 
N'<H1><font color="Red">Backup Success History for 2 Weeks</H1></font color="Red">'+
N'<H3><font color="Blue">Job [Checking_schedule_backups] is Disable, you can enable</H3></font color="Blue">'+
N'<H3><font color="Black">Run This Query:</H3></font color="Black">'+
N'<H4><font color="Black"> update MSDB.dbo.sysjobs set enabled=0 where name = ''Checking_schedule_backups''</H4></font color="Black">' +
N'<table id="box-table" >' +
N'
<th>Server_Name</th>
<th>Database_Name</th>
<th>Backup_Type</th>
<th>Date_Start</th>
<th>Time_Start</th>
<th>Time_Finish</th>
<th>Time_Run</th>
<th>Backup_Size</th>
<th>Who_Run</th>'
 +
    CAST ( (
SELECT td=server_name,       ''
,td=database_name,       ''
 ,td=CASE type
		WHEN 'L'
			THEN 'Logs'
		WHEN 'D'
			THEN 'Full'
		WHEN 'I'
			THEN 'Differential'
		END,       ''
	,td=(
		SELECT convert(VARCHAR(10), backup_start_date, 104)
		),       ''
	,td=(
		SELECT convert(VARCHAR(8), backup_start_date, 114)
		),       ''
	,td=(
		SELECT convert(VARCHAR(8), backup_finish_date, 114)
		),       ''
	,td=
	CASE
--минуты
WHEN DATEDIFF(second, backup_start_date, backup_finish_date) >= 3600
THEN
CAST(DATEDIFF(second, backup_start_date, backup_finish_date)/3600%24 AS VARCHAR(4)) + ' ' + 'h'+' '+CAST(DATEDIFF(second, backup_start_date, backup_finish_date)/60%60 AS VARCHAR(4)) + ' ' + 'min'+' '+CAST(DATEDIFF(second, backup_start_date, backup_finish_date)%60 AS VARCHAR(4)) + ' ' + 'sec'  
--Минуты 
WHEN DATEDIFF(second, backup_start_date, backup_finish_date) >60
THEN CAST(DATEDIFF(second, backup_start_date, backup_finish_date)/60%60 AS VARCHAR(4)) + ' ' + 'min'+' '+CAST(DATEDIFF(second, backup_start_date, backup_finish_date)%60 AS VARCHAR(4)) + ' ' + 'sec'
--секунды 
WHEN DATEDIFF(second, backup_start_date, backup_finish_date) < 60
THEN CAST(DATEDIFF(second, backup_start_date, backup_finish_date)%60 AS VARCHAR(4)) + ' ' + 'sec'
		Else 'can''n show'
		END,       ''
,td =
	CASE
--Терабайты
WHEN (backup_size / 1331439861000) > 1
THEN
CAST(CAST(backup_size / 1331439861000 AS DECIMAL(6, 1)) AS VARCHAR(14)) + ' ' + 'TB'	
--Гигабайты
WHEN (backup_size / 1073741824) > 1
THEN
CAST(CAST(backup_size / 1073741824 AS DECIMAL(6, 1)) AS VARCHAR(14)) + ' ' + 'GB'
--Мегабайты
WHEN (backup_size / 1048576) > 1
THEN
CAST(CAST(backup_size / 1048576 AS DECIMAL(6, 1)) AS VARCHAR(14)) + ' ' + 'MB'
--Килобайты
WHEN (backup_size / 1024) > 1
THEN
CAST(CAST(backup_size / 1024 AS DECIMAL(4, 0)) AS VARCHAR(14)) + ' ' + 'KB'
Else 'Backup=0 Warning!'
end,       ''
,td=	user_name,       ''

FROM msdb.dbo.backupset
where type=@BackupType
and database_name=@name
and user_name=@BackupUser
and	DATEDIFF(second, backup_finish_date, GETDATE()) < 1209600




ORDER BY backup_finish_date DESC
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>' ;
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = 'AlertSystem',
@recipients = 'p.varaks@fcod.nalog.ru',
@subject = @Subject,
@body = @tableHTML,
@body_format = 'HTML'
END
update MSDB.dbo.sysjobs
set enabled=0
where name = 'Checking_schedule_backups' 
END
ELSE
select 'Problems in the schedule of backup tools is not detected'

drop table #BackUpDIFFTempBackupset
drop table #BackUpDIFFTempBackupset2

FETCH NEXT FROM db_cursor INTO @name
END 
CLOSE db_cursor 
DEALLOCATE db_cursor


 FETCH NEXT FROM cursorTypeBackup INTO @backuptype
END 
CLOSE cursorTypeBackup 
DEALLOCATE cursorTypeBackup


FETCH NEXT FROM cursorUser INTO @BackupUser
END
CLOSE cursorUser 
DEALLOCATE cursorUser



