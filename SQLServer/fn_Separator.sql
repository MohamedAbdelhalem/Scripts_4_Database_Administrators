USE [master]
GO

CREATE Function [dbo].[Separator]
(@str nvarchar(max), @sepr nvarchar(5))
returns @table table (id int identity(1,1), [value] nvarchar(550))
as
begin
declare 
@word   nvarchar(550), 
@len    int, 
@s_ind  int, 
@f_ind  int

set @len  = LEN(@str)
set @f_ind = 1

while @f_ind > 0
begin
set @f_ind = case when charindex(@sepr,@str)-1 < 0 then 0 else charindex(@sepr,@str) end
set @s_ind = charindex(@sepr,@str) + len(@sepr)
set @len   = len(@str)
set @word  = case when substring(@str , 1, @f_ind) = '' then @str else substring(@str , 1, @f_ind) end
set @str   = substring(@str , @s_ind,@len )

insert into @table 
select @word
end

return
end
