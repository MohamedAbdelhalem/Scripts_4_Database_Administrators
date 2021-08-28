CREATE Function [dbo].[Percent_Complete]
(@id float, @total float)
Returns varchar(10)
as
begin
declare @table table ([loop] float, [prog] float)
declare 
@loop float = 1, 
@pct float, 
@prog float, 
@prev float,
@percent varchar(20)

set @pct = 100/@total
while @loop < @total + 1
begin 
	set @prog = Ceiling(@pct * @loop)
	if (isnull(@prev,0) != isnull(@prog,0))
	begin
		insert into @table values (@loop, @prog)
	end
	set @loop = @loop + 1
	set @prev = @prog
end

select @percent = cast(prog as varchar)+' %'
  from (
		select t1.loop range_from, t2.loop - 1 range_to, t1.prog 
		  from @table t1 left outer join @table t2
			on t1.prog = t2.prog -1) [range]
 where @id between range_from and isnull(range_to, @total)

return @percent
end
