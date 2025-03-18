-- Enable CLR in SQL Server (if not already enabled)
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'clr enabled', 1;
GO
RECONFIGURE;
GO


-- SQL script for registering merged assembly 
USE [master] 
GO 
DECLARE @hash varbinary(64) = (SELECT HASHBYTES('SHA2_512', BulkColumn) 
                              FROM OPENROWSET(BULK 'C:\CLR\API_Consumer.dll', SINGLE_BLOB) AS x);
EXEC sys.sp_add_trusted_assembly @hash = @hash, @description = N'SecureLibrary-SQL Assembly';
GO
-- Drop existing assembly if it exists 
IF EXISTS (SELECT * FROM sys.assemblies WHERE name = 'API_Consumer') 
BEGIN 
    DROP ASSEMBLY [API_Consumer] 
END 
GO 
CREATE ASSEMBLY [API_Consumer] FROM 'C:\CLR\API_Consumer.dll' WITH PERMISSION_SET = UNSAFE; 
GO 
