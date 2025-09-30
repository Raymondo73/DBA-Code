-- Red flags: unexpected users/groups in sysadmin, securityadmin, serveradmin.

SELECT      r.name          AS ServerRole
,           p.name          AS PrincipalName
,           p.type_desc     AS PrincipalType   -- SQL_LOGIN, WINDOWS_LOGIN, WINDOWS_GROUP
,           p.is_disabled
FROM        sys.server_role_members m
JOIN        sys.server_principals   r ON r.principal_id = m.role_principal_id
JOIN        sys.server_principals   p ON p.principal_id = m.member_principal_id
ORDER BY    ServerRole
,           PrincipalName;
