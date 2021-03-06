 select * from msdb.dbo.backupset
 where type='D'
 --and user_name like 'NT AUTHORITY\SYSTEM'
 order by backup_finish_date desc
--Курсор перебора типа бэкапов
declare @BackupType nvarchar(255)
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


order by backup_finish_date desc
) 
--select * from cte where rn=2

SELECT *
INTO #TempBackupset
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

  select * from #TempBackupset
 
  select *
  INTO #TempBackupset2
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
	--,DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset),backup_finish_date )
	,DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date) as 'TimeDiffInSecond'
	,'ПромежутокМеждуБэкапами'=
	CASE
--Дни
WHEN DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date) >= 86400
THEN
CAST(DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date)/86400%86400 AS VARCHAR(4)) + ' Days '+ CAST(DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date)/3600%24 AS VARCHAR(4)) + ' h '+CAST(DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date)/60%60 AS VARCHAR(4)) + ' min ' +CAST(DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date)%60 AS VARCHAR(4)) +' sec '
--Часы
WHEN DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date) >= 3600
THEN
CAST(DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date)/3600%3600 AS VARCHAR(4)) + ' h '+CAST(DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date)/60%60 AS VARCHAR(4)) + ' min ' +CAST(DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date)%60 AS VARCHAR(4)) +' sec '
--Минуты 
WHEN DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date) >60
THEN CAST(DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date)/60%60 AS VARCHAR(4))+ ' min '+CAST(DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date)%60 AS VARCHAR(4)) + ' sec'
--секунды 
WHEN DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date) < 60
THEN CAST(DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date)%60 AS VARCHAR(4)) + ' sec '
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

  order by backup_finish_date desc
  ) as Data2

  
  declare @DataDiffBackups int
 set @DataDiffBackups = (select TimeDiffInSecond from #TempBackupset2)
 select @DataDiffBackups
Select * from #TempBackupset2
--Задаем время срабатывания+300 сек(5 минут)
--Если разница между промежутками между бэкапов + 5 минут
declare @AlarmTime int
set @AlarmTime=@DataDiffBackups+300	
select @AlarmTime
select DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()) as 'разница'
declare @seconddiffBackups int
set @seconddiffBackups = @AlarmTime-(select DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()))
select @seconddiffBackups
IF @seconddiffBackups < 0
BEGIN
IF (select type from #TempBackupset2)='L'
BEGIN
select 'WARNING! BACKUP Logs DataBases ['+(select database_name from #TempBackupset2)+']  on SQL Server ['+(convert(nvarchar(50),serverproperty('Servername'),2))+'] not success run '+ 
(select  
INSECOND=CASE
--Дни
WHEN DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()) >= 86400
THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())/86400%86400 AS VARCHAR(4)) + ' Day '+ CAST(DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date)/3600%24 AS VARCHAR(4)) + ' h '+CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())/60%60 AS VARCHAR(4)) + ' min ' +CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())%60 AS VARCHAR(4)) +' sec '
--Часы
WHEN DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()) >= 3600
THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())/3600%3600 AS VARCHAR(4)) + ' h '+CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())/60%60 AS VARCHAR(4)) + ' min ' +CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())%60 AS VARCHAR(4)) +' sec '
--Минуты 
WHEN DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()) >60
THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())/60%60 AS VARCHAR(4))+ ' min '+CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())%60 AS VARCHAR(4)) + ' sec'
--секунды 
WHEN DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()) < 60
THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()) AS VARCHAR(50)) + ' sec '
		Else 'can not show'
		END
 from #TempBackupset2

)
END
IF (select type from #TempBackupset2)='D'
BEGIN
select 'WARNING! BACKUP FULL DataBases ['+(select database_name from #TempBackupset2)+']  on SQL Server ['+(convert(nvarchar(50),serverproperty('Servername'),2))+'] not success run '+ 
(select  
INSECOND=CASE
--Дни
WHEN DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()) >= 86400
THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())/86400%86400 AS VARCHAR(4)) + ' Day '+ CAST(DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date)/3600%24 AS VARCHAR(4)) + ' h '+CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())/60%60 AS VARCHAR(4)) + ' min ' +CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())%60 AS VARCHAR(4)) +' sec '
--Часы
WHEN DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()) >= 3600
THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())/3600%3600 AS VARCHAR(4)) + ' h '+CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())/60%60 AS VARCHAR(4)) + ' min ' +CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())%60 AS VARCHAR(4)) +' sec '
--Минуты 
WHEN DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()) >60
THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())/60%60 AS VARCHAR(4))+ ' min '+CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())%60 AS VARCHAR(4)) + ' sec'
--секунды 
WHEN DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()) < 60
THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()) AS VARCHAR(50)) + ' sec '
		Else 'can not show'
		END
 from #TempBackupset2
)
END
IF (select type from #TempBackupset2)='I'
BEGIN
select 'WARNING! BACKUP DIFF DataBases ['+(select database_name from #TempBackupset2)+']  on SQL Server ['+(convert(nvarchar(50),serverproperty('Servername'),2))+'] not success run '+ 
(select  
INSECOND=CASE
--Дни
WHEN DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()) >= 86400
THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())/86400%86400 AS VARCHAR(4)) + ' Day '+ CAST(DATEDIFF(second, (select top 1 backup_finish_date from #TempBackupset), backup_finish_date)/3600%24 AS VARCHAR(4)) + ' h '+CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())/60%60 AS VARCHAR(4)) + ' min ' +CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())%60 AS VARCHAR(4)) +' sec '
--Часы
WHEN DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()) >= 3600
THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())/3600%3600 AS VARCHAR(4)) + ' h '+CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())/60%60 AS VARCHAR(4)) + ' min ' +CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())%60 AS VARCHAR(4)) +' sec '
--Минуты 
WHEN DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()) >60
THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())/60%60 AS VARCHAR(4))+ ' min '+CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE())%60 AS VARCHAR(4)) + ' sec'
--секунды 
WHEN DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()) < 60
THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #TempBackupset2),GETDATE()) AS VARCHAR(50)) + ' sec '
		Else 'can not show'
		END
 from #TempBackupset2
)
END 
END
ELSE
select 'Все окэей'
 --select @seconddiffBackups


  --select * from #TempBackupset2
   drop table #TempBackupset
   drop table #TempBackupset2

FETCH NEXT FROM db_cursor INTO @name
END 
CLOSE db_cursor 
DEALLOCATE db_cursor


 FETCH NEXT FROM cursorTypeBackup INTO @backuptype
END 
CLOSE cursorTypeBackup 
DEALLOCATE cursorTypeBackup
 
	--   select    *
	--From msdb.dbo.backupset
	--order by backup_finish_date	desc
	