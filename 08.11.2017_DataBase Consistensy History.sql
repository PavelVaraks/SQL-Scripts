 --Курсор перебора типа бэкапов

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
declare @DatabaseName nvarchar(max)
set @DatabaseName= 'SfoMailServer'
declare @curr_tracefilename varchar(500); 
declare @base_tracefilename varchar(500); 
declare @indx int ; 
declare @temp_trace table (     
command nvarchar(MAX) collate database_default
,       LoginName varchar(MAX) collate database_default
,       StartTime datetime
,       errors int
,       repaired int
,       time nvarchar(10) collate database_default
); 

select @curr_tracefilename = path from sys.traces where is_default = 1 ; 
set @curr_tracefilename = reverse(@curr_tracefilename); 
select @indx  = PATINDEX('%\%', @curr_tracefilename) ;  
set @curr_tracefilename = reverse(@curr_tracefilename); 
set @base_tracefilename = left( @curr_tracefilename,len(@curr_tracefilename) - @indx) + '\log.trc' ; 

with TestVar as
(
select top 2 substring(convert(nvarchar(MAX),TextData),36, patindex('%executed%',TextData)-36) as command
,       LoginName
,       StartTime
,       convert(int,substring(convert(nvarchar(MAX),TextData),patindex('%found%',TextData)+6,patindex('%errors %',TextData)-patindex('%found%',TextData)-6)) as errors
,       convert(int,substring(convert(nvarchar(MAX),TextData),patindex('%repaired%',TextData)+9,patindex('%errors.%',TextData)-patindex('%repaired%',TextData)-9)) repaired
,       substring(convert(nvarchar(MAX),TextData),patindex('%time:%',TextData)+6,patindex('%hours%',TextData)-patindex('%time:%',TextData)-6)+':'+substring(convert(nvarchar(MAX),TextData),patindex('%hours%',TextData)+6,patindex('%minutes%',TextData)-patindex('%hours%',TextData)-6)+':'+substring(convert(nvarchar(MAX),TextData),patindex('%minutes%',TextData)+8,patindex('%seconds.%',TextData)-patindex('%minutes%',TextData)-8) as time 
,ROW_NUMBER() over (order by  StartTime desc) as RowNumber
from ::fn_trace_gettable( @base_tracefilename, default ) 
where EventClass = 22 and substring(TextData,36,12) = 'DBCC CHECKDB' and DatabaseName = @name   
order by StartTime desc
)

SELECT *
INTO #VaraksTest
FROM

  (
  
select 
	* from TestVar where RowNumber=2
   
  ) 
  as data
  
select *
  INTO #VaraksTest2
  FROM 
  (
  select top 1 substring(convert(nvarchar(MAX),TextData),36, patindex('%executed%',TextData)-36) as command
,       LoginName
,       StartTime
,       convert(int,substring(convert(nvarchar(MAX),TextData),patindex('%found%',TextData)+6,patindex('%errors %',TextData)-patindex('%found%',TextData)-6)) as errors
,       convert(int,substring(convert(nvarchar(MAX),TextData),patindex('%repaired%',TextData)+9,patindex('%errors.%',TextData)-patindex('%repaired%',TextData)-9)) repaired
,       substring(convert(nvarchar(MAX),TextData),patindex('%time:%',TextData)+6,patindex('%hours%',TextData)-patindex('%time:%',TextData)-6)+':'+substring(convert(nvarchar(MAX),TextData),patindex('%hours%',TextData)+6,patindex('%minutes%',TextData)-patindex('%hours%',TextData)-6)+':'+substring(convert(nvarchar(MAX),TextData),patindex('%minutes%',TextData)+8,patindex('%seconds.%',TextData)-patindex('%minutes%',TextData)-8) as time 
,ROW_NUMBER() over (order by  StartTime desc) as RowNumber
,DATEDIFF(second, (select top 1 StartTime from #VaraksTest), StartTime) as 'TimeDiffInSecond'
,'ПромежутокМеждуCheckDB'=
	CASE
--Дни
WHEN DATEDIFF(second, (select top 1 StartTime from #varakstest), StartTime) >= 86400
THEN
CAST(DATEDIFF(second, (select top 1 StartTime from #varakstest), StartTime)/86400%86400 AS VARCHAR(4)) + ' Days '+ CAST(DATEDIFF(second, (select top 1 StartTime from #varakstest), StartTime)/3600%24 AS VARCHAR(4)) + ' h '+CAST(DATEDIFF(second, (select top 1 StartTime from #varakstest), StartTime)/60%60 AS VARCHAR(4)) + ' min ' +CAST(DATEDIFF(second, (select top 1 StartTime from #varakstest), StartTime)%60 AS VARCHAR(4)) +' sec '
--Часы
WHEN DATEDIFF(second, (select top 1 StartTime from #varakstest), StartTime) >= 3600
THEN
CAST(DATEDIFF(second, (select top 1 StartTime from #varakstest), StartTime)/3600%3600 AS VARCHAR(4)) + ' h '+CAST(DATEDIFF(second, (select top 1 StartTime from #varakstest), StartTime)/60%60 AS VARCHAR(4)) + ' min ' +CAST(DATEDIFF(second, (select top 1 StartTime from #varakstest), StartTime)%60 AS VARCHAR(4)) +' sec '
--Минуты 
WHEN DATEDIFF(second, (select top 1 StartTime from #varakstest), StartTime) >60
THEN CAST(DATEDIFF(second, (select top 1 StartTime from #varakstest), StartTime)/60%60 AS VARCHAR(4))+ ' min '+CAST(DATEDIFF(second, (select top 1 StartTime from #varakstest), StartTime)%60 AS VARCHAR(4)) + ' sec'
--секунды 
WHEN DATEDIFF(second, (select top 1 StartTime from #varakstest), StartTime) < 60
THEN CAST(DATEDIFF(second, (select top 1 StartTime from #varakstest), StartTime)%60 AS VARCHAR(4)) + ' sec '
		Else 'can not show'
		END
from ::fn_trace_gettable( @base_tracefilename, default ) 
where EventClass = 22 and substring(TextData,36,12) = 'DBCC CHECKDB' and DatabaseName = @name   
order by StartTime desc
) as data2


  select * from #VaraksTest
  select * from #VaraksTest2

    declare @DataDiffBackups int
 set @DataDiffBackups = (select TimeDiffInSecond from #VaraksTest2)
 declare @seconddiffBackups int
 set @seconddiffBackups = @DataDiffBackups-(select DATEDIFF(second,(select top 1 StartTime from #VaraksTest2),GETDATE()))

 select TimeDiffInSecond as ПромежутокМеждуБэкапмиВСек from #VaraksTest2
 select @seconddiffBackups as ПрошлоВремени

 declare @USecondaryReplica bit
declare @versionSQL nvarchar(255)
set @USecondaryReplica = null
set @versionSql =Convert(nvarchar,SERVERPROPERTY('ProductVersion'))
IF @versionSql > '10.50.6220.0'
set @USecondaryReplica=(select is_primary_replica from sys.dm_hadr_database_replica_states AS RS
left join sys.databases as DB on RS.database_id=Db.database_id
where DB.name=@name)
else
set @USecondaryReplica=1
if
--@seconddiffBackups < 0
--and 
@USecondaryReplica=0
BEGIN
--Задаем Тему
--set @Subject= 'WARNING! BACKUP '+@BackupTypeCase+' DataBases ['+(select database_name from #BackUpDIFFTempBackupset2)+']  on SQL Server ['+(convert(nvarchar(50),serverproperty('Servername'),2))+'] not success run '+ 
--(select  
--INSECOND=CASE
----Дни
--WHEN DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE()) >= 86400
--THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE())/86400%86400 AS VARCHAR(4)) + ' Day '+ CAST(DATEDIFF(second, (select top 1 backup_finish_date from #BackUpDIFFTempBackupset), backup_finish_date)/3600%24 AS VARCHAR(4)) + ' h '+CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE())/60%60 AS VARCHAR(4)) + ' min ' +CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE())%60 AS VARCHAR(4)) +' sec '
----Часы
--WHEN DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE()) >= 3600
--THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE())/3600%3600 AS VARCHAR(4)) + ' h '+CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE())/60%60 AS VARCHAR(4)) + ' min ' +CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE())%60 AS VARCHAR(4)) +' sec '
----Минуты 
--WHEN DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE()) >60
--THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE())/60%60 AS VARCHAR(4))+ ' min '+CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE())%60 AS VARCHAR(4)) + ' sec'
----секунды 
--WHEN DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE()) < 60
--THEN CAST(DATEDIFF(second,(select top 1 backup_finish_date from #BackUpDIFFTempBackupset2),GETDATE()) AS VARCHAR(50)) + ' sec '
--		Else 'can not show'
--		END
-- from #BackUpDIFFTempBackupset2
-- )

 --Задаем  tableHTML
 DECLARE @tableHTML  NVARCHAR(MAX) 
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
N'<H1><font color="Red">DataBase Consistency History</H1></font color="Red">'+
N'<table id="box-table" >' +
N'
<th>CommandRun</th>
<th>Who_Run</th>
<th>Date_Start</th>
<th>Time_Start</th>
<th>Errors</th>
<th>Repaired</th>
<th>Time_Run</th>'
 +
    CAST ( (
select td=substring(convert(nvarchar(MAX),TextData),36, patindex('%executed%',TextData)-36),       ''
,td=       LoginName,       ''
,td=convert(VARCHAR(10), StartTime, 104),       ''
,td=convert(VARCHAR(8), StartTime, 114),       ''
,td=       convert(int,substring(convert(nvarchar(MAX),TextData),patindex('%found%',TextData)+6,patindex('%errors %',TextData)-patindex('%found%',TextData)-6)),       ''
,td=       convert(int,substring(convert(nvarchar(MAX),TextData),patindex('%repaired%',TextData)+9,patindex('%errors.%',TextData)-patindex('%repaired%',TextData)-9)),       ''
,td=       substring(convert(nvarchar(MAX),TextData),patindex('%time:%',TextData)+6,patindex('%hours%',TextData)-patindex('%time:%',TextData)-6)+':'+substring(convert(nvarchar(MAX),TextData),patindex('%hours%',TextData)+6,patindex('%minutes%',TextData)-patindex('%hours%',TextData)-6)+':'+substring(convert(nvarchar(MAX),TextData),patindex('%minutes%',TextData)+8,patindex('%seconds.%',TextData)-patindex('%minutes%',TextData)-8),       ''
from ::fn_trace_gettable( @base_tracefilename, default ) 
where EventClass = 22 and substring(TextData,36,12) = 'DBCC CHECKDB' and DatabaseName = @name   
order by StartTime desc
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>' ;
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = 'AlertSystem',
@recipients = 'p.varaks@fcod.nalog.ru',
@subject = '2',
@body = @tableHTML,
@body_format = 'HTML'
END
--update MSDB.dbo.sysjobs
--set enabled=0
--where name = 'Checking_schedule_backups' 

ELSE
select 'Problems in the schedule of backup tools is not detected'
select @USecondaryReplica
--drop table #BackUpDIFFTempBackupset
--drop table #BackUpDIFFTempBackupset2

FETCH NEXT FROM db_cursor INTO @name
END 
CLOSE db_cursor 
DEALLOCATE db_cursor









  drop table #varaksTest
  drop table #VaraksTest2
  --use SfoMailServer
  --dbcc dbinfo with tableresults