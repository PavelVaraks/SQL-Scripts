[CmdletBinding()] 
    param( 
    [Parameter(Position=0, Mandatory=$true)] [string]$Server
    )

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



$ServerName=$Server

$FindPrincipalMirror='declare @principalMirror nvarchar(200) 
set @principalMirror=(select distinct mirroring_partner_instance from sys.database_mirroring
where mirroring_partner_instance is not null)
select @principalMirror'


$SuspendMirror='declare @effect nvarchar(max)
set @effect =
--Остановить синхронизацию
''SUSPEND''
--Продолжить синхронизацию
--''RESUME''
--меняет роли у серверов
--''FAILOVER''
--Переключает Operating mode в Синхронный режим
--''SAFETY FULL''
--Переключает Operating mode в Асинхронный режим
--''SAFETY OFF''
declare @command nvarchar(max)
declare @name nvarchar(max)
DECLARE db_cursor CURSOR FOR
SELECT name
FROM master.dbo.sysdatabases as d
left join sys.database_mirroring as m on m.database_id=d.dbid
WHERE d.name NOT IN (''master'',''model'',''msdb'',''tempdb'')
and m.mirroring_guid is not null
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @name
WHILE @@FETCH_STATUS = 0
BEGIN
set @command = ''ALTER DATABASE ''+@name+'' SET PARTNER ''+@effect
print @command
exec  sys.sp_executesql  @command
FETCH NEXT FROM db_cursor INTO @name
END
CLOSE db_cursor
DEALLOCATE db_cursor'


$resumeMirror='declare @effect nvarchar(max)
set @effect =
--Остановить синхронизацию
--''SUSPEND''
--Продолжить синхронизацию
''RESUME''
--меняет роли у серверов
--''FAILOVER''
--Переключает Operating mode в Синхронный режим
--''SAFETY FULL''
--Переключает Operating mode в Асинхронный режим
--''SAFETY OFF''
declare @command nvarchar(max)
declare @name nvarchar(max)
DECLARE db_cursor CURSOR FOR
SELECT name
FROM master.dbo.sysdatabases as d
left join sys.database_mirroring as m on m.database_id=d.dbid
WHERE d.name NOT IN (''master'',''model'',''msdb'',''tempdb'')
and m.mirroring_guid is not null
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @name
WHILE @@FETCH_STATUS = 0
BEGIN
set @command = ''ALTER DATABASE ''+@name+'' SET PARTNER ''+@effect
print @command
exec  sys.sp_executesql  @command
FETCH NEXT FROM db_cursor INTO @name
END
CLOSE db_cursor
DEALLOCATE db_cursor'

$SqlMirrorStatus='select count(*) from sys.database_mirroring where mirroring_state_desc!=''SYNCHRONIZED'''

#Invoke-Sqlcmd2 -ServerInstance $ServerName -Query $FindPrincipalMirror 
foreach ($server in $ServerName){
#Write-Host $Server
$PrincipalMirror=Invoke-Sqlcmd2 -ServerInstance $ServerName -Query $FindPrincipalMirror 
Write-Host "Сервер" $PrincipalMirror.Column1 "имеет роль Principal по отношению к " $server
Write-host "Останавливаем Репликацию на сервере " $PrincipalMirror.Column1
Invoke-Sqlcmd2 -ServerInstance $PrincipalMirror.Column1 -Query $SuspendMirror
$MirrorStatus=Invoke-Sqlcmd2 -ServerInstance $PrincipalMirror.Column1 -Query $SqlMirrorStatus
#Write-Host $MirrorStatus.Column1
IF ($MirrorStatus.Column1 -ne 0)
{Write-Host "Репликация остановленна"}
ELSE
{Write-host "Останавливаем Репликацию на сервере " $PrincipalMirror.Column1}

<#
Invoke-Sqlcmd2 -ServerInstance $PrincipalMirror.Column1 -Query $resumeMirror

Start-Sleep 2
$MirrorStatus=Invoke-Sqlcmd2 -ServerInstance $PrincipalMirror.Column1 -Query $SqlMirrorStatus
Write-Host $MirrorStatus.Column1
IF ($MirrorStatus.Column1 -ne 0)
{
Write-Host "Репликация остановленнаЛожь"
}
ELSE
{
Write-host "Останавливаем Репликацию на сервере " $PrincipalMirror.Column1
Invoke-Sqlcmd2 -ServerInstance $PrincipalMirror.Column1 -Query $SuspendMirror
}
#>

#Restart-Computer -ComputerName $server

DO
{
$ping=ping $server
if
($ping -like "*(0%*")
{Write-Host "Сервер" $server "доступен"

Write-Host "Проверим доступен ли скуль"

$MSSQL=Get-Service -Name MSSQLSERVER -ComputerName $server

IF
($MSSQL.status -ne "Running")
{
Write-host "Служба не запущена"}
Else 
{
Write-Host "Служба запущена"
Start-Sleep 1
Write-Host "Восстанавливаем репликацию зеркало"
Invoke-Sqlcmd2 -ServerInstance $PrincipalMirror.Column1 -Query $resumeMirror
$MirrorStatus=Invoke-Sqlcmd2 -ServerInstance $PrincipalMirror.Column1 -Query $SqlMirrorStatus
IF ($MirrorStatus.Column1 -ne 0)
{
Write-Host "Зеркало Восстановлено"}
ELSE
{Write-Host "Репликация не восстановлена, пробуем еще раз"
Invoke-Sqlcmd2 -ServerInstance $PrincipalMirror.Column1 -Query $resumeMirror
}
}
}
ELSE
{Write-Host "Сервер недоступен, через 10 секунд опросим снова"
Start-Sleep 10
}
}
WHILE ($MSSQL.status -ne "Running")

}




