USE [master]
GO

CREATE FUNCTION [dbo].[Separator]
(@str NVARCHAR(MAX),@sepr NVARCHAR(5))
RETURNS @table TABLE (ID INT IDENTITY(1,1), [Value] NVARCHAR(150))
AS
BEGIN
DECLARE 
@word   NVARCHAR(150), 
@len    INT, 
@s_ind  INT, 
@f_ind  INT
--
SET @len  = LEN(@str)
SET @f_ind = 1

WHILE @f_ind > 0
BEGIN
SET @f_ind = CASE WHEN CHARINDEX(@sepr,@str)-1 < 0 THEN 0 ELSE CHARINDEX(@sepr,@str)-1 END
SET @s_ind = CHARINDEX(@sepr,@str)+1
SET @len   = LEN(@str)
SET @word  = CASE WHEN SUBSTRING(@str , 1, @f_ind) = '' THEN @str ELSE SUBSTRING(@str , 1, @f_ind) END
SET @str   = SUBSTRING(@str , @s_ind,@len )

INSERT INTO @table 
SELECT @word
END

RETURN
END
