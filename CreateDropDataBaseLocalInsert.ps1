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
set @command = '
DECLARE @filename NVARCHAR(1000);
DECLARE @bc INT;
DECLARE @ec INT;
DECLARE @bfn VARCHAR(1000);
DECLARE @efn VARCHAR(10);
 
-- Get the name of the current default trace
SELECT @filename = CAST(value AS NVARCHAR(1000))
FROM ::fn_trace_getinfo(DEFAULT)
WHERE traceid = 1 AND property = 2;
 
-- rip apart file name into pieces
SET @filename = REVERSE(@filename);
SET @bc = CHARINDEX(''.'',@filename);
SET @ec = CHARINDEX(''_'',@filename)+1;
SET @efn = REVERSE(SUBSTRING(@filename,1,@bc));
SET @bfn = REVERSE(SUBSTRING(@filename,@ec,LEN(@filename)));
 
-- set filename without rollover number
SET @filename = @bfn + @efn

SELECT distinct
      EventType = e.name
    , t.DatabaseName
	, ObjectType =
        CASE t.ObjectType
            WHEN 16964 THEN ''Database''
        END
		    , t.ApplicationName
    , t.LoginName
    ,t.HostName as Servername
		,convert(datetime2(0),StartTime) as [DateTime]
FROM sys.traces i
CROSS APPLY sys.fn_trace_gettable(@filename, DEFAULT) t
JOIN sys.trace_events e ON t.EventClass = e.trace_event_id
WHERE 1=1
and e.name IN (''Object:Created'', ''Object:Deleted'') 
and ObjectType =16964
order by convert(datetime2(0),StartTime)
'

EXEC sys.sp_executesql @command
"
[array]$configurationChangeHistoryResult=Invoke-Sqlcmd2 -ServerInstance $ServerName  -Query $configurationChangeHistoryQuery

foreach ($s in $configurationChangeHistoryResult)
{
$EventType=$s.EventType
$DatabaseName=$s.DatabaseName
$ObjectType=$s.ObjectType
$ApplicationName=$s.ApplicationName
$LoginName=$s.LoginName
$serverName=$s.serverName
$DateTime=$s.DateTime
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
	 (''$EventType''
	 ,''$DatabaseName''
	 ,''$ObjectType''
	 ,''$ApplicationName''
	 ,''$LoginName''
	 ,''$serverName''
	 ,''$DateTime'')
	 ) s ([EventType]
         ,[DatabaseName]
         ,[ObjectType]
         ,[ApplicationName]
         ,[LoginName]
		 ,[servername]
		 ,[DateTime])
         ) s
         
		 on t.servername=s.servername
		 and t.DateTime=s.DateTime
		 and t.login_name=s.login_name
		 and t.DatabaseName=s.DatabaseName
		 and t.ApplicationName=s.ApplicationName
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