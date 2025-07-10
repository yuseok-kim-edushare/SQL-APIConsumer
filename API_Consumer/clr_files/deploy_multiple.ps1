# PowerShell script to deploy SQL-APIConsumer to multiple databases
# This script runs the single database deployment script against multiple target databases

param(
    [string]$ServerInstance = "localhost",
    [string]$DllPath = "C:\CLR\API_Consumer.dll",
    [string[]]$TargetDatabases = @("master", "db1")
)

# Verify SQL Module is available
if (!(Get-Module -ListAvailable -Name SqlServer)) {
    Write-Error "SqlServer PowerShell module is not installed. Install it with: Install-Module -Name SqlServer"
    exit 1
}

Import-Module SqlServer

# SQL Script template
$sqlScript = @"
-- SQL Server CLR Assembly Deployment Script - Single Database Version
-- SQL-APIConsumer

-- =============================================
-- Enable CLR (run once per instance)
-- =============================================
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;

-- =============================================
-- Trust assemblies (run once per instance)
-- =============================================
USE [{0}];

-- Trust API_Consumer assembly
DECLARE @hash VARBINARY(64);
SELECT @hash = HASHBYTES('SHA2_512', BulkColumn)
FROM OPENROWSET(BULK '$DllPath', SINGLE_BLOB) AS x;

IF NOT EXISTS (SELECT * FROM sys.trusted_assemblies WHERE [hash] = @hash)
BEGIN
    EXEC sys.sp_add_trusted_assembly @hash = @hash, @description = N'SQL-APIConsumer Assembly';
    PRINT 'API_Consumer assembly hash added to trusted assemblies.';
END
ELSE
BEGIN
    PRINT 'API_Consumer assembly hash already exists in trusted assemblies.';
END

-- =============================================
-- Switch to target database: {0}
-- =============================================
USE [{0}];

PRINT 'Deploying to database: {0}';

-- =============================================
-- Clean up existing objects
-- =============================================

-- Drop existing stored procedures
IF OBJECT_ID('dbo.APICaller_WebMethod) IS NOT NULL DROP PROCEDURE dbo.APICaller_WebMethod;
IF OBJECT_ID('dbo.APICaller_Web_Extended) IS NOT NULL DROP PROCEDURE dbo.APICaller_Web_Extended;
IF OBJECT_ID('dbo.APICaller_GET) IS NOT NULL DROP PROCEDURE dbo.APICaller_GET;
IF OBJECT_ID('dbo.APICaller_POST) IS NOT NULL DROP PROCEDURE dbo.APICaller_POST;
IF OBJECT_ID('dbo.APICaller_POSTAuth) IS NOT NULL DROP PROCEDURE dbo.APICaller_POSTAuth;
IF OBJECT_ID('dbo.APICaller_GETAuth) IS NOT NULL DROP PROCEDURE dbo.APICaller_GETAuth;
IF OBJECT_ID('dbo.APICaller_GET_Headers) IS NOT NULL DROP PROCEDURE dbo.APICaller_GET_Headers;
IF OBJECT_ID('dbo.APICaller_GET_Headers_BODY) IS NOT NULL DROP PROCEDURE dbo.APICaller_GET_Headers_BODY;
IF OBJECT_ID('dbo.APICaller_POST_Headers) IS NOT NULL DROP PROCEDURE dbo.APICaller_POST_Headers;
IF OBJECT_ID('dbo.APICaller_POST_JsonBody_Header) IS NOT NULL DROP PROCEDURE dbo.APICaller_POST_JsonBody_Header;
IF OBJECT_ID('dbo.APICaller_GET_Extended) IS NOT NULL DROP PROCEDURE dbo.APICaller_GET_Extended;
IF OBJECT_ID('dbo.APICaller_POST_Extended) IS NOT NULL DROP PROCEDURE dbo.APICaller_POST_Extended;
IF OBJECT_ID('dbo.APICaller_POST_Encoded) IS NOT NULL DROP PROCEDURE dbo.APICaller_POST_Encoded;

-- Drop existing functions
IF OBJECT_ID('dbo.Create_HMACSHA256') IS NOT NULL DROP FUNCTION dbo.Create_HMACSHA256;
IF OBJECT_ID('dbo.GetTimestamp') IS NOT NULL DROP FUNCTION dbo.GetTimestamp;
IF OBJECT_ID('dbo.fn_GetBytes') IS NOT NULL DROP FUNCTION dbo.fn_GetBytes;

PRINT 'Dropped existing procedures and functions';

-- Drop existing assemblies
IF EXISTS (SELECT * FROM sys.assemblies WHERE name = 'API_Consumer') 
    DROP ASSEMBLY [API_Consumer];

PRINT 'Dropped existing assemblies';

-- =============================================
-- Create assembly
-- =============================================

-- Create API_Consumer assembly
CREATE ASSEMBLY [API_Consumer] 
FROM '$DllPath'
WITH PERMISSION_SET = UNSAFE;

PRINT 'Created API_Consumer assembly';

-- =============================================
-- Create stored procedures
-- =============================================

PRINT 'Creating stored procedures...';
GO

-- APICaller_WebMethod
CREATE PROCEDURE dbo.APICaller_WebMethod
    @httpMethod NVARCHAR(MAX) NULL, 
    @URL NVARCHAR(MAX) NULL, 
    @JsonBody NVARCHAR(MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_WebMethod];
GO

-- APICaller_Web_Extended
CREATE PROCEDURE dbo.APICaller_Web_Extended
    @httpMethod NVARCHAR(MAX) NULL, 
    @URL NVARCHAR(MAX) NULL, 
    @Headers NVARCHAR(MAX) NULL, 
    @JsonBody NVARCHAR(MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_Web_Extended];
GO

-- APICaller_GET
CREATE PROCEDURE dbo.APICaller_GET
    @URL NVARCHAR(MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_GET];
GO

-- APICaller_POST
CREATE PROCEDURE dbo.APICaller_POST
    @URL NVARCHAR(MAX) NULL, 
    @JsonBody NVARCHAR(MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_POST];
GO

-- APICaller_POSTAuth
CREATE PROCEDURE dbo.APICaller_POSTAuth
    @URL NVARCHAR(MAX) NULL, 
    @Token NVARCHAR(MAX) NULL, 
    @JsonBody NVARCHAR(MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_POST_Auth];
GO

-- APICaller_GETAuth
CREATE PROCEDURE dbo.APICaller_GETAuth
    @URL NVARCHAR(MAX) NULL, 
    @Token NVARCHAR(MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_GET_Auth];
GO

-- APICaller_GET_Headers
CREATE PROCEDURE dbo.APICaller_GET_Headers
    @URL NVARCHAR(MAX) NULL, 
    @Headers NVARCHAR(MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_GET_Headers];
GO

-- APICaller_GET_Headers_BODY
CREATE PROCEDURE dbo.APICaller_GET_Headers_BODY
    @URL NVARCHAR(MAX) NULL, 
    @JsonBody NVARCHAR(MAX) NULL, 
    @Headers NVARCHAR(MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].APICaller_GET_JsonBody_Header;
GO

-- APICaller_POST_Headers
CREATE PROCEDURE dbo.APICaller_POST_Headers
    @URL NVARCHAR(MAX) NULL, 
    @Headers NVARCHAR(MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].APICaller_POST_Headers;
GO

-- APICaller_POST_JsonBody_Header
CREATE PROCEDURE dbo.APICaller_POST_JsonBody_Header
    @URL NVARCHAR(MAX), 
    @Headers NVARCHAR(MAX), 
    @jSON NVARCHAR(MAX)
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].APICaller_POST_JsonBody_Headers;
GO

-- APICaller_GET_Extended
CREATE PROCEDURE dbo.APICaller_GET_Extended
    @URL NVARCHAR(MAX) NULL, 
    @JsonBody NVARCHAR(MAX) NULL, 
    @Headers NVARCHAR(MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_GET_Extended];
GO

-- APICaller_POST_Extended
CREATE PROCEDURE dbo.APICaller_POST_Extended
    @URL NVARCHAR(MAX) NULL, 
    @Headers NVARCHAR(MAX) NULL, 
    @JsonBody NVARCHAR(MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].[APICaller_POST_Extended];
GO

-- APICaller_POST_Encoded
CREATE PROCEDURE dbo.APICaller_POST_Encoded
    @URL NVARCHAR(MAX) NULL, 
    @Headers NVARCHAR(MAX) NULL, 
    @JsonBody NVARCHAR(MAX) NULL
AS EXTERNAL NAME [API_Consumer].[StoredProcedures].APICaller_POST_Encoded;
GO

-- =============================================
-- Create functions
-- =============================================

PRINT 'Creating functions...';
Go

-- Create_HMACSHA256
CREATE FUNCTION dbo.Create_HMACSHA256 
(
    @message NVARCHAR(MAX) NULL, 
    @SecretKey NVARCHAR(MAX) NULL
) 
RETURNS NVARCHAR(MAX) 
AS EXTERNAL NAME [API_Consumer].[UserDefinedFunctions].[Create_HMACSHA256];
GO

-- GetTimestamp
CREATE FUNCTION dbo.GetTimestamp() 
RETURNS NVARCHAR(MAX) 
AS EXTERNAL NAME [API_Consumer].[UserDefinedFunctions].[GetTimestamp];
GO

-- fn_GetBytes
CREATE FUNCTION dbo.fn_GetBytes 
(
    @value NVARCHAR(MAX) NULL
) 
RETURNS NVARCHAR(MAX) 
AS EXTERNAL NAME [API_Consumer].[UserDefinedFunctions].fn_GetBytes;
GO

PRINT 'Deployment completed for database: {0}';
"@

# Verify DLL exists
if (!(Test-Path $DllPath)) {
    Write-Error "DLL file not found at: $DllPath"
    exit 1
}

Write-Host "Starting deployment to multiple databases..." -ForegroundColor Green
Write-Host "Server: $ServerInstance" -ForegroundColor Yellow
Write-Host "DLL Path: $DllPath" -ForegroundColor Yellow
Write-Host "Target Databases: $($TargetDatabases -join ', ')" -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$errorCount = 0
$results = @()

foreach ($database in $TargetDatabases) {
    Write-Host "Deploying to database: $database" -ForegroundColor Cyan
    
    try {
        # Format the SQL script with the current database name
        $currentSql = $sqlScript -f $database
        
        # Execute the SQL script
        $result = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $database -Query $currentSql -Verbose -ErrorAction Stop
        
        Write-Host "✓ Successfully deployed to $database" -ForegroundColor Green
        $successCount++
        
        $results += [PSCustomObject]@{
            Database = $database
            Status = "Success"
            Message = "Deployment completed successfully"
        }
    }
    catch {
        Write-Host "✗ Failed to deploy to $database" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
        
        $results += [PSCustomObject]@{
            Database = $database
            Status = "Failed"
            Message = $_.Exception.Message
        }
    }
    
    Write-Host ""
}

# Summary
Write-Host "=== DEPLOYMENT SUMMARY ===" -ForegroundColor Magenta
Write-Host "Total databases: $($TargetDatabases.Count)" -ForegroundColor White
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $errorCount" -ForegroundColor Red
Write-Host ""

# Display detailed results
$results | Format-Table -AutoSize

if ($errorCount -eq 0) {
    Write-Host "All deployments completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Some deployments failed. Please check the errors above." -ForegroundColor Red
    exit 1
} 