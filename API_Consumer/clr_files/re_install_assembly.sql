-- This SQL script is for old version of this API Consumer.
-- It is used to re-install the assembly and stored procedures and functions.
-- It is used to update the assembly to the new version.
-- Cause of change by New version using IL-repack, so we need to re-install the assembly.
/* If this query works, you not need to run this query.
   ALTER ASSEMBLY API_Consumer
    FROM 'C:\CLR\API_Consumer.dll'
   WITH PERMISSION_SET = UNSAFE
 */

-- =============================================
-- Drop all dependent stored procedures and functions
-- =============================================
IF OBJECT_ID('[dbo].[APICaller_WebMethod]') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_WebMethod]
IF OBJECT_ID('[dbo].[APICaller_Web_Extended]') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_Web_Extended]
IF OBJECT_ID('[dbo].[APICaller_GET]') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_GET]
IF OBJECT_ID('[dbo].[APICaller_POST]') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_POST]
IF OBJECT_ID('[dbo].[APICaller_POSTAuth]') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_POSTAuth]
IF OBJECT_ID('[dbo].[APICaller_GETAuth]') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_GETAuth]
IF OBJECT_ID('[dbo].[APICaller_GET_Headers]') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_GET_Headers]
IF OBJECT_ID('[dbo].[APICaller_GET_Headers_BODY]') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_GET_Headers_BODY]
IF OBJECT_ID('[dbo].[APICaller_POST_Headers]') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_POST_Headers]
IF OBJECT_ID('[dbo].[APICaller_POST_JsonBody_Header]') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_POST_JsonBody_Header]
IF OBJECT_ID('[dbo].[APICaller_GET_Extended]') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_GET_Extended]
IF OBJECT_ID('[dbo].[APICaller_POST_Extended]') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_POST_Extended]
IF OBJECT_ID('[dbo].[APICaller_POST_Encoded]') IS NOT NULL DROP PROCEDURE [dbo].[APICaller_POST_Encoded]

IF OBJECT_ID('[dbo].[Create_HMACSHA256]') IS NOT NULL DROP FUNCTION [dbo].[Create_HMACSHA256]
IF OBJECT_ID('[dbo].[GetTimestamp]') IS NOT NULL DROP FUNCTION [dbo].[GetTimestamp]
IF OBJECT_ID('[dbo].[fn_GetBytes]') IS NOT NULL DROP FUNCTION [dbo].[fn_GetBytes]

-- =============================================
-- Drop the assembly
-- =============================================
IF EXISTS (SELECT * FROM sys.assemblies WHERE name = 'API_Consumer')
BEGIN
    DROP ASSEMBLY [API_Consumer]
END

-- =============================================
-- Create the assembly with the updated DLL
-- =============================================
CREATE ASSEMBLY [API_Consumer]
AUTHORIZATION dbo
FROM 'C:\CLR\API_Consumer.dll'
WITH PERMISSION_SET = UNSAFE

-- =============================================
-- Recreate the stored procedures and functions
-- =============================================
go
-- Main procedures (current version)
CREATE PROCEDURE [dbo].[APICaller_WebMethod]
@httpMethod NVARCHAR (MAX) NULL, @URL NVARCHAR (MAX) NULL, @JsonBody NVARCHAR (MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_WebMethod]
go
CREATE PROCEDURE [dbo].[APICaller_Web_Extended]
@httpMethod NVARCHAR (MAX) NULL, @URL NVARCHAR (MAX) NULL, @Headers NVARCHAR (MAX) NULL, @JsonBody NVARCHAR (MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_Web_Extended]
go
-- Utility functions
CREATE FUNCTION [dbo].[Create_HMACSHA256]
(@message NVARCHAR (MAX) NULL, @SecretKey NVARCHAR (MAX) NULL)
RETURNS NVARCHAR (MAX)
AS EXTERNAL NAME [API_Consumer].[UserDefinedFunctions].[Create_HMACSHA256]
go
CREATE FUNCTION [dbo].[GetTimestamp]()
RETURNS NVARCHAR (MAX)
AS EXTERNAL NAME [API_Consumer].[UserDefinedFunctions].[GetTimestamp]
go
CREATE FUNCTION [dbo].fn_GetBytes
(@value NVARCHAR (MAX) NULL)
RETURNS NVARCHAR (MAX)
AS EXTERNAL NAME [API_Consumer].[UserDefinedFunctions].fn_GetBytes
go
-- Legacy procedures (deprecated but still supported)
CREATE PROCEDURE [dbo].[APICaller_GET]
@URL NVARCHAR (MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_GET]
go
CREATE PROCEDURE [dbo].[APICaller_POST]
@URL NVARCHAR (MAX) NULL, @JsonBody NVARCHAR (MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_POST]
go
CREATE PROCEDURE [dbo].[APICaller_POSTAuth]
@URL NVARCHAR (MAX) NULL, @Token NVARCHAR (MAX) NULL, @JsonBody NVARCHAR (MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_POST_Auth]
go
CREATE PROCEDURE [dbo].[APICaller_GETAuth]
@URL NVARCHAR (MAX) NULL, @Token NVARCHAR (MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_GET_Auth]
go
CREATE PROCEDURE [dbo].[APICaller_GET_Headers]
@URL NVARCHAR (MAX) NULL, @Headers NVARCHAR (MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_GET_Headers]
go
CREATE PROCEDURE [dbo].[APICaller_GET_Headers_BODY]
@URL NVARCHAR (MAX) NULL, @JsonBody NVARCHAR (MAX) NULL, @Headers NVARCHAR (MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].APICaller_GET_JsonBody_Header
go
CREATE PROCEDURE [dbo].[APICaller_POST_Headers]
@URL NVARCHAR (MAX) NULL, @Headers NVARCHAR (MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].APICaller_POST_Headers
go
CREATE PROCEDURE [dbo].[APICaller_POST_JsonBody_Header]
@URL NVARCHAR (MAX), @Headers NVARCHAR (MAX), @jSON NVARCHAR (MAX)
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].APICaller_POST_JsonBody_Headers
go
CREATE PROCEDURE [dbo].[APICaller_GET_Extended]
@URL NVARCHAR (MAX) NULL, @JsonBody NVARCHAR (MAX) NULL, @Headers NVARCHAR (MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_GET_Extended]
go
CREATE PROCEDURE [dbo].[APICaller_POST_Extended]
@URL NVARCHAR (MAX) NULL, @Headers NVARCHAR (MAX) NULL, @JsonBody NVARCHAR (MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_POST_Extended]
go
CREATE PROCEDURE [dbo].APICaller_POST_Encoded
@URL NVARCHAR (MAX) NULL, @Headers NVARCHAR (MAX) NULL, @JsonBody NVARCHAR (MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].APICaller_POST_Encoded