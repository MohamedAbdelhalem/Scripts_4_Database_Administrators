USE [master]
GO
declare @sql varchar(max), @drop varchar(500), @replace bit = 0

-----------------------------------------------------------------------------------------------------------

set @sql = 'CREATE Function [dbo].[numberSize]
(@number numeric(20,2), @type varchar(1))
returns varchar(100)
as
begin
declare @return varchar(100), @B numeric, @K numeric, @M numeric, @G numeric, @T numeric
set @b = 1024
set @k = 1048576
set @m = 1073741824
set @g = 1099511627776
set @t = 1125899906842624

if @type = ''B''
select @return = 
case 
when @number between    0 and @B then cast(round(cast(@number as float)/1,2) as varchar)+'' Bytes''
when @number between @b+0 and @K then cast(round(cast(@number as float)/1024,2) as varchar)+'' KB''
when @number between @k+0 and @M then cast(round(cast(@number as float)/1024/1024,2) as varchar)+'' MB''
when @number between @m+0 and @G then cast(round(cast(@number as float)/1024/1024/1024,2) as varchar)+'' GB''
when @number between @g+0 and @T then cast(round(cast(@number as float)/1024/1024/1024/1024,2) as varchar)+'' TB''
end

else if @type = ''K''
begin
select @return = 
case 
when @number between    0 and @B then cast(round(cast(@number as float)/1,2) as varchar)+'' KB''
when @number between @b+0 and @K then cast(round(cast(@number as float)/1024,2) as varchar)+'' MB''
when @number between @k+0 and @M then cast(round(cast(@number as float)/1024/1024,2) as varchar)+'' GB''
when @number between @m+0 and @G then cast(round(cast(@number as float)/1024/1024/1024,2) as varchar)+'' TB''
end
end

else if @type = ''M''
select @return = 
case 
when @number between    0 and @B then cast(round(cast(@number as float)/1,2) as varchar)+'' MB''
when @number between @b+0 and @K then cast(round(cast(@number as float)/1024,2) as varchar)+'' GB''
when @number between @k+0 and @M then cast(round(cast(@number as float)/1024/1024,2) as varchar)+'' TB''
end

else if @type = ''G''
select @return = 
case 
when @number between    0 and @B then cast(round(cast(@number as float)/1,2) as varchar)+'' GB''
when @number between @b+0 and @K then cast(round(cast(@number as float)/1024,2) as varchar)+'' TB''
end

else if @type = ''T''
select @return = 
case 
when @number between    0 and @B then cast(round(cast(@number as float)/1,2) as varchar)+'' TB''
end

return @return
end'
if (select count(*) from sys.objects where object_id = object_id('numberSize') and schema_id = 1) > 0 and @replace = 0
begin
	print('Scalar-valued Function [dbo].[numberSize] already exists')
end
else 
if (select count(*) from sys.objects where object_id = object_id('numberSize') and schema_id = 1) > 0 and @replace = 1
begin
	set @drop = 'DROP Function [dbo].[numberSize]'
	exec(@drop)
	exec(@sql)
	print('Scalar-valued Function [dbo].[numberSize] has created successfully')
end
else
if (select count(*) from sys.objects where object_id = object_id('numberSize') and schema_id = 1) = 0 and @replace = 0
begin
	exec(@sql)
	print('Scalar-valued Function [dbo].[numberSize] has created successfully')
end

-----------------------------------------------------------------------------------------------------------

set @sql = 'CREATE Function [dbo].[Format]
(@P_Number decimal(35,6), @P_Round int)
returns varchar(50)
as
begin
declare 
@round int, 
@number varchar(50),
@result varchar(50),
@round_exist int

set @number = @P_Number
set @round = @P_Round

select @round_exist = count(*)
from (
select @number number)a
where number like ''%.%''

if @round_exist > 0
begin
if @round >= 0 
begin
select @result = 
case len(substring(number,1,charindex(''.'',number)-1)) 
when 1  then substring(number,1,charindex(''.'',number)-1)+ case @round when 0 then ''.0'' else ''.''+substring(number,charindex(''.'',number)+1,@round) end 
when 2  then substring(number,1,charindex(''.'',number)-1)+ case @round when 0 then ''.0'' else ''.''+substring(number,charindex(''.'',number)+1,@round) end 
when 3  then substring(number,1,charindex(''.'',number)-1)+ case @round when 0 then ''.0'' else ''.''+substring(number,charindex(''.'',number)+1,@round) end 
when 4  then substring(number,1,1)+'',''+substring(number,2,3) +''.''+substring(number,charindex(''.'',number)+1,case @round when 0 then len(number) else @round end) 
when 5  then substring(number,1,2)+'',''+substring(number,3,3) +''.''+substring(number,charindex(''.'',number)+1,case @round when 0 then len(number) else @round end) 
when 6  then substring(number,1,3)+'',''+substring(number,4,3) +''.''+substring(number,charindex(''.'',number)+1,case @round when 0 then len(number) else @round end)
when 7  then substring(number,1,1)+'',''+substring(number,2,3) +'',''+substring(number,5,3)+''.''+substring(number,charindex(''.'',number)+1,case @round when 0 then len(number) else @round end) 
when 8  then substring(number,1,2)+'',''+substring(number,3,3) +'',''+substring(number,6,3)+''.''+substring(number,charindex(''.'',number)+1,case @round when 0 then len(number) else @round end) 
when 9  then substring(number,1,3)+'',''+substring(number,4,3) +'',''+substring(number,7,3)+''.''+substring(number,charindex(''.'',number)+1,case @round when 0 then len(number) else @round end) 
when 10 then substring(number,1,1)+'',''+substring(number,2,3) +'',''+substring(number,5,3)+'',''+substring(number,8,3)+''.''+substring(number,charindex(''.'',number)+1,case @round when 0 then len(number) else @round end) 
when 11 then substring(number,1,2)+'',''+substring(number,3,3) +'',''+substring(number,6,3)+'',''+substring(number,9,3)+''.''+substring(number,charindex(''.'',number)+1,case @round when 0 then len(number) else @round end) 
when 12 then substring(number,1,3)+'',''+substring(number,4,3) +'',''+substring(number,7,3)+'',''+substring(number,10,3)+''.''+substring(number,charindex(''.'',number)+1,case @round when 0 then len(number) else @round end)
when 13 then substring(number,1,1)+'',''+substring(number,2,3) +'',''+substring(number,5,3)+'',''+substring(number,8,3)+'',''+substring(number,11,3)+''.''+substring(number,charindex(''.'',number)+1,case @round when 0 then len(number) else @round end) end
from (
select @number number)a
end
else
begin
select @result = 
case len(substring(number,1,charindex(''.'',number)-1)) 
when 1 then substring(number,1,charindex(''.'',number)-1)
when 2 then substring(number,1,charindex(''.'',number)-1)
when 3 then substring(number,1,charindex(''.'',number)-1)
when 4 then substring(number,1,1)+'',''+substring(number,2,3) 
when 5 then substring(number,1,2)+'',''+substring(number,3,3)
when 6 then substring(number,1,3)+'',''+substring(number,4,3)
when 7 then substring(number,1,1)+'',''+substring(number,2,3)+'',''+substring(number,5,3) 
when 8  then substring(number,1,2)+'',''+substring(number,3,3)+'',''+substring(number,6,3)
when 9  then substring(number,1,3)+'',''+substring(number,4,3)+'',''+substring(number,7,3)
when 10 then substring(number,1,1)+'',''+substring(number,2,3)+'',''+substring(number,5,3)+'',''+substring(number,8,3)
when 11 then substring(number,1,2)+'',''+substring(number,3,3)+'',''+substring(number,6,3)+'',''+substring(number,9,3)
when 12 then substring(number,1,3)+'',''+substring(number,4,3)+'',''+substring(number,7,3)+'',''+substring(number,10,3)
when 13 then substring(number,1,1)+'',''+substring(number,2,3)+'',''+substring(number,5,3)+'',''+substring(number,8,3)+'',''+substring(number,11,3) end
from (
select @number number)a
end
end
else
begin
select @result = 
case len(substring(number,1,charindex(''.'',number)-1)) 
when 1 then substring(number,1,charindex(''.'',number)-1)
when 2 then substring(number,1,charindex(''.'',number)-1)
when 3 then substring(number,1,charindex(''.'',number)-1)
when 4 then substring(number,1,1)+'',''+substring(number,2,3) 
when 5 then substring(number,1,2)+'',''+substring(number,3,3)
when 6 then substring(number,1,3)+'',''+substring(number,4,3)
when 7 then substring(number,1,1)+'',''+substring(number,2,3)+'',''+substring(number,5,3) 
when 8  then substring(number,1,2)+'',''+substring(number,3,3)+'',''+substring(number,6,3)
when 9  then substring(number,1,3)+'',''+substring(number,4,3)+'',''+substring(number,7,3)
when 10 then substring(number,1,1)+'',''+substring(number,2,3)+'',''+substring(number,5,3)+'',''+substring(number,8,3)
when 11 then substring(number,1,2)+'',''+substring(number,3,3)+'',''+substring(number,6,3)+'',''+substring(number,9,3)
when 12 then substring(number,1,3)+'',''+substring(number,4,3)+'',''+substring(number,7,3)+'',''+substring(number,10,3)
when 13 then substring(number,1,1)+'',''+substring(number,2,3)+'',''+substring(number,5,3)+'',''+substring(number,8,3)+'',''+substring(number,11,3) end
from (
select @number number)a
end

return @result 
end'
if (select count(*) from sys.objects where object_id = object_id('Format') and schema_id = 1) > 0 and @replace = 0
begin
	print('Scalar-valued Function [dbo].[Format] already exists')
end
else 
if (select count(*) from sys.objects where object_id = object_id('Format') and schema_id = 1) > 0 and @replace = 1
begin
	set @drop = 'DROP Function [dbo].[Format]'
	exec(@drop)
	exec(@sql)
	print('Scalar-valued Function [dbo].[Format] has created successfully')
end
else
if (select count(*) from sys.objects where object_id = object_id('Format') and schema_id = 1) = 0 and @replace = 0
begin
	exec(@sql)
	print('Scalar-valued Function [dbo].[Format] has created successfully')
end

-----------------------------------------------------------------------------------------------------------

set	@sql = 'CREATE Function [dbo].[Separator]
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
SET @s_ind = CHARINDEX(@sepr,@str)+ 1 + len(@sepr)
SET @len   = LEN(@str)
SET @word  = CASE WHEN SUBSTRING(@str , 1, @f_ind) = '''' THEN @str ELSE SUBSTRING(@str , 1, @f_ind) END
SET @str   = SUBSTRING(@str , @s_ind,@len )

INSERT INTO @table 
SELECT @word
END

RETURN
END'

if (select count(*) from sys.objects where object_id = object_id('Separator') and schema_id = 1) > 0 and @replace = 0
begin
	print('Table-valued Function [dbo].[Separator] already exists')
end
else 
if (select count(*) from sys.objects where object_id = object_id('Separator') and schema_id = 1) > 0 and @replace = 1
begin
	set @drop = 'DROP Function [dbo].[Separator]'
	exec(@drop)
	exec(@sql)
	print('Table-valued Function [dbo].[Separator] has created successfully')
end
else
if (select count(*) from sys.objects where object_id = object_id('Separator') and schema_id = 1) = 0 and @replace = 0
begin
	exec(@sql)
	print('Table-valued Function [dbo].[Separator] has created successfully')
end

-----------------------------------------------------------------------------------------------------------

set @sql = 'CREATE Function [dbo].[virtical_array]
(@string varchar(max), @sep varchar(5), @position int)
returns varchar(max)
as
begin

declare @result varchar(max), @loop int = 0, @len int = 1, @inserted int = 0
while @inserted < @position
begin
select @len = charindex(@sep,substring(@string,case when @loop = 0 then 1 else @loop + 1 end,len(@string)))
select @result = substring(@string, @loop + 1, case @len when 0 then len(@string) else @len - 1 end)
set @loop = @loop + @len
set @inserted = @inserted + 1
end

return @result
end'
if (select count(*) from sys.objects where object_id = object_id('virtical_array') and schema_id = 1) > 0 and @replace = 0
begin
	print('Scalar-valued Function [dbo].[virtical_array] already exists')
end
else 
if (select count(*) from sys.objects where object_id = object_id('virtical_array') and schema_id = 1) > 0 and @replace = 1
begin
	set @drop = 'DROP Function [dbo].[virtical_array]'
	exec(@drop)
	exec(@sql)
	print('Scalar-valued Function [dbo].[virtical_array] has created successfully')
end
else
if (select count(*) from sys.objects where object_id = object_id('virtical_array') and schema_id = 1) = 0 and @replace = 0
begin
	exec(@sql)
	print('Scalar-valued Function [dbo].[virtical_array] has created successfully')
end

-----------------------------------------------------------------------------------------------------------

set @sql = 'CREATE Function [dbo].[duration]
(@type varchar(5) = ''s'', @number bigint)
returns varchar(50)
as
begin
declare @duration varchar(50)
if @type = ''ms''
begin
select @duration = 
cast(day(convert(varchar(30), dateadd(ms, @number, ''2000-01-01''), 121)) - 1 as varchar)+''d ''+
[dbo].virtical_array(convert(varchar(10), dateadd(ms, @number, ''2000-01-01''), 108),'':'',1)+''h:''+
[dbo].virtical_array(convert(varchar(10), dateadd(ms, @number, ''2000-01-01''), 108),'':'',2)+''m:''+
[dbo].virtical_array(convert(varchar(10), dateadd(ms, @number, ''2000-01-01''), 108),'':'',3)+''s.''+ 
[dbo].virtical_array(convert(varchar(50), dateadd(ms, @number, ''2000-01-01''), 121),''.'',5)+''ms''
end
else if @type = ''s''
begin
select @duration = 
cast(day(convert(varchar(30), dateadd(s, @number, ''2000-01-01''), 121)) - 1 as varchar)+''d ''+
[dbo].virtical_array(convert(varchar(10), dateadd(s, @number, ''2000-01-01''), 108),'':'',1)+''h:''+
[dbo].virtical_array(convert(varchar(10), dateadd(s, @number, ''2000-01-01''), 108),'':'',2)+''m:''+
[dbo].virtical_array(convert(varchar(10), dateadd(s, @number, ''2000-01-01''), 108),'':'',3)+''s''
end

return @duration
end'
if (select count(*) from sys.objects where object_id = object_id('duration') and schema_id = 1) > 0 and @replace = 0
begin
	print('Scalar-valued Function [dbo].[duration] already exists')
end
else 
if (select count(*) from sys.objects where object_id = object_id('duration') and schema_id = 1) > 0 and @replace = 1
begin
	set @drop = 'DROP Function [dbo].[duration]'
	exec(@drop)
	exec(@sql)
	print('Scalar-valued Function [dbo].[duration] has created successfully')
end
else
if (select count(*) from sys.objects where object_id = object_id('duration') and schema_id = 1) = 0 and @replace = 0
begin
	exec(@sql)
	print('Scalar-valued Function [dbo].[duration] has created successfully')
end

-----------------------------------------------------------------------------------------------------------

set @sql = 'CREATE Function [dbo].[fn_oneline]
(
@text				varchar(max), 
@separator			varchar(10), 
@one_line			bit,
@with_square		int,
@with_brackets		int,
@with_text_before	int,
@text_before		varchar(max)
)
returns @table table ([value] varchar(max))
as
begin

declare @result varchar(max)
select @result = isnull(@result+@separator,'''') + case 
when @with_square + @with_brackets + @with_text_before = 1 then ''['' + value + '']'' 
when @with_square + @with_brackets + @with_text_before = 2 then ''('' + value + '')'' 
when @with_square + @with_brackets + @with_text_before = 4 then @text_before + value  
when @with_square + @with_brackets + @with_text_before = 5 then @text_before + ''['' + value + '']''
when @with_square + @with_brackets + @with_text_before = 6 then @text_before + ''('' + value + '')''
else value end
from master.dbo.Separator(@text,(select CHAR(10)))
order by id

set @result = replace(replace(replace(convert(varbinary(max), @result),0x0D,0x20),'' ]'','']''),'' )'','')'')

if @one_line = 1
begin
insert into @table select @result
end
else
begin
insert into @table
select ltrim(rtrim(value))
from master.dbo.Separator(@result,@separator)
order by id
end

return

end'
if (select count(*) from sys.objects where object_id = object_id('fn_oneline') and schema_id = 1) > 0 and @replace = 0
begin
	print('Table-valued Function [dbo].[fn_oneline] already exists')
end
else 
if (select count(*) from sys.objects where object_id = object_id('fn_oneline') and schema_id = 1) > 0 and @replace = 1
begin
	set @drop = 'DROP Function [dbo].[fn_oneline]'
	exec(@drop)
	exec(@sql)
	print('Table-valued Function [dbo].[fn_oneline] has created successfully')
end
else
if (select count(*) from sys.objects where object_id = object_id('fn_oneline') and schema_id = 1) = 0 and @replace = 0
begin
	exec(@sql)
	print('Table-valued Function [dbo].[fn_oneline] has created successfully')
end

