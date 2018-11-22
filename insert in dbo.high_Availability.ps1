$ServerInstance="n7701-ktr011"
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
<#
##ОбновлениеВерсии SQL SQLVERSION
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
Write-Host "Это сервер" $ServerName "а версия" $Version

$UpdateVersion="declare @command nvarchar(max)
set @command= 
'
update [DBAMonitoring].[dbo].[DB_ServerMain]
set [sqlversion] = ''$Version''
where [ServerName] = ''$ServerInstance''
'
exec  sys.sp_executesql  @command
"
Invoke-Sqlcmd2 -ServerInstance Localhost -Query $UpdateVersion

#ОбновлениеВерсии SQL SQLVERSION

#>
$CheckMsSqlServerRole="
declare @command nvarchar(max)
set @command=
'
declare @version varchar(20)
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
,ServerIp=''''
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
,ServerIP=''''
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
 --and listenerdns.dns_name=''n7701-lsn035''
 
  
 
 ) > 0
BEGIN
select distinct
convert(varchar(20),serverproperty(''ServerName''),2) as ServerName
,ServerIP=''''
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
 --and listenerdns.dns_name=''n7701-lsn035''
 
 
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
 and listenerdns.dns_name=''n7701-lsn035''
 

 ) > 0
BEGIN
select top 1
convert(varchar(20),serverproperty(''ServerName''),2) as ServerName
,ServerIP=''''
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
 and listenerdns.dns_name=''n7701-lsn035''
 

--END проверки на Always On
END
ELSE
BEGIN
print ''СтандАлоне''
select 
convert(varchar(20),serverproperty(''ServerName''),2)as ServerName
,ServerIP=''''
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
$dbohigh_Availability=Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Query $CheckMsSqlServerRole 
$ipsLocal = [System.Net.Dns]::GetHostAddresses("$ServerInstance")
#$dbohigh_Availability.ServerIp=$ipsLocal.SyncRoot.IPAddressToString
$ServerIp1=$ipsLocal.SyncRoot.IPAddressToString
$dbohigh_Availability.ServerIp=$ServerIp1
write-host "BLABLABLA" $dbohigh_Availability.ServerIp "and" $ServerIp1
#Получаем IP Партнера
$ServerNameParner=$dbohigh_Availability.ServerPartnerName
$ipsPartner = [System.Net.Dns]::GetHostAddresses("$ServerNameParner")
$dbohigh_Availability.ServerPartnerAddress=$ipsPartner.SyncRoot.IPAddressToString
#Получаем IP WSFC
$WSFCName=$dbohigh_Availability.WSFCName
IF ($WSFCName.Length -ge 1)
{

$ipsWSFC = [System.Net.Dns]::GetHostAddresses("$WSFCName")
$dbohigh_Availability.WSFCIpAddress=$ipsWSFC.SyncRoot.IPAddressToString
}
#Получаем IP Listener
$ListenerName=$dbohigh_Availability.ListenerName
IF ($ListenerName.Length  -ge 1)
{
$ipsListener = [System.Net.Dns]::GetHostAddresses("$ListenerName")
$dbohigh_Availability.IpAddressListener=$ipsListener.SyncRoot.IPAddressToString
}
#Выводим результат
$dbohigh_Availability
$serverName=$dbohigh_Availability.ServerName
$ServerIp=$dbohigh_Availability.ServerIp
$HA_TYPE=$dbohigh_Availability.HA_TYPE
$ServerRole=$dbohigh_Availability.ServerRole
$ServerPartnerName=$dbohigh_Availability.ServerPartnerName
$ServerPartnerAddress=$dbohigh_Availability.ServerPartnerAddress
$WSFCName=$dbohigh_Availability.WSFCName 
$WSFCIpAddress=$dbohigh_Availability.WSFCIpAddress
$ListenerName=$dbohigh_Availability.ListenerName
$IpAddressListener=$dbohigh_Availability.IpAddressListener


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

