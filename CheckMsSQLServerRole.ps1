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

$MirrorStopSync="declare @command nvarchar(max)
set @command= 
'
select ServerName from DBAMonitoring.[dbo].[DB_ServerMain]
where 1=1
and sqlversion !=''''
and domain = ''dpc''
--and servername in (''n7701-ppk314'',''n7701-ppk315'')
--and servername = ''n7701-ais481''
'
exec  sys.sp_executesql  @command
"
[array]$ServerList=Invoke-Sqlcmd2 -ServerInstance localhost -Query $MirrorStopSync 
foreach ($ServerInstance in $ServerList)
{
$ServerName=$ServerInstance.ServerName
$SimpleDate=Get-Date -Format hh:mm:ss.ms
Write-Host "Это сервер" $ServerInstance.ServerName "Опросили в:" $SimpleDate

#ОбновлениеВерсии MSSQL
<#
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
#ОбновлениеВерсии MSSQL
#>

$CheckMsSqlServerRole="
declare @command nvarchar(max)
set @command=
'
declare @version varchar(20)
declare @IPAddressQuery nvarchar(20)
set @IPAddressQuery =(SELECT dec.local_net_address
FROM sys.dm_exec_connections AS dec
WHERE dec.session_id = @@SPID)
set @version = convert(varchar(20),serverproperty(''ProductVersion''),2)
if @version < ''11''
begin
print ''Это версия 2008''
IF  
(
select COUNT(*) 
from sys.database_mirroring
 where database_id > 4
 and mirroring_role_desc is not null
 and mirroring_partner_instance is not null
 ) > 0
BEGIN
select distinct 
convert(varchar(20),serverproperty(''ServerName''),2) as Servername
,ServerIp=@IPAddressQuery
,HA_TYPE =''MIRRORING''
,mirroring_role_desc as ServerRole
,mirroring_partner_instance as  ServerPartnerName
,ServerPartnerAddress =''''
,WSFCName = null
,WSFCIpAddress = null
,ListenerName = null
,IpAddressListener = null
from sys.database_mirroring
where database_id > 4
and mirroring_role_desc is not null
and mirroring_partner_instance is not null
END
ELSE
select 
convert(varchar(20),serverproperty(''ServerName''),2) as ServerName
,ServerIp=@IPAddressQuery
,HA_TYPE =''StandAlone''
,ServerRole=null
,ServerPartherName=null
,ServerPartnerAddress=null
,WSFCName=null
,WSFCIpAddress=null
,ListenerName=null
,ListenerIpAddress=null
END
ELSE
BEGIN
IF 
(
select count(*) from  sys.availability_group_listeners
) > 0
and
( select count(*)
 from 
 sys.dm_hadr_cluster as Cluster
 ,sys.dm_hadr_cluster_members as ClusterMember
 ,sys.availability_group_listener_ip_addresses as ListenerIP
 join sys.availability_group_listeners ListenerDNS on ListenerDNS.listener_id=ListenerIP.listener_id
 join sys.dm_hadr_availability_replica_states as RepStates on RepStates.group_id=ListenerDNS.group_id
  where ClusterMember.member_type=0
 and  ClusterMember.member_name!=convert(varchar(20),serverproperty(''ServerName''),2)
 and RepStates.Is_local=1
 and RepStates.role_desc=''PRIMARY''
 ) > 0
BEGIN
select distinct
convert(varchar(20),serverproperty(''ServerName''),2) as ServerName
,ServerIp=@IPAddressQuery
,HA_TYPE =''Always ON''
,ServerRole=RepStates.role_desc
,ClusterMember.member_name as ServerPartnerName
,ServerPartnerAddress = ''''
,cluster.cluster_name as WSFCName
,WSFCIpAddress=''''
,ListenerDNS.dns_name as ListenerName
,listenerIP.ip_address as IpAddressListener

 from 
 sys.dm_hadr_cluster as Cluster
 ,sys.dm_hadr_cluster_members as ClusterMember
 ,sys.availability_group_listener_ip_addresses as ListenerIP
 join sys.availability_group_listeners ListenerDNS on ListenerDNS.listener_id=ListenerIP.listener_id
 join sys.dm_hadr_availability_replica_states as RepStates on RepStates.group_id=ListenerDNS.group_id
  where ClusterMember.member_type=0
 and  ClusterMember.member_name!=convert(varchar(20),serverproperty(''ServerName''),2)
 and RepStates.Is_local=1
 and RepStates.role_desc=''PRIMARY''
--END проверки на Always On
END
ELSE
IF 
(
select count(*) from  sys.availability_group_listeners
) > 0
and
( select count(*)
 from 
 sys.dm_hadr_cluster as Cluster
 ,sys.dm_hadr_cluster_members as ClusterMember
 ,sys.availability_group_listener_ip_addresses as ListenerIP
 join sys.availability_group_listeners ListenerDNS on ListenerDNS.listener_id=ListenerIP.listener_id
 join sys.dm_hadr_availability_replica_states as RepStates on RepStates.group_id=ListenerDNS.group_id
  where ClusterMember.member_type=0
 and  ClusterMember.member_name!=convert(varchar(20),serverproperty(''ServerName''),2)
 and RepStates.Is_local=1
 and RepStates.role_desc=''SECONDARY''
 ) > 0
BEGIN
select distinct
convert(varchar(20),serverproperty(''ServerName''),2) as ServerName
,ServerIp=@IPAddressQuery
,HA_TYPE =''Always ON''
,ServerRole=RepStates.role_desc
,ClusterMember.member_name as ServerPartnerName
,ServerPartnerAddress = ''''
,cluster.cluster_name as WSFCName
,WSFCIpAddress=''''
,ListenerDNS.dns_name as ListenerName
,listenerIP.ip_address as IpAddressListener

 from 
 sys.dm_hadr_cluster as Cluster
 ,sys.dm_hadr_cluster_members as ClusterMember
 ,sys.availability_group_listener_ip_addresses as ListenerIP
 join sys.availability_group_listeners ListenerDNS on ListenerDNS.listener_id=ListenerIP.listener_id
 join sys.dm_hadr_availability_replica_states as RepStates on RepStates.group_id=ListenerDNS.group_id
  where ClusterMember.member_type=0
 and  ClusterMember.member_name!=convert(varchar(20),serverproperty(''ServerName''),2)
 and RepStates.Is_local=1
 and RepStates.role_desc=''SECONDARY''
--END проверки на Always On
END
ELSE
BEGIN
print ''СтандАлоне''
select 
convert(varchar(20),serverproperty(''ServerName''),2) as ServerName
,ServerIp=@IPAddressQuery
,HA_TYPE =''StandAlone''
,ServerRole=null
,ServerPartherName=null
,ServerPartnerAddress=null
,WSFCName=null
,WSFCIpAddress=null
,ListenerName=null
,ListenerIpAddress=null
END
END
'
exec sys.sp_executesql @command
"
$dbohigh_Availability=Invoke-Sqlcmd2 -ServerInstance $ServerName -Query $CheckMsSqlServerRole 

#Если листенеров много разбираем каждый
foreach ($EachListener in $dbohigh_Availability)
{
#Write-Host $dbohigh_Availability.ListenerName
#Write-Host $Listener.ListenerName

#Получаем IP Партнера
IF ($EachListener.HA_TYPE -ne "StandAlone")
{
$ServerNameParner=$EachListener.ServerPartnerName
$ipsPartner = [System.Net.Dns]::GetHostAddresses("$ServerNameParner")
$EachListener.ServerPartnerAddress=$ipsPartner.SyncRoot.IPAddressToString
}
#Получаем IP WSFC
$WSFCName=$EachListener.WSFCName
IF ($EachListener.HA_TYPE -eq "Always ON")
{
IF ($WSFCName.Length -ge 1)
{
$ipsWSFC = [System.Net.Dns]::GetHostAddresses("$WSFCName")
$EachListener.WSFCIpAddress=$ipsWSFC.SyncRoot.IPAddressToString
}
}
#Получаем IP Listener
$ListenerName=$EachListener.ListenerName
IF ($EachListener.HA_TYPE -eq "Always ON")
	{
		IF ($ListenerName.Length  -ge 1)
			{
				$ipsListener = [System.Net.Dns]::GetHostAddresses("$ListenerName")
				$EachListener.IpAddressListener=$ipsListener.SyncRoot.IPAddressToString
			}
	}
#Выводим результат

$serverName=$EachListener.ServerName
$ServerIp=$EachListener.ServerIp
$HA_TYPE=$EachListener.HA_TYPE
$ServerRole=$EachListener.ServerRole
$ServerPartnerName=$EachListener.ServerPartnerName
$ServerPartnerAddress=$EachListener.ServerPartnerAddress
$WSFCName=$EachListener.WSFCName 
$WSFCIpAddress=$EachListener.WSFCIpAddress
$ListenerName=$EachListener.ListenerName
$IpAddressListener=$EachListener.IpAddressListener


$high_AvailabilityMergeToLocal="
declare @command nvarchar(max)
set @command= 
'
use [DBAMonitoring]
merge [DBAMonitoring].[dbo].[high_Availability] t using
(
    Select * from
    (
     VALUES 
	 (''$ServerName''
	 ,''$ServerIp''
	 ,''$HA_TYPE''
	 ,''$ServerRole''
	 ,''$ServerPartnerName''
	 ,''$ServerPartnerAddress''
	 ,''$WSFCName''
	 ,''$WSFCIpAddress''
	 ,''$ListenerName''
	 ,''$IpAddressListener''
	 )
	 ) s ([ServerName]
	 ,[ServerIP]
      ,[HA_type]
      ,[ServerRole]
      ,[ServerPartnerName]
      ,[ServerPartnerAddress]
      ,[WSFCName]
      ,[WSFCIpAddress]
      ,[ListenerName]
      ,[ListenerIpAddress])
         ) s
         on t.servername=s.servername
		 and
		 t.ListenerName=s.ListenerName
 when not matched by target then
          INSERT ([ServerName]
	 ,[ServerIP]
      ,[HA_type]
      ,[ServerRole]
      ,[ServerPartnerName]
      ,[ServerPartnerAddress]
      ,[WSFCName]
      ,[WSFCIpAddress]
      ,[ListenerName]
      ,[ListenerIpAddress])
         VALUES
         (
	  s.[ServerName]
	 ,s.[ServerIP]
      ,s.[HA_type]
      ,s.[ServerRole]
      ,s.[ServerPartnerName]
      ,s.[ServerPartnerAddress]
      ,s.[WSFCName]
      ,s.[WSFCIpAddress]
      ,s.[ListenerName]
      ,s.[ListenerIpAddress])
when matched then update set
       [ServerIP]=s.[ServerIP]
      ,[HA_type]=s.[HA_type]
      ,[ServerRole]=s.[ServerRole]
      ,[ServerPartnerName]=s.[ServerPartnerName]
      ,[ServerPartnerAddress]=s.[ServerPartnerAddress]
      ,[WSFCName]=s.[WSFCName]
      ,[WSFCIpAddress]=s.[WSFCIpAddress]
      ,[ListenerName]=s.[ListenerName]
      ,[ListenerIpAddress]=s.[ListenerIpAddress]
	 
;

'
EXEC sys.sp_executesql @command

"
Invoke-Sqlcmd2 -ServerInstance "localhost"  -Query $high_AvailabilityMergeToLocal


}
}