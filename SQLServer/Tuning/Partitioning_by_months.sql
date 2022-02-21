Declare 
@loop int = 0, 
@sql varchar(max), 
@mon char(2), 
@month char(3),
@db_name varchar(300) ='AdventureWorks2017'

While @loop < 12
Begin 
Select @mon = case when 
Len(datepart(MONTH,dateadd(month,@loop,'2000-01-01'))) = 1 
Then '0'+cast(datepart(MONTH,dateadd(month,@loop,'2000-01-01')) as varchar(2))
Else cast(datepart(MONTH,dateadd(month,@loop,'2000-01-01')) as varchar(2)) end,
@month = case datepart(MONTH,dateadd(month,@loop,'2000-01-01'))
When 1 then 'Jan'
When 2 then 'Feb'
When 3 then 'Mar'
When 4 then 'Apr'
When 5 then 'May'
When 6 then 'Jun'
When 7 then 'Jul'
When 8 then 'Aug'
When 9 then 'Sep'
When 10 then 'Oct'
When 11 then 'Nov'
When 12 then 'Dec'
End
Set @sql= '
Alter database ['+@db_name+'] add filegroup Month_'+@mon+'_'+@month+';
Alter database ['+@db_name+'] add file (
Name=''Month_'+@mon+''', 
Filename=''C:\dataFiles\Month_'+@mon+'_'+@month+'.ndf'', 
Size = 10mb, 
Filegrowth= 128mb, 
Maxsize=unlimited) 
To filegroup Month_'+@mon+'_'+@month+';'
Print(@sql)
Exec(@sql)
Set @loop = @loop + 1
End

CREATE Partition Function pf_Months(int)
AS Range Right for Values 
(1,2,3,4,5,6,7,8,9,10,11,12)

CREATE PARTITION scheme ps_Months
AS PARTITION pf_Months
TO 
( [PRIMARY],
  [Month_01_Jan], [Month_02_Feb], [Month_03_Mar],
  [Month_04_Apr], [Month_05_May], [Month_06_Jun], 
  [Month_07_Jul], [Month_08_Aug], [Month_09_Sep], 
  [Month_10_Oct], [Month_11_Nov], [Month_12_Dec]
);

CREATE TABLE [dbo].[SalesOrderHeader](
	[SalesOrderID] [int] NOT NULL,
	[Partition_ID]  AS (datepart(month,[OrderDate])) PERSISTED NOT NULL,
	[RevisionNumber] [tinyint] NOT NULL,
	[OrderDate] [datetime] NOT NULL,
	[DueDate] [datetime] NOT NULL,
	[ShipDate] [datetime] NULL,
	[Status] [tinyint] NOT NULL,
	[OnlineOrderFlag] [bit] NOT NULL,
	[SalesOrderNumber] [nvarchar](23) NULL,
	[PurchaseOrderNumber] [nvarchar](25) NULL,
	[AccountNumber] [nvarchar](15) NULL,
	[CustomerID] [int] NOT NULL,
	[SalesPersonID] [int] NULL,
	[TerritoryID] [int] NULL,
	[BillToAddressID] [int] NOT NULL,
	[ShipToAddressID] [int] NOT NULL,
	[ShipMethodID] [int] NOT NULL,
	[CreditCardID] [int] NULL,
	[CreditCardApprovalCode] [varchar](15) NULL,
	[CurrencyRateID] [int] NULL,
	[SubTotal] [money] NOT NULL,
	[TaxAmt] [money] NOT NULL,
	[Freight] [money] NOT NULL,
	[TotalDue] [money] NOT NULL,
	[Comment] [nvarchar](128) NULL,
 CONSTRAINT [PK_SalesOrderHeader_SalesOrderID] PRIMARY KEY CLUSTERED 
--([SalesOrderID], [Partition_ID])) on ps_Months([Partition_ID]) -- make the cluster key first 
  ([Partition_ID], [SalesOrderID])) on ps_Months([Partition_ID]) -- make the Partition Id first 
GO

Insert into [dbo].[SalesOrderHeader](
[SalesOrderID], [RevisionNumber], [OrderDate], [DueDate], [ShipDate], [Status], [OnlineOrderFlag], [SalesOrderNumber], 
[PurchaseOrderNumber], [AccountNumber], [CustomerID], [SalesPersonID], [TerritoryID], [BillToAddressID], [ShipToAddressID], 
[ShipMethodID], [CreditCardID], [CreditCardApprovalCode], [CurrencyRateID], [SubTotal], [TaxAmt], [Freight], [TotalDue], [Comment])
Select 
[SalesOrderID], [RevisionNumber], [OrderDate], [DueDate], [ShipDate], [Status], [OnlineOrderFlag], [SalesOrderNumber], 
[PurchaseOrderNumber], [AccountNumber], [CustomerID], [SalesPersonID], [TerritoryID], [BillToAddressID], [ShipToAddressID], 
[ShipMethodID], [CreditCardID], [CreditCardApprovalCode], [CurrencyRateID], [SubTotal], [TaxAmt], [Freight], [TotalDue], [Comment]
From [AdventureWorks2017].[Sales].[SalesOrderHeader]


select '['+schema_name(schema_id)+'].['+t.name+']' table_name, 
index_id, case when fg.name != 'PRIMARY' then partition_number - 1 else partition_number end partition_number, 
master.dbo.format(rows,-1) rows, fg.name [filegroup_name]
from sys.partitions p inner join sys.allocation_units a
on (a.type in (1,3) and a.container_id = p.partition_id)
or (a.type in (2) and a.container_id = p.hobt_id)
inner join sys.filegroups fg 
on a.data_space_id = fg.data_space_id
inner join sys.tables t
on p.object_id = t.object_id
where p.object_id in (object_id('[dbo].[FactSales]'),object_id('[dbo].[FactSales2]'),object_id('[dbo].[FactSales3]'))
and t.name = 'FactSales3'


Select * from [SalesOrderHeader]
Where SalesOrderID = 55464
