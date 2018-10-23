select distinct
		SYS.Netbios_Name0 as N'Имя сервера'
,		SYS.description0 as N'Описание'
,		SERV.Name0 as N'Сервис'
,		arp.DisplayName00
,		os.Caption0
from
		v_R_System SYS
join		v_GS_SERVICE SERV on SYS.ResourceID = SERV.ResourceID
join v_GS_OPERATING_SYSTEM os
		on os.ResourceID = sys.ResourceID
join	Add_Remove_Programs_64_DATA arp
		on arp.MachineID = os.ResourceID
where
		SERV.Name0 = 'MSSQLServer'
and		
		(
		arp.DisplayName00 like 'Microsoft SQL Server 2008 R2 (%'
or		arp.DisplayName00 like 'Microsoft SQL Server 2008 (%'
or		arp.DisplayName00 like 'Microsoft SQL Server 2012 (%'
or		arp.DisplayName00 like 'Microsoft SQL Server 2014 (%'
or		arp.DisplayName00 like 'Microsoft SQL Server 2016 (%'
		)
and		(
		SYS.Netbios_Name0 like 'n5001-%'
or		SYS.Netbios_Name0 like 'n5201-%'
or		SYS.Netbios_Name0 like 'n7701-%'
or		SYS.Netbios_Name0 like 'm9965-%'
		)