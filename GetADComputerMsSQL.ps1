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



[array]$c=Get-ADComputer -Filter  { 
Name -notlike "*-lsn*"


}  |? {$_.name -like "N5001-*" } | ? { $_.name -like "*AIS*" -OR $_.name -like "*SYS*" -OR $_.name -like "*APP*" -OR $_.name -like "*PPK*" -OR $_.name -like "*KOE*" -OR $_.name -like "*KTR*" -OR $_.name -like "*STD*"  -OR $_.name -like "*OPZ*" -OR $_.name -like "*tmpl*" }  | Sort-Object name | select name
#}  |? {$_.name -like "N5001*" -or $_.name -like "N5201*" -or $_.name -like "N7701*" -or $_.name -like "M9965*"} | ? { $_.name -like "*KTR23"}  | Sort-Object name | select name
#[array]$c=Get-ADComputer -Filter  { Description -notlike "Failover cluster virtual network name account"} -Properties name,OperatingSystem | ? {$_.OperatingSystem -like "*Windows*"} | ? { $_.name -notlike "*-lsn*"}  | ? { $_.name -like "*AIS*" -OR $_.name -like "*SYS*" -OR $_.name -like "*APP*" -OR $_.name -like "*PPK*" -OR $_.name -like "*KOE*" -OR $_.name -like "*KTR*" -OR $_.name -like "*STD*"  -OR $_.name -like "*OPZ*" -OR $_.name -like "*tmpl*" -and $_.name -ne "m9965-app075" }  | Sort-Object name | select name
#[array]$c=Get-ADComputer -Filter  { Description -notlike "Failover cluster virtual network name account"} -Properties name,OperatingSystem | ? {$_.OperatingSystem -like "*Windows*"} | ? { $_.name -notlike "*-lsn*"}  | ? { $_.name -like "*AIS*" }  | Sort-Object name | select name
#[array]$c=Get-ADComputer -Filter { Description -notlike "Failover cluster virtual network name account"} | ? { $_.name -like "N7701-PPK314" }  | Sort-Object name | select name
#[array]$c=Get-ADComputer -Filter { Description -notlike "Failover cluster virtual network name account"} | ? { $_.name -like "n5001-ais262"  }  | Sort-Object name | select name
#[array]$c=Get-ADComputer -Filter { Description -notlike "Failover cluster virtual network name account"} | ? { $_.name -like "*AIS*" }  | Sort-Object name | select name
#$Clusters

foreach ($s in $c)
    {
	
    #  TRY 
     # {
	  IF (Test-NetConnection -Port 1433 -ComputerName $s.name -InformationLevel Quiet)
	  {
	  $cluster=get-cluster $s.name -ErrorAction SilentlyContinue
    IF ($cluster -ne $s.name)
    {
      #write-host "Проверяю" $s.name
      #Test-NetConnection -ComputerName $s.name -Port 1433 -InformationLevel Quiet
     IF (Get-Service -ComputerName $s.name -name "*MSSQL*" -ErrorAction SilentlyContinue)
      {
Write-Host "Порт 1433 доступен, пробую подключиться к " $s.name
[array]$AdCompProperty=Get-ADComputer -Identity $s.name -Properties * | select SID,Name,DNSHostName,IPv4Address,Description,OperatingSystem,WhenCreated,ManagedBy
$SqlServerSID=$AdCompProperty.SyncRoot.SID
$SqlServerName=$AdCompProperty.SyncRoot.Name
$SqlServerDNSHostName=$AdCompProperty.SyncRoot.DNSHostName
$DomainName=($SqlServerDNSHostName -replace $SqlServerName,"")
$DomainName=$DomainName.Remove(0,1)
IF ($DomainName -like "*dpc*")
{$DomainName="DPC"}
IF ($DomainName -like "*idmz*")
{$DomainName="IDMZ"}
$SqlServerIPv4Address=$AdCompProperty.SyncRoot.IPv4Address
$SqlServerOperatingSystem=$AdCompProperty.SyncRoot.OperatingSystem
$SqlServerDescription=$AdCompProperty.SyncRoot.Description
$SqlServerWhenCreated=$AdCompProperty.SyncRoot.WhenCreated
$TimePool=Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$lastbootup=Invoke-Command -ComputerName $s.name -ScriptBlock {Get-WmiObject win32_operatingsystem | Select-Object @{LABEL='LastBootUpTime'
;EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}}
$lastbootuptime=$lastbootup.LastBootUpTime
$ServerName=$s.name
$GetSQLVersion="declare @command nvarchar(max)
set @command= 
'
declare @version nvarchar(55)=@@version
select @version
'
exec  sys.sp_executesql  @command
"
$Version2=Invoke-Sqlcmd2 -ServerInstance $ServerName -Query $GetSQLVersion
$VersionSql=$Version2.column1 
#Получаем Редакцию MS SQL
$GetSQL_Edition="
declare @command nvarchar(max)
set @command= 
'
declare @edition nvarchar(55)=convert(nvarchar(50),SERVERPROPERTY(''edition''),2)
select @edition
'
exec  sys.sp_executesql  @command
"
$edition2=Invoke-Sqlcmd2 -ServerInstance $ServerName -Query $GetSQL_Edition
$editionSql=$edition2.column1 

$GetPhysicalCPUs="
declare @command nvarchar(max)
set @command= 
'
declare @PhysicalCPUs nvarchar(55)=(SELECT 
(cpu_count / hyperthread_ratio) AS PhysicalCPUs
FROM sys.dm_os_sys_info )
select @PhysicalCPUs
'
exec  sys.sp_executesql  @command 
"
$PhysicalCPUs2=Invoke-Sqlcmd2 -ServerInstance $ServerName -Query $GetPhysicalCPUs
$PhysicalCPUs=$PhysicalCPUs2.column1 


$GetlogicalCPUs="
declare @command nvarchar(max)
set @command= 
'
declare @logicalCPUs nvarchar(55)=(SELECT 
cpu_count  AS logicalCPUs
FROM sys.dm_os_sys_info )
select @logicalCPUs
'
exec  sys.sp_executesql  @command 
"
$logicalCPUs2=Invoke-Sqlcmd2 -ServerInstance $ServerName -Query $GetlogicalCPUs
$logicalCPUs=$logicalCPUs2.column1 



Write-Host "!!!На сервере" $SqlServerName "Найден MSSQL"
$MsSQLAdd="
declare @command nvarchar(max)
set @command= 
'
use [DBAMonitoring]
INSERT INTO [dbo].[DB_ServerMain]
           ([DBServerID]
           ,[ServerName]
           ,[DNSHostName]
           ,[IPv4Address]
           ,[Description]
           ,[OperatingSystem]
           ,[WhenCreated]
           ,[SessionCollectionInterval]
		   ,[lastPoll]
		   ,[lastreboot]
		   ,[SqlVersion]
		   ,[Domain]
		   ,[SqlEdition]
		   ,[PhysicalCPUs]
		   ,[logicalCPUs])
     VALUES 
	 (''$SqlServerSID''
	 ,''$SqlServername''
	 ,''$SqlServerDNSHostName''
	 ,''$SqlServerIPv4Address''
	 ,''$SqlServerDescription''
	 ,''$SqlServerOperatingSystem''
	 ,''$SqlServerWhenCreated''
	 , 5
	 , ''$Timepoll''
	 , ''$lastbootuptime''
	 , ''$VersionSql''
	 , ''$DomainName''
	 , ''$editionSql''
	 , ''$PhysicalCPUs''
	 , ''$logicalCPUs''
	 )
'
EXEC sys.sp_executesql @command
"

$MsSQLMerge="
declare @command nvarchar(max)
set @command= 
'
use [DBAMonitoring]
merge [dbo].[DB_ServerMain] t using
(
    Select * from
    (
     VALUES 
	 (''$SqlServerSID''
	 ,''$SqlServername''
	 ,''$SqlServerDNSHostName''
	 ,''$SqlServerIPv4Address''
	 ,''$SqlServerDescription''
	 ,''$SqlServerOperatingSystem''
	 ,''$SqlServerWhenCreated''
	 , 5
	 , ''$timepool''
	 , ''$lastbootuptime''
	 , ''$VersionSql''
	 , ''$DomainName''
	 , ''$editionSql''
	 , ''$PhysicalCPUs''
	 , ''$logicalCPUs'')
	 ) s ([DBServerID]
         ,[ServerName]
         ,[DNSHostName]
         ,[IPv4Address]
         ,[Description]
         ,[OperatingSystem]
         ,[WhenCreated]
         ,[SessionCollectionInterval]
		 ,[lastPoll]
		 ,[lastreboot]
		 ,[SqlVersion]
		 ,[Domain]
		 ,[SqlEdition]
		 ,[PhysicalCPUs]
		 ,[logicalCPUs])
         ) s
         
         on t.servername=s.servername
 when not matched by target then
          INSERT ([DBServerID]
         ,[ServerName]
         ,[DNSHostName]
         ,[IPv4Address]
         ,[Description]
         ,[OperatingSystem]
         ,[WhenCreated]
         ,[SessionCollectionInterval]
		 ,[lastPoll]
		 ,[lastreboot]
		 ,[SqlVersion]
		 ,[Domain]
		 ,[SqlEdition]
		 ,[PhysicalCPUs]
		 ,[logicalCPUs])
         VALUES
         (s.[DBServerID]
         ,s.[ServerName]
         ,s.[DNSHostName]
         ,s.[IPv4Address]
         ,s.[Description]
         ,s.[OperatingSystem]
         ,s.[WhenCreated]
         ,s.[SessionCollectionInterval]
		 ,s.[lastPoll]
		 ,s.[lastreboot]
		 ,s.[SqlVersion]
		 ,s.[Domain]
		 ,s.[SqlEdition]
		 ,s.[PhysicalCPUs]
		 ,s.[logicalCPUs])
when matched then update set
          [DBServerID]						=	s.[DBServerID]
         ,[DNSHostName] 					=	s.[DNSHostName]
         ,[IPv4Address] 					=	s.[IPv4Address]
         ,[Description] 					=	s.[Description]
         ,[OperatingSystem]					=	s.[OperatingSystem]
         ,[WhenCreated]						=	s.[WhenCreated]
         ,[SessionCollectionInterval]		=	s.[SessionCollectionInterval]
		 ,[lastPoll]						=	s.[lastPoll]
		 ,[lastreboot]						=	s.[lastreboot]
		 ,[SqlVersion]						=	s.[SqlVersion]
		 ,[Domain]							=	s.[Domain]
		 ,[SqlEdition]						=	s.[SqlEdition]
		 ,[PhysicalCPUs]					=	s.[PhysicalCPUs]
		 ,[logicalCPUs]						=	s.[logicalCPUs]
;

'
EXEC sys.sp_executesql @command
"
Invoke-Sqlcmd2 -ServerInstance "localhost"  -Query $MsSQLMerge

        }
		}
		}
  #  ELSE
       # {
       # } 
        }
     # CATCH{  }
      #  }
