
USE [DocumotiveDW_CRM_V2_Warehouse];
GO

SELECT      dp.name AS DbUser
,           dp.sid AS DbUserSid
,           sp.name AS ServerLogin
,           sp.sid AS ServerSid
FROM        sys.database_principals dp
LEFT JOIN   sys.server_principals sp ON sp.name = dp.name
WHERE       dp.name = N'fusionrs';


ALTER USER fusionrs WITH LOGIN = fusionrs;
GO

SELECT      dp.name AS DbUser
,           dp.sid AS DbUserSid
,           sp.name AS ServerLogin
,           sp.sid AS ServerSid
FROM        sys.database_principals dp
LEFT JOIN   sys.server_principals sp ON sp.name = dp.name
WHERE       dp.name = N'fusionrs';