CREATE FUNCTION [dbo].[FN_MineSweeper]
(@Number int, @Width int, @Height int)
returns @table table (InNumber int)
as
Begin
declare @loop int, @IsRightBorder int, @IsLiftBorder int
declare @RBorder table (Border_number int)
declare @LBorder table (Border_number int)
set @loop = 0

while @loop < (@width*@height)/@width
begin
set @loop = @loop + 1
insert into @RBorder
select @width*@loop
end

insert into @LBorder
select Border_number - (@width-1)
from @Rborder

select @IsRightBorder = count(*) 
from @RBorder
where Border_number = @number

select @IsLiftBorder = count(*) 
from @LBorder
where Border_number = @number

IF @IsRightBorder > 0 
begin
insert into @table
select @Number - (@width+1)
insert into @table
select @Number - (@width)
insert into @table
select @Number - 1
insert into @table
select @Number + (@width - 1)
insert into @table
select @Number + (@width)
End
IF @IsLiftBorder > 0 
begin
insert into @table
select @Number - (@width)
insert into @table
select @Number - (@width - 1)
insert into @table
select @Number + 1
insert into @table
select @Number + (@width)
insert into @table
select @Number + (@width+1)
End
IF @IsLiftBorder = 0 and @IsRightBorder = 0 
begin
declare @IN varchar(50)
insert into @table
select @Number - (@width+1)
insert into @table
select @Number - (@width)
insert into @table
select @Number - (@width - 1)
insert into @table
select @Number - 1
insert into @table
select @Number + 1
insert into @table
select @Number + (@width - 1)
insert into @table
select @Number + (@width)
insert into @table
select @Number + (@width+1)
End

return
end

