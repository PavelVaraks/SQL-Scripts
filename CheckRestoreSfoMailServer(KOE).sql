/*
if exists (select 1 from sys.databases where name ='SfoMailServer')
print 'База восстановлена'
else
*/
if sys.fn_hadr_is_primary_replica('SfoMailServer') = 1
BEGIN
IF (convert(date,(select create_date from sys.databases
where name ='SfoMailServer'),4))  >=  convert(date,getdate(),4)
BEGIN
print 'База восстановлена'
end
ELSE
BEGIN
print 'База не восстановлена'
declare @subject nvarchar(max)
declare @body nvarchar(max)
declare @servername varchar(100)
set @servername = (select convert(varchar(30),SERVERPROPERTY('servername')))
set @subject ='[WARNING] База [SfoMailServer] на '+ @servername +' не восстановлена!'
set @body = @subject + '
<br><br>Необходимо восстановить базу.<br><br>
<br><br><b>Подробнее тут:</b> http://confluence:8090/pages/viewpage.action?pageId=49872915 <br><br><br><br>
'
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = 'AlertSystem',
@recipients = 'dbashift@fcod.nalog.ru',
@subject = @subject,
@body = @body,
@body_format = 'HTML'
END
END
ELSE
BEGIN
IF (convert(date,(select create_date from sys.databases
where name ='SfoMailServer'),4))  >=  convert(date,getdate(),4)
BEGIN
print 'База восстановлена'
end
ELSE
BEGIN
print 'База не восстановлена'
set @servername = (select convert(varchar(30),SERVERPROPERTY('servername')))
set @subject ='[WARNING] База [SfoMailServer] на '+ @servername +' не восстановлена!'
set @body = @subject + '
<br><br>Необходимо восстановить базу.<br><br>
<br><br><b>Подробнее тут:</b> http://confluence:8090/pages/viewpage.action?pageId=49872915 <br><br><br><br>
'
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = 'AlertSystem',
@recipients = 'dbashift@fcod.nalog.ru',
@subject = @subject,
@body = @body,
@body_format = 'HTML'
END
END