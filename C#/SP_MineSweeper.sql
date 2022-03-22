CREATE Procedure [dbo].[SP_MineSweeper]
(@Mine int, @Width int , @Height int)
as
begin
declare @table table (number int, Random_number int, Mine bit default 1)
declare @table_All table (number int, mine bit default 0)
declare @mines table (number int, mine int)
declare @mine_Sweeper      table (number int, mine int, Mine_Count int)
declare @mine_sweeper_fine table (number varchar(5), mine varchar(5), Mine_Count varchar(5))
declare @random_number int,@Loop int, @count int, @sum int,@number int, @inStatement varchar(100),@mine_ int
set nocount on
set @loop   = 0
while @loop < (@Width*@Height)
begin
set @loop = @loop + 1
insert into @table_all (number) values (@loop)
end

set @loop   = 0
while @loop < @Mine
begin
select @random_number = isnull(number ,0)
from (
select 
cast(ltrim(rtrim(substring(replace(replace(replace(replace(replace(replace(
replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
newid(),'A',''),'B',''),'C',''),'D',''),'E',''),'F',''),'G',''),'H',''),'I',''),'G',''),
'K',''),'L',''),'M',''),'N',''),'O',''),'P',''),'Q',''),'R',''),'S',''),'T',''),'U',''),
'V',''),'W',''),'X',''),'Y',''),'Z',''),'-',''),1,3))) as int) Number)a
where number between 1 and (@Width*@Height)
and number is not null

select @count = count(*) 
from @table 
where random_number = @random_number
and random_number is not null

IF @count = 0 and @random_number between 1 and (@Width*@Height)
begin
set @loop = @loop + 1
insert into @table (number, random_number) values (@loop,@random_number)
end
end

insert into @mines
select Number , Mine
from (
select a.number , isnull(nullif(t.mine, null),a.mine) Mine 
from @table t right outer join @table_all a
on t.random_number = a.number)Mine
order by number

declare i cursor fast_forward
for
select Number, mine
from (
select a.number , isnull(nullif(t.mine, null),a.mine) Mine 
from @table t right outer join @table_all a
on t.random_number = a.number)Mine
where mine = 0
order by number

open i
fetch next from i into @Number,@mine_
while @@fetch_status = 0
begin

select @sum = sum(mine)
from @mines
where number in (select InNumber from dbo.FN_MineSweeper(@number,@width,@height) where InNumber > 0)
insert into @Mine_Sweeper
select Number, Mine , @sum
from @mines
where number = @number

fetch next from i into @Number,@mine_
end
close i
deallocate i

insert into @mine_sweeper
select * , 0 from @mines
where mine = 1

insert into @mine_sweeper_fine
select Number, Mine ,Mine_Count 
from @mine_sweeper
order by number

select Number, case _mine when '.' then _mine else _count end Mine
from (
select Number, case mine when '1' then '.' else '' end _mine , case mine_count when '0' then ' ' else mine_count end _Count
from @mine_sweeper_fine)a

end


