CREATE PROCEDURE [dbo].[sp_insert_sound]
(@P_status INT output, @id int, @filename NVARCHAR(1000), @bytes varbinary(max))
AS
BEGIN
DECLARE @sound VARBINARY(max), @sql NVARCHAR(max), @ParmDefinition NVARCHAR(50),
@name NVARCHAR(100), @extention VARCHAR(50), @file_exists int, @word_exists int

 select @name = substring(name, 1, charindex('.',name)-1), @extention = substring(name,charindex('.',name),len(name))
   from (
    select reverse(substring(reverse(@filename), 1, charindex('\',reverse(@filename))-1))name)a 

  begin try
   begin transaction
    INSERT INTO sound_details (id, name, file_extention, sound) values (@id , @name, @extention, @bytes)
    SET @P_status = 1
   commit transaction
  end try
  begin catch
   SET @P_status = 0
  end catch

END
