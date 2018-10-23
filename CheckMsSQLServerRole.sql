declare @version varchar(20)
set @version = convert(varchar(20),serverproperty('ProductVersion'),2)
if @version < '11'
begin
print '��� ������ 2008'
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
@@SERVERNAME as Servername
,ServerIp=''
,HA_TYPE ='MIRRORING'
,mirroring_role_desc as ServerRole
,mirroring_partner_instance as  ServerPartnerName
,ServerPartnerAddress =''
,WSFCName = null
,WSFCIpAddress = null
,ListenerName = null
,IpAdressListener = null
from sys.database_mirroring
where database_id > 4
and mirroring_role_desc is not null
and mirroring_partner_instance is not null
END
ELSE
select 
@@SERVERNAME as ServerName
,ServerIP=''
,HA_TYPE ='StandAlone'
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
BEGIN
select distinct
@@servername as ServerName
,ServerIP=''
,HA_TYPE ='Always ON'
,ServerRole=RepStates.role_desc
,ClusterMember.member_name as MemberName
,ServerPartherAddress = ''
,cluster.cluster_name as WSFCName
,WSFCIpAddress=''
,ListenerDNS.dns_name as ListenerName
,listenerIP.ip_address as IpAdressListener

 from 
 sys.dm_hadr_cluster as Cluster
 ,sys.dm_hadr_cluster_members as ClusterMember
 ,sys.availability_group_listener_ip_addresses as ListenerIP
 join sys.availability_group_listeners ListenerDNS on ListenerDNS.listener_id=ListenerIP.listener_id
 join sys.dm_hadr_availability_replica_states as RepStates on RepStates.group_id=ListenerDNS.group_id
  where ClusterMember.member_type=0
 and  ClusterMember.member_name!=@@servername
 and RepStates.Is_local=1
--END �������� �� Always On
END
ELSE
BEGIN
print '����������'
select 
@@SERVERNAME
,ServerIP=''
,HA_TYPE ='StandAlone'
,ServerRole=null
,ServerPartherName=null
,ServerPartnerAddress=null
,WSFCName=null
,WSFCIpAddress=null
,ListenerName=null
,ListenerIpAddress=null
END
END
--�������� �� ������� 
--select SERVERPROPERTY('IsClustered')
--�������� �� ALWAYS ON
--select SERVERPROPERTY('IsHadrEnabled')

