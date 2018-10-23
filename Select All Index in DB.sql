	
declare @command nvarchar(max)
set @command=
'use ?
IF db_id() > 4
select @@servername as SrvName, 
db_name() db
--	,o.type_desc
	,(i.type_desc) index_type
	,''[''+s.name collate Cyrillic_General_CI_AS+''].[''+o.name+'']'' object_name
	,''[''+i.name+'']'' index_name
	,case when i.type in (1,2) then
	stuff((
		select '',''+name+case when ic.is_descending_key=0 then '' asc'' else '' desc'' end
		
		from sys.columns c
		join sys.index_columns ic
			on c.column_id = ic.column_id
			and c.object_id = ic.object_id
			and c.object_id = i.object_id
			and ic.index_id = i.index_id
			and ic.is_included_column=0
		order by ic.key_ordinal
		for xml path('''')
	),1,1,'''')
	when i.type=5 then ''<CLUSTERED COLUMNSTORE>''
	else ''<UNKNOWN>''
	end index_column
	,coalesce(stuff((
		select '',''+name
		from sys.columns c
		join sys.index_columns ic
			on c.column_id = ic.column_id
			and c.object_id = ic.object_id
			and c.object_id = i.object_id
			and ic.index_id = i.index_id
			and ic.is_included_column=1
		order by ic.key_ordinal
		for xml path('''')
	),1,1,''''),''-'') include_column
	,coalesce(filter_definition,''-'') filter_definition
	,i.is_primary_key
	,i.is_unique_constraint
	,i.is_unique
from sys.indexes i
join sys.objects o on i.object_id = o.object_id
join sys.schemas s on s.schema_id = o.schema_id
where 1=1
and i.type != 0
and o.type in (''U'',''V'')
and db_id() >4'

exec sp_msforeachdb @command