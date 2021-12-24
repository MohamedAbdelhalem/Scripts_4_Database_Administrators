-- i am using a data from Microsoft SQL Server 2017 schema AdventureWorks2017, that i convert the table of Sales.SalesOrderHeader 
-- into 4 table (2011, 2012, 2013, and 2014)
-- first you need to use this procedure in SQL Server to convert the table to PostgreSQL compatibility 

-- create Sales schema and username in postgres

Create User mssql encrypted password 'password';
Create Database AdventureWorks2017 owner mssql;
Create Schema Sales authorization mssql;

-- https://github.com/MohamedAbdelhalem/Scripts_4_Database_Administrators/blob/master/Migration/SQLServer__to/sp_Export_Table_Data.sql

use [AdventureWorks2017]
go
exec [dbo].[sp_dump_table] 
@table='Sales.SalesOrderHeader',
@migrated_to='postgresql',
@header=1,
@with_computed=0,
@bulk=10,
@patch=0

-- copy the table script into postgresql and 

Create Table Sales.SalesOrderHeader_2011 ( 
check(orderdate between '2011-01-01' and '2011-12-31 23:59:59')) inherits (Sales.SalesOrderHeader);
Create Table Sales.SalesOrderHeader_2012 ( 
check(orderdate between '2012-01-01' and '2012-12-31 23:59:59')) inherits (Sales.SalesOrderHeader);
Create Table Sales.SalesOrderHeader_2013 ( 
check(orderdate between '2013-01-01' and '2013-12-31 23:59:59')) inherits (Sales.SalesOrderHeader);
Create Table Sales.SalesOrderHeader_2014 ( 
check(orderdate between '2014-01-01' and '2014-12-31 23:59:59')) inherits (Sales.SalesOrderHeader);

create index idx_salesorderheader_date_2011 on sales.salesorderheader_2011 (orderdate);
create index idx_salesorderheader_date_2012 on sales.salesorderheader_2012 (orderdate);
create index idx_salesorderheader_date_2013 on sales.salesorderheader_2013 (orderdate);
create index idx_salesorderheader_date_2014 on sales.salesorderheader_2014 (orderdate);

create function fn_insert_into_salesorderheader_master()
returns trigger as $$
begin
	if (new.orderdate between '2011-01-01' and '2011-12-31 23:59:59') then
			insert into Sales.SalesOrderHeader_2011 values (new.*);
	elsif (new.orderdate between '2012-01-01' and '2012-12-31 23:59:59') then
			insert into Sales.SalesOrderHeader_2012 values (new.*);
	elsif (new.orderdate between '2013-01-01' and '2013-12-31 23:59:59') then
			insert into Sales.SalesOrderHeader_2013 values (new.*);
	elsif (new.orderdate between '2014-01-01' and '2014-12-31 23:59:59') then
			insert into Sales.SalesOrderHeader_2014 values (new.*);
	elsif (new.orderdate between '2015-01-01' and '2015-12-31 23:59:59') then
			insert into Sales.SalesOrderHeader_2015 values (new.*);
	elsif (new.orderdate between '2016-01-01' and '2016-12-31 23:59:59') then
			insert into Sales.SalesOrderHeader_2016 values (new.*);
	elsif (new.orderdate between '2017-01-01' and '2017-12-31 23:59:59') then
			insert into Sales.SalesOrderHeader_2017 values (new.*);
	elsif (new.orderdate between '2018-01-01' and '2018-12-31 23:59:59') then
			insert into Sales.SalesOrderHeader_2018 values (new.*);
	elsif (new.orderdate between '2019-01-01' and '2019-12-31 23:59:59') then
			insert into Sales.SalesOrderHeader_2019 values (new.*);
	elsif (new.orderdate between '2020-01-01' and '2020-12-31 23:59:59') then
			insert into Sales.SalesOrderHeader_2020 values (new.*);
	elsif (new.orderdate between '2021-01-01' and '2021-12-31 23:59:59') then
			insert into Sales.SalesOrderHeader_2021 values (new.*);
	elsif (new.orderdate between '2022-01-01' and '2022-12-31 23:59:59') then
			insert into Sales.SalesOrderHeader_2022 values (new.*);
	elsif (new.orderdate between '2023-01-01' and '2023-12-31 23:59:59') then
			insert into Sales.SalesOrderHeader_2023 values (new.*);
	else
			raise exception 'the inserted data are not valid date time';
	end if;
	
	return null;
end;
$$ LANGUAGE plpgsql;

create trigger trg_insert_into_salesorderheader_master
before insert on sales.salesorderheader 
for each row execute procedure fn_insert_into_salesorderheader_master();

-- export the data from SQL Server using the below procedure to export and convert into postgresql 
use [AdventureWorks2017]
go
exec [dbo].[sp_dump_table] 
@table='Sales.SalesOrderHeader',
@migrated_to='postgresql',
@header=0,
@with_computed=0,
@bulk=10000,
@patch=0 -- 0,1,2,3 table has 39,898 rows = 10,000 x 4 times

-- copy the insert statements into postgresql
-- then voila!

select * from only sales.salesorderheader;
select * from sales.salesorderheader_2011;
select * from sales.salesorderheader_2012;
select * from sales.salesorderheader_2013;
select * from sales.salesorderheader_2014;
select * from sales.salesorderheader;
