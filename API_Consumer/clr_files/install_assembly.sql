-- This SQL script is for old version of this API Consumer.
-- It is used to re-install the assembly and stored procedures and functions.
-- It is used to update the assembly to the new version.
-- Cause of change by New version using IL-repack, so we need to re-install the assembly.
-- also you can use this for install first time


sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'clr enabled', 1;
GO
RECONFIGURE;
GO
USE [master];
GO
-- =============================================
-- Create a log table (temporary)
-- =============================================
IF OBJECT_ID('tempdb..#ErrorLog') IS NOT NULL DROP TABLE #ErrorLog;

CREATE TABLE #ErrorLog (
    dbname NVARCHAR(128),
    error_message NVARCHAR(MAX),
    error_time DATETIME DEFAULT GETDATE()
);
-- =============================================
-- Define DLL Path
-- =============================================
DECLARE @dll_path NVARCHAR(260) = N'C:\CLR\API_Consumer.dll';  -- <<<< SET YOUR PATH HERE

-- =============================================
-- Trust the assembly file (at the instance level)
-- =============================================
DECLARE @dynamic_sql NVARCHAR(MAX);

SET @dynamic_sql = '
    DECLARE @hash VARBINARY(64);
    SELECT @hash = HASHBYTES(''SHA2_512'', BulkColumn)
    FROM OPENROWSET(BULK ''' + @dll_path + ''', SINGLE_BLOB) AS x;

    EXEC sys.sp_add_trusted_assembly @hash = @hash, @description = N''SecureLibrary-SQL Assembly'';
';
EXEC(@dynamic_sql);

-- =============================================
-- Loop through the target databases
-- =============================================

DECLARE @databases TABLE (dbname NVARCHAR(128));
INSERT INTO @databases (dbname)
VALUES ('db1'), ('db2'), ('db3'); -- <<<< PUT YOUR DATABASE NAMES HERE

DECLARE @db NVARCHAR(128);

DECLARE db_cursor CURSOR FOR
SELECT dbname FROM @databases;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @db;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        -- Build dynamic SQL for each DB
        SET @dynamic_sql = '
        USE [' + @db + '];

        -- =============================================
        -- Drop dependent stored procedures and functions
        -- =============================================
        IF OBJECT_ID(''[dbo].[APICaller_WebMethod]'') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_WebMethod];
        IF OBJECT_ID(''[dbo].[APICaller_Web_Extended]'') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_Web_Extended];
        IF OBJECT_ID(''[dbo].[APICaller_GET]'') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_GET];
        IF OBJECT_ID(''[dbo].[APICaller_POST]'') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_POST];
        IF OBJECT_ID(''[dbo].[APICaller_POSTAuth]'') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_POSTAuth];
        IF OBJECT_ID(''[dbo].[APICaller_GETAuth]'') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_GETAuth];
        IF OBJECT_ID(''[dbo].[APICaller_GET_Headers]'') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_GET_Headers];
        IF OBJECT_ID(''[dbo].[APICaller_GET_Headers_BODY]'') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_GET_Headers_BODY];
        IF OBJECT_ID(''[dbo].[APICaller_POST_Headers]'') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_POST_Headers];
        IF OBJECT_ID(''[dbo].[APICaller_POST_JsonBody_Header]'') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_POST_JsonBody_Header];
        IF OBJECT_ID(''[dbo].[APICaller_GET_Extended]'') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_GET_Extended];
        IF OBJECT_ID(''[dbo].[APICaller_POST_Extended]'') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_POST_Extended];
        IF OBJECT_ID(''[dbo].[APICaller_POST_Encoded]'') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_POST_Encoded];

        IF OBJECT_ID(''[dbo].[Create_HMACSHA256]'') IS NOT NULL DROP FUNCTION [dbo].[Create_HMACSHA256];
        IF OBJECT_ID(''[dbo].[GetTimestamp]'') IS NOT NULL DROP FUNCTION [dbo].[GetTimestamp];
        IF OBJECT_ID(''[dbo].[fn_GetBytes]'') IS NOT NULL DROP FUNCTION [dbo].[fn_GetBytes];

        -- =============================================
        -- Drop assemblies
        -- =============================================
        IF EXISTS (SELECT * FROM sys.assemblies WHERE name = ''API_Consumer'') DROP ASSEMBLY [API_Consumer];
        IF EXISTS (SELECT * FROM sys.assemblies WHERE name = ''Newtonsoft.Json'') DROP ASSEMBLY [Newtonsoft.Json];
        IF EXISTS (SELECT * FROM sys.assemblies WHERE name = ''System.Runtime.Serialization'') DROP ASSEMBLY [System.Runtime.Serialization];
        IF EXISTS (SELECT * FROM sys.assemblies WHERE name = ''SMDiagnostics'') DROP ASSEMBLY [SMDiagnostics];

        -- =============================================
        -- Create the updated assembly
        -- =============================================
        CREATE ASSEMBLY [API_Consumer]
        AUTHORIZATION dbo
        FROM ''' + @dll_path + '''
        WITH PERMISSION_SET = UNSAFE;

        -- =============================================
        -- Recreate Procedures and Functions
        -- =============================================

        CREATE PROCEDURE [dbo].[APICaller_WebMethod]
        @httpMethod NVARCHAR(MAX) NULL, @URL NVARCHAR(MAX) NULL, @JsonBody NVARCHAR(MAX) NULL
        AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_WebMethod];

        CREATE PROCEDURE [dbo].[APICaller_Web_Extended]
        @httpMethod NVARCHAR(MAX) NULL, @URL NVARCHAR(MAX) NULL, @Headers NVARCHAR(MAX) NULL, @JsonBody NVARCHAR(MAX) NULL
        AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_Web_Extended];

        CREATE FUNCTION [dbo].[Create_HMACSHA256]
        (@message NVARCHAR(MAX) NULL, @SecretKey NVARCHAR(MAX) NULL)
        RETURNS NVARCHAR(MAX)
        AS EXTERNAL NAME [API_Consumer].[UserDefinedFunctions].[Create_HMACSHA256];

        CREATE FUNCTION [dbo].[GetTimestamp]()
        RETURNS NVARCHAR(MAX)
        AS EXTERNAL NAME [API_Consumer].[UserDefinedFunctions].[GetTimestamp];

        CREATE FUNCTION [dbo].[fn_GetBytes]
        (@value NVARCHAR(MAX) NULL)
        RETURNS NVARCHAR(MAX)
        AS EXTERNAL NAME [API_Consumer].[UserDefinedFunctions].[fn_GetBytes];

        CREATE PROCEDURE [dbo].[APICaller_GET]
        @URL NVARCHAR(MAX) NULL
        AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_GET];

        CREATE PROCEDURE [dbo].[APICaller_POST]
        @URL NVARCHAR(MAX) NULL, @JsonBody NVARCHAR(MAX) NULL
        AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_POST];

        CREATE PROCEDURE [dbo].[APICaller_POSTAuth]
        @URL NVARCHAR(MAX) NULL, @Token NVARCHAR(MAX) NULL, @JsonBody NVARCHAR(MAX) NULL
        AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_POST_Auth];

        CREATE PROCEDURE [dbo].[APICaller_GETAuth]
        @URL NVARCHAR(MAX) NULL, @Token NVARCHAR(MAX) NULL
        AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_GET_Auth];

        CREATE PROCEDURE [dbo].[APICaller_GET_Headers]
        @URL NVARCHAR(MAX) NULL, @Headers NVARCHAR(MAX) NULL
        AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_GET_Headers];

        CREATE PROCEDURE [dbo].[APICaller_GET_Headers_BODY]
        @URL NVARCHAR(MAX) NULL, @JsonBody NVARCHAR(MAX) NULL, @Headers NVARCHAR(MAX) NULL
        AS EXTERNAL NAME [API_Consumer].[StoredProcedures].APICaller_GET_JsonBody_Header;

        CREATE PROCEDURE [dbo].[APICaller_POST_Headers]
        @URL NVARCHAR(MAX) NULL, @Headers NVARCHAR(MAX) NULL
        AS EXTERNAL NAME [API_Consumer].[StoredProcedures].APICaller_POST_Headers;

        CREATE PROCEDURE [dbo].[APICaller_POST_JsonBody_Header]
        @URL NVARCHAR(MAX), @Headers NVARCHAR(MAX), @jSON NVARCHAR(MAX)
        AS EXTERNAL NAME [API_Consumer].[StoredProcedures].APICaller_POST_JsonBody_Headers;

        CREATE PROCEDURE [dbo].[APICaller_GET_Extended]
        @URL NVARCHAR(MAX) NULL, @JsonBody NVARCHAR(MAX) NULL, @Headers NVARCHAR(MAX) NULL
        AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_GET_Extended];

        CREATE PROCEDURE [dbo].[APICaller_POST_Extended]
        @URL NVARCHAR(MAX) NULL, @Headers NVARCHAR(MAX) NULL, @JsonBody NVARCHAR(MAX) NULL
        AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_POST_Extended];

        CREATE PROCEDURE [dbo].[APICaller_POST_Encoded]
        @URL NVARCHAR(MAX) NULL, @Headers NVARCHAR(MAX) NULL, @JsonBody NVARCHAR(MAX) NULL
        AS EXTERNAL NAME [API_Consumer].[StoredProcedures].APICaller_POST_Encoded;
        ';

        EXEC sp_executesql @dynamic_sql;
    END TRY
    BEGIN CATCH
        -- Log the error
        INSERT INTO #ErrorLog (dbname, error_message)
        VALUES (@db, ERROR_MESSAGE());
    END CATCH;

    FETCH NEXT FROM db_cursor INTO @db;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- =============================================
-- See Errors if any
-- =============================================
SELECT * FROM #ErrorLog;
