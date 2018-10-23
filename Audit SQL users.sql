SELECT SP1.[name] AS 'Login', 'Role: ' + SP2.[name] COLLATE DATABASE_DEFAULT AS 'ServerPermission','LoginOff'=case
when sp1.is_disabled = 1
then 'YES'
else 'NO'
end 
FROM sys.server_principals SP1 
  JOIN sys.server_role_members SRM 
    ON SP1.principal_id = SRM.member_principal_id 
  JOIN sys.server_principals SP2 
    ON SRM.role_principal_id = SP2.principal_id 
	where sp1.principal_id=1
	and sp1.is_disabled=0
UNION ALL 
SELECT SP.[name] AS 'Login' , SPerm.state_desc + ' ' + SPerm.permission_name COLLATE DATABASE_DEFAULT AS 'ServerPermission',
'LoginOff'=case 
when sp.is_disabled = 1
then 'YES'
else 'NO'
end 
  FROM sys.server_principals SP  
  JOIN sys.server_permissions SPerm  
    ON SP.principal_id = SPerm.grantee_principal_id  
where principal_id=1
and is_disabled=0
ORDER BY [Login], [ServerPermission]; 


--select *  FROM sys.server_principals,sys.server_role_members,sys.server_permissions