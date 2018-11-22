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

$MirrorStopSync="declare @command nvarchar(max)
set @command= 
'
select ServerName from DBAMonitoring.[dbo].[DB_ServerMain]
where [description]!=''GP3 - Listener BD MSSQL''
'
exec  sys.sp_executesql  @command
"
[array]$ServerList=Invoke-Sqlcmd2 -ServerInstance localhost -Query $MirrorStopSync 
foreach ($ServerInstance in $ServerList)
{
$ServerName=$ServerInstance.ServerName
#Write-Host "Это сервер" $ServerInstance.ServerName
$GetSQLVersion="declare @command nvarchar(max)
set @command= 
'
declare @version nvarchar(55)=@@version
select @version
'
exec  sys.sp_executesql  @command
"
$Version2=Invoke-Sqlcmd2 -ServerInstance $ServerName -Query $GetSQLVersion
$Version=$Version2.column1 
Write-Host "Это сервер" $ServerInstance.ServerName "а версия" $Version
$UpdateVersion="declare @command nvarchar(max)
set @command= 
'
update [DBAMonitoring].[dbo].[DB_ServerMain]
set [sqlversion] = ''$Version''
where [ServerName] = ''$ServerName''
'
exec  sys.sp_executesql  @command
"
Invoke-Sqlcmd2 -ServerInstance Localhost -Query $UpdateVersion
}