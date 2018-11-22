cls
function Invoke-Sqlcmd2
{ 
    [CmdletBinding()] 
    param( 
    [Parameter(Position=0, Mandatory=$true)] [string]$ServerInstance, 
    [Parameter(Position=1, Mandatory=$false)] [string]$Database, 
    [Parameter(Position=2, Mandatory=$false)] [string]$Query, 
    [Parameter(Position=3, Mandatory=$false)] [string]$Username, 
    [Parameter(Position=4, Mandatory=$false)] [string]$Password, 
    [Parameter(Position=5, Mandatory=$false)] [Int32]$QueryTimeout=600, 
    [Parameter(Position=6, Mandatory=$false)] [Int32]$ConnectionTimeout=15, 
    [Parameter(Position=7, Mandatory=$false)] [ValidateScript({test-path $_})] [string]$InputFile, 
    [Parameter(Position=8, Mandatory=$false)] [ValidateSet("DataSet", "DataTable", "DataRow")] [string]$As="DataRow" 
    ) 
 
    if ($InputFile) 
    { 
        $filePath = $(resolve-path $InputFile).path 
        $Query =  [System.IO.File]::ReadAllText("$filePath") 
    } 
 
    $conn=new-object System.Data.SqlClient.SQLConnection 
      
    if ($Username) 
    { $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance,$Database,$Username,$Password,$ConnectionTimeout } 
    else 
    { $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout } 
 
    $conn.ConnectionString=$ConnectionString 
     
    if ($PSBoundParameters.Verbose) 
    { 
        $conn.FireInfoMessageEventOnUserErrors=$true 
        $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {Write-Verbose "$($_)"} 
        $conn.add_InfoMessage($handler) 
    } 
     
    $conn.Open() 
    $cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn) 
    $cmd.CommandTimeout=$QueryTimeout 
    $ds=New-Object system.Data.DataSet 
    $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd) 
    [void]$da.fill($ds) 
    $conn.Close() 
    switch ($As) 
    { 
        'DataSet'   { Write-Output ($ds) } 
        'DataTable' { Write-Output ($ds.Tables) } 
        'DataRow'   { Write-Output ($ds.Tables[0]) } 
    } 
 
}
#Запрос на получение списка серверов из таблицы DB_ServerMain на Localhost
$GetServerListQuery="declare @command nvarchar(max)
set @command= 
'
select ServerName from DBAMonitoring.[dbo].[DB_ServerMain]
where 1=1
and sqlversion !=''''
and domain = ''dpc''
'
exec  sys.sp_executesql  @command
"
[array]$ServerList=Invoke-Sqlcmd2 -ServerInstance localhost -Query $GetServerListQuery 
foreach ($ServerInstance in $ServerList)
{
$ServerName=$ServerInstance.ServerName
#Write-Host "Это сервер" $ServerInstance.ServerName

$configurationChangeHistoryQuery="
declare @command nvarchar(max)
set @command = 
'
begin try
declare @enable int;
select @enable = convert(int,value_in_use) from sys.configurations where name = ''default trace enabled''
if @enable = 1 --default trace is enabled
begin
        declare @d1 datetime;
        declare @diff int;  
        declare @curr_tracefilename varchar(500); 
        declare @base_tracefilename varchar(500); 
        declare @indx int ;
        declare @temp_trace table (
                textdata nvarchar(MAX) collate database_default 
        ,       login_name sysname collate database_default
        ,       start_time datetime
        ,       event_class int
        );
        
        select @curr_tracefilename = path from sys.traces where is_default = 1 ; 
        
        set @curr_tracefilename = reverse(@curr_tracefilename)
        select @indx  = PATINDEX(''%\%'', @curr_tracefilename) 
        set @curr_tracefilename = reverse(@curr_tracefilename)
        set @base_tracefilename = LEFT( @curr_tracefilename,len(@curr_tracefilename) - @indx) + ''\log.trc'';
        
        insert into @temp_trace
        select TextData
        ,       LoginName
        ,       StartTime
        ,       EventClass 
        from ::fn_trace_gettable( @base_tracefilename, default ) 
        where ((EventClass = 22 and Error = 15457) or (EventClass = 116 and TextData like ''%TRACEO%(%''))
        
        select @d1 = min(start_time) from @temp_trace
        
        set @diff= datediff(hh,@d1,getdate())
        set @diff=@diff/24; 

        select 
		--(row_number() over (order by start_time desc))%2 as l1
        --,       @diff as difference,
		--       @d1 as date
		start_time
        ,       case event_class 
                        when 116 then ''Trace Flag '' + substring(textdata,patindex(''%(%'',textdata),len(textdata) - patindex(''%(%'',textdata) + 1) 
                        when 22 then substring(textdata,58,patindex(''%changed from%'',textdata)-60) 
                end as config_option
        --,       start_time
        ,       login_name
        ,       case event_class 
                        when 116 then ''--''
                        when 22 then substring(substring(textdata,patindex(''%changed from%'',textdata),len(textdata) - patindex(''%changed from%'',textdata))
                                                                ,patindex(''%changed from%'',substring(textdata,patindex(''%changed from%'',textdata),len(textdata) - patindex(''%changed from%'',textdata)))+13
                                                                ,patindex(''%to%'',substring(textdata,patindex(''%changed from%'',textdata),len(textdata) - patindex(''%changed from%'',textdata))) - patindex(''%from%'',substring(textdata,patindex(''%changed from%'',textdata),len(textdata) - patindex(''%changed from%'',textdata))) - 6) 
                end as old_value
        ,       case event_class 
                        when 116 then substring(textdata,patindex(''%TRACE%'',textdata)+5,patindex(''%(%'',textdata) - patindex(''%TRACE%'',textdata)-5)
                        when 22 then substring(substring(textdata,patindex(''%changed from%'',textdata),len(textdata) - patindex(''%changed from%'',textdata))
                                                                ,patindex(''%to%'',substring(textdata,patindex(''%changed from%'',textdata),len(textdata) - patindex(''%changed from%'',textdata)))+3
                                                                , patindex(''%. Run%'',substring(textdata,patindex(''%changed from%'',textdata),len(textdata) - patindex(''%changed from%'',textdata))) - patindex(''%to%'',substring(textdata,patindex(''%changed from%'',textdata),len(textdata) - patindex(''%changed from%'',textdata))) - 3) 
																
                end as new_value
				,@@servername as ServerName
        from @temp_trace 
        order by start_time desc
end else 
begin 
        select top 0  1  as l1, 1 as difference,1 as date , 1 as config_option,1 as start_time , 1 as login_name, 1 as old_value, 1 as new_value
end
end try 
begin catch
select -100  as l1
,       ERROR_NUMBER() as difference
,       ERROR_SEVERITY() as date 
,       ERROR_STATE() as config_option
,       1 as start_time 
,       ERROR_MESSAGE() as login_name
,       1 as old_value, 1 as new_value
end catch
'
EXEC sys.sp_executesql @command
"
[array]$configurationChangeHistoryResult=Invoke-Sqlcmd2 -ServerInstance $ServerName  -Query $configurationChangeHistoryQuery

foreach ($s in $configurationChangeHistoryResult)
{
$start_Time=$s.start_time
$config_option=$s.config_option
$login_name=$s.login_name
$old_value=$s.old_value
$new_value=$s.new_value
$serverName=$s.serverName
$configurationChangeHistoryResultLocalInsert="
declare @command nvarchar(max)
set @command= 
'
use [DBAMonitoring]
merge [dbo].[configurationChangeHistory] t using
(
    Select * from
    (
     VALUES 
	 (''$start_time''
	 ,''$config_option''
	 ,''$login_name''
	 ,''$old_value''
	 ,''$new_value''
	 ,''$ServerName'')
	 ) s ([start_time]
         ,[config_option]
         ,[login_name]
         ,[old_value]
         ,[new_value]
		 ,[servername])
         ) s
         
         on t.servername=s.servername
		 and t.start_time=s.start_time
		 and t.login_name=s.login_name
		 and t.config_option=s.config_option
 when not matched by target then
          INSERT ([start_time]
         ,[config_option]
         ,[login_name]
         ,[old_value]
         ,[new_value]
		 ,[servername])
         VALUES
         (s.[start_time]
         ,s.[config_option]
         ,s.[login_name]
         ,s.[old_value]
         ,s.[new_value]
		 ,s.[servername]
         )
when matched then update set
         [start_time]=s.[start_time]
         ,[config_option]=s.[config_option]
         ,[login_name]=s.[login_name]
         ,[old_value]=s.[old_value]
         ,[new_value]=s.[new_value]
;

'
EXEC sys.sp_executesql @command
"
Invoke-Sqlcmd2 -ServerInstance localhost  -Query $configurationChangeHistoryResultLocalInsert
}
}