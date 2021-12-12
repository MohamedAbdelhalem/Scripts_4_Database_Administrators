CREATE procedure [dbo].[Find] 
(@like nvarchar(100), @objname varchar(100) = '%')
as
begin
declare @count int, @pro nvarchar(100), @type varchar(5), @Type_Desc varchar(30), @Is_Enable  bit
declare @tab   table (text_output varchar(500))
declare @tab2  table (row_num int , text_output varchar(500))
declare @table table (Line_No int , Procedure_Name varchar(100) , [Type] varchar(5), Type_Desc varchar(30), Is_Enable bit, [Text] nvarchar(500))
declare pro cursor fast_forward 
for
select name, type , replace(replace(type_desc , 'SQL_',' '),'_',' ') , case type 
when 'TR' then dbo.[is_trigger_enabled](name) 
else 1 end
from sys.all_objects
where type in('P','V','TR','TF','FN')
and object_id not like '-%'
and name like ''+@objname+''
order by name

set nocount on

open pro
fetch next from pro into @pro , @type , @Type_Desc , @Is_Enable  
while @@fetch_status = 0
begin

delete @tab
delete @tab2

insert into @tab
exec sp_helptext @objname = @pro

INSERT INTO @TAB2
SELECT row_number() over(order by orderby) , text_output 
from (
select '1' orderby , text_output from @tab
)a

select @count = count(*)
from @tab2
where text_output like '%'+@like+'%'

IF @count > 0
begin
insert into @table
(line_no , procedure_name , [Type] , Type_Desc , Is_Enable , [Text] )
select row_num , @pro , @type , @Type_Desc , @Is_Enable  , text_output 
from @tab2
where text_output like '%'+@like+'%'
end

fetch next from pro into @pro , @type , @Type_Desc , @Is_Enable  
end
close pro
deallocate pro

select @count = count(*) from @table 

IF @count > 0
begin
   select @count = count(distinct procedure_name)
   from @table 
   IF @count = 1
   begin
     select * from @table 
     exec sp_helptext @objname = @pro
   end
   IF @count > 1
   begin
     select * from @table 
   end
end

IF @count = 0
begin
print('The object or the word that you are searching about doesn''t exist in any procedure') 
end
set nocount off 
end

