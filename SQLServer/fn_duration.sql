create function dbo.duration
(@seconds bigint)
returns varchar(50)
as
begin
declare @duration varchar(50)
select @duration = 
cast(day(convert(varchar(30), dateadd(s, @seconds, '2000-01-01'), 121)) - 1 as varchar)+'d '+
[dbo].[Separator_Single](convert(varchar(10), dateadd(s, @seconds, '2000-01-01'), 108),':',1)+'h:'+
[dbo].[Separator_Single](convert(varchar(10), dateadd(s, @seconds, '2000-01-01'), 108),':',2)+'m:'+
[dbo].[Separator_Single](convert(varchar(10), dateadd(s, @seconds, '2000-01-01'), 108),':',3)+'s' 

return @duration
end
