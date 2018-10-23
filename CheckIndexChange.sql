USE [msdb]
GO

/****** Object:  Job [CheckIndexChange]    Script Date: 21.09.2018 9:38:35 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 21.09.2018 9:38:35 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'CheckIndexChange', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'AlertSql', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CheckIndexChange]    Script Date: 21.09.2018 9:38:35 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'CheckIndexChange', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'if object_id(''tempdb..#index_list'') is not null drop table #index_list
create table #index_list
(
	db varchar(128) not null,
	type_desc varchar(60) null,
	is_primary_key bit null,
	is_unique_constraint bit null,
	is_unique bit null,
	index_type varchar(60) null,
	object_name varchar(250),
	index_name varchar(128) not null,
	index_column varchar(max) null,
	include_column varchar(max) null,
	filter_definition varchar(max) null,
	primary key (db,object_name,index_name)
)

insert #index_list
exec sp_msforeachdb ''use [?];
select
	 db_name() db
	,o.type_desc
	,i.is_primary_key
	,i.is_unique_constraint
	,i.is_unique
	,lower(i.type_desc) index_type
	,''''[''''+s.name collate Cyrillic_General_CI_AS+''''].[''''+o.name+'''']'''' object_name
	,''''[''''+i.name+'''']'''' index_name
	,case when i.type in (1,2) then
	stuff((
		select '''',''''+name+case when ic.is_descending_key=0 then '''' asc'''' else '''' desc'''' end
		from sys.columns c
		join sys.index_columns ic
			on c.column_id = ic.column_id
			and c.object_id = ic.object_id
			and c.object_id = i.object_id
			and ic.index_id = i.index_id
			and ic.is_included_column=0
		order by ic.key_ordinal
		for xml path('''''''')
	),1,1,'''''''')
	when i.type=5 then ''''<CLUSTERED COLUMNSTORE>''''
	else ''''<UNKNOWN>''''
	end index_column
	,coalesce(stuff((
		select '''',''''+name
		from sys.columns c
		join sys.index_columns ic
			on c.column_id = ic.column_id
			and c.object_id = ic.object_id
			and c.object_id = i.object_id
			and ic.index_id = i.index_id
			and ic.is_included_column=1
		order by ic.key_ordinal
		for xml path('''''''')
	),1,1,''''''''),''''-'''') include_column
	,coalesce(filter_definition,''''-'''') filter_definition
from sys.indexes i
join sys.objects o on i.object_id = o.object_id
join sys.schemas s on s.schema_id = o.schema_id
where 1=1
and i.type != 0
and o.type in (''''U'''',''''V'''')
and db_id() != 2''

declare @dt datetime = getdate()
--delete from dbo.index_list where dt$ = (select max(dt$) from dbo.index_list)

;with trg as
(
	select *
	from
	(
		select *,
			rn$ = row_number() over
			(
				partition by db,object_name,index_name
				order by dt$ desc
			)
		from dbo.index_list
	) t
	where rn$=1 and oper$ != ''D''
)
, recordset as
(
	select
		coalesce(src.type_desc, trg.type_desc) as type_desc,
		coalesce(src.db, trg.db) as db,
		coalesce(src.object_name, trg.object_name) as object_name,
		coalesce(src.index_name, trg.index_name) as index_name,
		coalesce(src.index_column, trg.index_column) as index_column,
		coalesce(src.include_column, trg.include_column) as include_column,
		coalesce(src.filter_definition, trg.filter_definition) as filter_definition,
		coalesce(src.is_primary_key, trg.is_primary_key) as is_primary_key,
		coalesce(src.is_unique_constraint, trg.is_unique_constraint) as is_unique_constraint,
		coalesce(src.is_unique, trg.is_unique) as is_unique,
		coalesce(src.index_type, trg.index_type) as index_type,
		@dt as dt$,
		oper$ = case
			when src.db is null then ''D''
			when trg.db is null then ''I''
			when	src.type_desc != trg.type_desc
				or	src.index_column != trg.index_column
				or	coalesce(src.include_column,'''') != coalesce(trg.include_column,'''')
				or	coalesce(src.filter_definition,'''') != coalesce(trg.filter_definition,'''')
				or	src.is_primary_key != trg.is_primary_key
				or	src.is_unique_constraint != trg.is_unique_constraint
				or	src.is_unique != trg.is_unique
				or	src.index_type != trg.index_type
								then ''U''
		end
	from trg full join #index_list as src
		on  trg.db = src.db
		and trg.object_name = src.object_name
		and trg.index_name = src.index_name
)
insert dbo.index_list
select *
from recordset
where oper$ is not null

--- формируем оповещение на емэйл
--select @dt = max(dt$) from dbo.index_list
if not exists (select * from dbo.index_list where dt$ = @dt) return

if object_id(''tempdb..#curr'') is not null drop table #curr
select *
into #curr
from dbo.index_list
where dt$ = @dt

if object_id(''tempdb..#prev'') is not null drop table #prev
select *
into #prev
from dbo.index_list
where dt$ in (
select max(dt$)
from dbo.index_list
where dt$ < @dt
)

if object_id(''tempdb..#res'') is not null drop table #res
select 
	 type_desc
	,db
	,object_name
	,index_name
	,index_column
	,isnull(include_column,'''') include_column
	,isnull(filter_definition,'''') filter_definition
	,case
		when is_primary_key=1 then ''primary key ''
		when is_unique_constraint=1 then ''unique constraint ''
		when is_unique=1 then ''unique index ''
		else ''''
	end+index_type as index_type
	,dt$
	,''drop index'' oper$
into #res
from #curr
where oper$=''D''
union all
select 
	 type_desc
	,db
	,object_name
	,index_name
	,index_column
	,include_column
	,filter_definition
	,case
		when is_primary_key=1 then ''primary key ''
		when is_unique_constraint=1 then ''unique constraint ''
		when is_unique=1 then ''unique index ''
		else ''''
	end+index_type
	,dt$
	,''create index''
from #curr
where oper$=''I''
union all
select 
	 case when c.type_desc!=p.type_desc
		then ''old: (''+p.type_desc+''); new: (''+c.type_desc+'')''
		else c.type_desc
	end
	,c.db
	,c.object_name
	,c.index_name
	,c.index_column cix
	--,p.index_column pix
	,case when c.include_column!=p.include_column
		then ''old: (''+p.include_column+''); new: (''+c.include_column+'')''
		else c.include_column
	end
	,case when c.filter_definition!=p.filter_definition
		then ''old: (''+p.filter_definition+''); new: (''+c.filter_definition+'')''
		else c.filter_definition
	end
	,case when	c.is_primary_key!=p.is_primary_key or
				c.is_unique_constraint!=p.is_unique_constraint or
				c.is_unique!=p.is_unique or
				c.index_type!=p.index_type
		then ''old: (''+
				case
					when c.is_primary_key=1 then ''primary key ''
					when c.is_unique_constraint=1 then ''unique constraint ''
					when c.is_unique=1 then ''unique index ''
					else ''''
				end+c.index_type+''); new: (''+
				case
					when p.is_primary_key=1 then ''primary key ''
					when p.is_unique_constraint=1 then ''unique constraint ''
					when p.is_unique=1 then ''unique index ''
					else ''''
				end+p.index_type+'')''
		else
				case
					when c.is_primary_key=1 then ''primary key ''
					when c.is_unique_constraint=1 then ''unique constraint ''
					when c.is_unique=1 then ''unique index ''
					else ''''
				end+c.index_type
	end
	,convert(nvarchar,c.dt$,120)
	,''modify index''
--select c.*, p.*
from #curr c join #prev p	on	c.db = p.db
							and	c.object_name = p.object_name
							and c.index_name = p.index_name
where c.oper$=''U''


DECLARE @tableHTML nvarchar(max) = N''<style type="text/css">
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
</style>''+ 
N''<table id="box-table" >'' +
N''
<th>Object Type</th>
<th>Database Name</th>
<th>Object Name</th>
<th>Index Name</th>
<th>Index Colum</th>
<th>Include Column</th>
<th>Filter Definition</th>
<th>Index Type</th>
<th>DateTime</th>
<th>Operation</th>''
+
coalesce(cast ( (
select 
	 td=type_desc, ''''
	,td=db, ''''
	,td=object_name, ''''
	,td=index_name, ''''
	,td=index_column, ''''
	,td=include_column, ''''
	,td=filter_definition, ''''
	,td=index_type, ''''
	,td=dt$, ''''
	,td=oper$, ''''
from #res
order by oper$, dt$
for xml path(''tr''), type
) as nvarchar(max) ),'''')+
N''</table>'';

print @tableHTML
declare @sub nvarchar(200)
set @sub = ''Index changed on['' + @@servername+'']''
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = ''AlertSystem'',
@recipients = ''a.kurenkov@fcod.nalog.ru;p.varaks@fcod.nalog.ru'',
@subject = @sub,
@body = @tableHTML,
@body_format = ''HTML''', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every60Min', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180428, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'b2af015c-05a1-4a8a-8cbf-b00491c076ed'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


