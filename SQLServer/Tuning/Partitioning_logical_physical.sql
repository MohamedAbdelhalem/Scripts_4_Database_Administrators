USE [dwh]
GO
drop TABLE [dbo].[FactSales_PT]
drop partition scheme ps_FactSalesBranches
drop partition function pf_FactSalesBranches

GO
alter database dwh add filegroup fg_FactSalesAllBranches
go
alter database dwh add filegroup fg_FactSalesBranch01
alter database dwh add filegroup fg_FactSalesBranch02
alter database dwh add filegroup fg_FactSalesBranch03
alter database dwh add filegroup fg_FactSalesBranch04
alter database dwh add filegroup fg_FactSalesBranch05
alter database dwh add filegroup fg_FactSalesBranch06
alter database dwh add filegroup fg_FactSalesBranch07
alter database dwh add filegroup fg_FactSalesBranch08
alter database dwh add filegroup fg_FactSalesBranch09
alter database dwh add filegroup fg_FactSalesBranch10
alter database dwh add filegroup fg_FactSalesBranch11
alter database dwh add filegroup fg_FactSalesBranch12
alter database dwh add filegroup fg_FactSalesBranch13
go
alter database dwh add file (
name='dwh_FSAllBranches2', 
filename ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dwh_fsallbranches2.ndf',
size=400mb,
filegrowth=8mb) to filegroup fg_FactSalesAllBranches
go
alter database dwh add file (name='dwh_fsbranch01', filename ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dwh_fsb01.ndf',size=100mb,filegrowth=8mb) to filegroup fg_FactSalesBranch01
alter database dwh add file (name='dwh_fsbranch02', filename ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dwh_fsb02.ndf',size=100mb,filegrowth=8mb) to filegroup fg_FactSalesBranch02
alter database dwh add file (name='dwh_fsbranch03', filename ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dwh_fsb03.ndf',size=100mb,filegrowth=8mb) to filegroup fg_FactSalesBranch03
alter database dwh add file (name='dwh_fsbranch04', filename ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dwh_fsb04.ndf',size=100mb,filegrowth=8mb) to filegroup fg_FactSalesBranch04
alter database dwh add file (name='dwh_fsbranch05', filename ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dwh_fsb05.ndf',size=100mb,filegrowth=8mb) to filegroup fg_FactSalesBranch05
alter database dwh add file (name='dwh_fsbranch06', filename ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dwh_fsb06.ndf',size=100mb,filegrowth=8mb) to filegroup fg_FactSalesBranch06
alter database dwh add file (name='dwh_fsbranch07', filename ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dwh_fsb07.ndf',size=100mb,filegrowth=8mb) to filegroup fg_FactSalesBranch07
alter database dwh add file (name='dwh_fsbranch08', filename ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dwh_fsb08.ndf',size=100mb,filegrowth=8mb) to filegroup fg_FactSalesBranch08
alter database dwh add file (name='dwh_fsbranch09', filename ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dwh_fsb09.ndf',size=100mb,filegrowth=8mb) to filegroup fg_FactSalesBranch09
alter database dwh add file (name='dwh_fsbranch10', filename ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dwh_fsb10.ndf',size=100mb,filegrowth=8mb) to filegroup fg_FactSalesBranch10
alter database dwh add file (name='dwh_fsbranch11', filename ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dwh_fsb11.ndf',size=100mb,filegrowth=8mb) to filegroup fg_FactSalesBranch11
alter database dwh add file (name='dwh_fsbranch12', filename ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dwh_fsb12.ndf',size=100mb,filegrowth=8mb) to filegroup fg_FactSalesBranch12
alter database dwh add file (name='dwh_fsbranch13', filename ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\dwh_fsb13.ndf',size=100mb,filegrowth=8mb) to filegroup fg_FactSalesBranch13

go
create partition function pf_FactSalesAllBranches(int)
as
range right for values 
(1,2,3,4,5,6,7,8,9,10,11,12,13)

go --alter the partition function later but after you insert branchid 14 in dbo.FactSales_PT.

ALTER PARTITION FUNCTION pf_FactSalesAllBranches ()  
SPLIT RANGE (14);  
go
create partition function pf_FactSalesBranches(int)
as
range right for values 
(1,2,3,4,5,6,7,8,9,10,11,12,13)
go
create partition scheme ps_FactSalesAllBranches
as
partition pf_FactSalesAllBranches ALL TO (fg_FactSalesAllBranches)
go
create partition scheme ps_FactSalesBranches
as
partition pf_FactSalesBranches to(
[PRIMARY],
fg_FactSalesBranch01, fg_FactSalesBranch02, fg_FactSalesBranch03, fg_FactSalesBranch04,
fg_FactSalesBranch05, fg_FactSalesBranch06, fg_FactSalesBranch07, fg_FactSalesBranch08,
fg_FactSalesBranch09, fg_FactSalesBranch10, fg_FactSalesBranch11, fg_FactSalesBranch12,
fg_FactSalesBranch13)


go
CREATE TABLE [dbo].[FactSales_PT](
	[DateId] [int] NOT NULL,
	[ArticleId] [int] NOT NULL,
	[BranchId] [int] NOT NULL,
	[OrderId] [int] NOT NULL,
	[Quantity] [decimal](9, 3) NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[Amount] [money] NOT NULL,
	[DiscountPcnt] [decimal](6, 3) NOT NULL,
	[DiscountAmt] [money] NOT NULL,
	[TaxAmt] [money] NOT NULL,
 CONSTRAINT [PK_FactSales_PT] PRIMARY KEY CLUSTERED 
(
	[DateId] ASC,
	[ArticleId] ASC,
	[BranchId] ASC,
	[OrderId] ASC
--)) ON ps_FactSalesBranches(BranchId)
)) ON ps_FactSalesAllBranches(BranchId)
GO

ALTER TABLE [dbo].[FactSales_PT]  WITH CHECK ADD FOREIGN KEY([ArticleId])
REFERENCES [dbo].[DimArticles] ([ArticleId])
GO

ALTER TABLE [dbo].[FactSales_PT]  WITH CHECK ADD FOREIGN KEY([BranchId])
REFERENCES [dbo].[DimBranches] ([BranchId])
GO

ALTER TABLE [dbo].[FactSales_PT]  WITH CHECK ADD FOREIGN KEY([DateId])
REFERENCES [dbo].[DimDates] ([DateId])
GO

insert into [FactSales_PT]
select * from [FactSales]


select 
'['+schema_name(schema_id)+'].['+t.name+']', p.partition_number, master.dbo.format(rows,-1) rows, 
index_id, fg.name filegroup_name,fg.is_default is_default_filegroup, 
a.type, a.type_desc, 
fg.data_space_id, total_pages, used_pages, data_pages
from sys.allocation_units a inner join sys.partitions p
on ((a.type in (1,3) and a.container_id = p.hobt_id)
or (a.type in (2) and a.container_id = p.partition_number))
inner join sys.filegroups fg
on fg.data_space_id = a.data_space_id
inner join sys.tables t
on t.object_id = p.object_id
where '['+schema_name(schema_id)+'].['+t.name+']' = '[dbo].[FactSales_PT]'

TRUCATE TABLE [dbo].[FactSales_PT] WITH (PARTITIONS (5))
--check after truncate the partition in milliseconds
select top 10 * from [dbo].[FactSales_PT] where branchid = 3

--Add new row with different branchid (14), and then you will see that the new record was allocated in the last partition
--so alter the partition function to Split Range (14)
select * from DimBranches
insert into DimBranches values (14,14,'City','Region','Country')
insert into [dbo].[FactSales_PT] values (1,5,14,8116955,51.000,5.99,305.49,0.000,0.00,0.2995)

--to see that this record(s) are allocated in new pages regarding the spliting with different partition
select 'dbcc page(0,'+fileid+','+pageid+',3)',
* from (
select 
cast(dbRecovery.dbo.Hex_to_Decimal_fn_dblog(substring(convert(varchar(50),%%physloc%%,2),1,8 )) as varchar(10)) pageid,
cast(dbRecovery.dbo.Hex_to_Decimal_fn_dblog(substring(convert(varchar(50),%%physloc%%,2),9,4 )) as varchar(10)) fileid,
cast(dbRecovery.dbo.Hex_to_Decimal_fn_dblog(substring(convert(varchar(50),%%physloc%%,2),13,3)) as varchar(10)) slotid,
* from [dbo].[FactSales_PT] where BranchId = 14)a

select * from sys.dm_db_database_page_allocations(db_id(), object_id('[dbo].[FactSales_PT]'),5,null,'detailed')

DBCC page(0,17,5136,3) -- data page 
DBCC traceon(3604)
create nonclustered index idx_branchid_factsales_pt on dbo.factsales_pt (branchid)
DBCC page(0,17,170504,3) -- index page


