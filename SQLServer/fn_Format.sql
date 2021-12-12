USE [master]
GO
/****** Object:  UserDefinedFunction [dbo].[Format]    Script Date: 6/30/2019 9:59:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [dbo].[Format]
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
where number like '%.%'

if @round_exist > 0
begin
if @round >= 0 
begin
select @result = 
case len(substring(number,1,charindex('.',number)-1)) 
when 1  then substring(number,1,charindex('.',number)-1)+ case @round when 0 then '.0' else '.'+substring(number,charindex('.',number)+1,@round) end 
when 2  then substring(number,1,charindex('.',number)-1)+ case @round when 0 then '.0' else '.'+substring(number,charindex('.',number)+1,@round) end 
when 3  then substring(number,1,charindex('.',number)-1)+ case @round when 0 then '.0' else '.'+substring(number,charindex('.',number)+1,@round) end 
when 4  then substring(number,1,1)+','+substring(number,2,3) +'.'+substring(number,charindex('.',number)+1,case @round when 0 then len(number) else @round end) 
when 5  then substring(number,1,2)+','+substring(number,3,3) +'.'+substring(number,charindex('.',number)+1,case @round when 0 then len(number) else @round end) 
when 6  then substring(number,1,3)+','+substring(number,4,3) +'.'+substring(number,charindex('.',number)+1,case @round when 0 then len(number) else @round end)
when 7  then substring(number,1,1)+','+substring(number,2,3) +','+substring(number,5,3)+'.'+substring(number,charindex('.',number)+1,case @round when 0 then len(number) else @round end) 
when 8  then substring(number,1,2)+','+substring(number,3,3) +','+substring(number,6,3)+'.'+substring(number,charindex('.',number)+1,case @round when 0 then len(number) else @round end) 
when 9  then substring(number,1,3)+','+substring(number,4,3) +','+substring(number,7,3)+'.'+substring(number,charindex('.',number)+1,case @round when 0 then len(number) else @round end) 
when 10 then substring(number,1,1)+','+substring(number,2,3) +','+substring(number,5,3)+','+substring(number,8,3)+'.'+substring(number,charindex('.',number)+1,case @round when 0 then len(number) else @round end) 
when 11 then substring(number,1,2)+','+substring(number,3,3) +','+substring(number,6,3)+','+substring(number,9,3)+'.'+substring(number,charindex('.',number)+1,case @round when 0 then len(number) else @round end) 
when 12 then substring(number,1,3)+','+substring(number,4,3) +','+substring(number,7,3)+','+substring(number,10,3)+'.'+substring(number,charindex('.',number)+1,case @round when 0 then len(number) else @round end)
when 13 then substring(number,1,1)+','+substring(number,2,3) +','+substring(number,5,3)+','+substring(number,8,3)+','+substring(number,11,3)+'.'+substring(number,charindex('.',number)+1,case @round when 0 then len(number) else @round end) end
from (
select @number number)a
end
else
begin
select @result = 
case len(substring(number,1,charindex('.',number)-1)) 
when 1 then substring(number,1,charindex('.',number)-1)
when 2 then substring(number,1,charindex('.',number)-1)
when 3 then substring(number,1,charindex('.',number)-1)
when 4 then substring(number,1,1)+','+substring(number,2,3) 
when 5 then substring(number,1,2)+','+substring(number,3,3)
when 6 then substring(number,1,3)+','+substring(number,4,3)
when 7 then substring(number,1,1)+','+substring(number,2,3)+','+substring(number,5,3) 
when 8  then substring(number,1,2)+','+substring(number,3,3)+','+substring(number,6,3)
when 9  then substring(number,1,3)+','+substring(number,4,3)+','+substring(number,7,3)
when 10 then substring(number,1,1)+','+substring(number,2,3)+','+substring(number,5,3)+','+substring(number,8,3)
when 11 then substring(number,1,2)+','+substring(number,3,3)+','+substring(number,6,3)+','+substring(number,9,3)
when 12 then substring(number,1,3)+','+substring(number,4,3)+','+substring(number,7,3)+','+substring(number,10,3)
when 13 then substring(number,1,1)+','+substring(number,2,3)+','+substring(number,5,3)+','+substring(number,8,3)+','+substring(number,11,3) end
from (
select @number number)a
end
end
else
begin
select @result = 
case len(substring(number,1,charindex('.',number)-1)) 
when 1 then substring(number,1,charindex('.',number)-1)
when 2 then substring(number,1,charindex('.',number)-1)
when 3 then substring(number,1,charindex('.',number)-1)
when 4 then substring(number,1,1)+','+substring(number,2,3) 
when 5 then substring(number,1,2)+','+substring(number,3,3)
when 6 then substring(number,1,3)+','+substring(number,4,3)
when 7 then substring(number,1,1)+','+substring(number,2,3)+','+substring(number,5,3) 
when 8  then substring(number,1,2)+','+substring(number,3,3)+','+substring(number,6,3)
when 9  then substring(number,1,3)+','+substring(number,4,3)+','+substring(number,7,3)
when 10 then substring(number,1,1)+','+substring(number,2,3)+','+substring(number,5,3)+','+substring(number,8,3)
when 11 then substring(number,1,2)+','+substring(number,3,3)+','+substring(number,6,3)+','+substring(number,9,3)
when 12 then substring(number,1,3)+','+substring(number,4,3)+','+substring(number,7,3)+','+substring(number,10,3)
when 13 then substring(number,1,1)+','+substring(number,2,3)+','+substring(number,5,3)+','+substring(number,8,3)+','+substring(number,11,3) end
from (
select @number number)a
end

return @result 
end
