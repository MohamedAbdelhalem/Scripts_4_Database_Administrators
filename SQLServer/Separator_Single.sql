CREATE Function [dbo].[Separator_Single]
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
end
