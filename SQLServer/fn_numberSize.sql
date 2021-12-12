Create function [dbo].[numberSize]
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

if @type = 'B'
select @return = 
case 
when @number between    0 and @B then cast(round(cast(@number as float)/1,2) as varchar)+' Bytes'
when @number between @b+0 and @K then cast(round(cast(@number as float)/1024,2) as varchar)+' KB'
when @number between @k+0 and @M then cast(round(cast(@number as float)/1024/1024,2) as varchar)+' MB'
when @number between @m+0 and @G then cast(round(cast(@number as float)/1024/1024/1024,2) as varchar)+' GB'
when @number between @g+0 and @T then cast(round(cast(@number as float)/1024/1024/1024/1024,2) as varchar)+' TB'
end

else if @type = 'K'
begin
select @return = 
case 
when @number between    0 and @B then cast(round(cast(@number as float)/1,2) as varchar)+' KB'
when @number between @b+0 and @K then cast(round(cast(@number as float)/1024,2) as varchar)+' MB'
when @number between @k+0 and @M then cast(round(cast(@number as float)/1024/1024,2) as varchar)+' GB'
when @number between @m+0 and @G then cast(round(cast(@number as float)/1024/1024/1024,2) as varchar)+' TB'
end
end

else if @type = 'M'
select @return = 
case 
when @number between    0 and @B then cast(round(cast(@number as float)/1,2) as varchar)+' MB'
when @number between @b+0 and @K then cast(round(cast(@number as float)/1024,2) as varchar)+' GB'
when @number between @k+0 and @M then cast(round(cast(@number as float)/1024/1024,2) as varchar)+' TB'
end

else if @type = 'G'
select @return = 
case 
when @number between    0 and @B then cast(round(cast(@number as float)/1,2) as varchar)+' GB'
when @number between @b+0 and @K then cast(round(cast(@number as float)/1024,2) as varchar)+' TB'
end

else if @type = 'T'
select @return = 
case 
when @number between    0 and @B then cast(round(cast(@number as float)/1,2) as varchar)+' TB'
end

return @return
end
