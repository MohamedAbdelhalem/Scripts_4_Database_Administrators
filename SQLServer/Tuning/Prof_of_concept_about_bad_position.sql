CREATE DATABASE TestFillFactor;
GO
USE TestFillFactor
GO
CREATE TABLE tbWindowsClusters (
	WindowsClusterId INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
	Name VARCHAR(300) NOT NULL, 
	IpAddress VARCHAR(20) NOT NULL)

insert into tbWindowsClusters values ('WinCLuster043','10.13.32.50'),('WinCLuster044','10.13.38.31'),('WinCLuster045','10.13.32.190')

CREATE TABLE tbVLans (
	VLanId INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
	Name VARCHAR(300) NOT NULL, 
	Number INT NOT NULL)
insert into tbVLans values ('ProdDB','23456'),('ProdDB2','23488'),('DCVlan','12345')

CREATE TABLE tbOss (
	OsId INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
	Name VARCHAR(300) NOT NULL)
insert into tbOss values ('Microsoft Windows Server'),('Linux Red Hat')

CREATE TABLE tbEsxiClusters (
	EsxiClusterId INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
	Name VARCHAR(300) NOT NULL)
insert into tbEsxiClusters values ('RAC-AF8DC01-AMPvSANCLS01')

CREATE TABLE tbEsxiPhysicalServers (
	PhysicalServerId INT IDENTITY(1,1) PRIMARY KEY, 
	Name VARCHAR(300), 
	IpAddress VARCHAR(20), 
	EsxiId int)
insert into tbEsxiPhysicalServers values 
('af8dc01-r02-c07-ampvsan03-s01.rac.sa','172.16.51.55',1),
('af8dc01-r02-c07-ampvsan03-s02.rac.sa','172.16.51.56',1),
('t5dc02-r02-c04-ampvsan03-s03.rac.sa','172.16.51.57',1)
ALTER TABLE tbEsxiPhysicalServers ADD CONSTRAINT fk_EsxiId_tbEsxiPhysicalServers FOREIGN KEY (EsxiId) REFERENCES tbEsxiClusters (EsxiClusterId)

CREATE TABLE tbDataCenters (
	DataCenterId INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
	Name VARCHAR(300) NOT NULL)
insert into tbDataCenters values ('AF8'),('T5')

CREATE TABLE tbServerTypes (
	ServerTypeId INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
	Name VARCHAR(300) NOT NULL)
insert into tbServerTypes values ('Application'),('Database'),('File Server'),('Load Balancer'),('Domain Controller')

CREATE TABLE tbServerPurposes (
	ServerPurposeId INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
	Name VARCHAR(300) NOT NULL)
insert into tbServerPurposes values ('Test'),('Dev'),('PreProd'),('Prod'),('POC')

CREATE TABLE tbDepartments (
	DepartmentId INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
	Name VARCHAR(300) NOT NULL)
insert into tbDepartments values ('Infrastructure'),('Application'),('Security'),('Network')
select * from tbJobs
CREATE TABLE tbJobs (
	JobId INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
	Name VARCHAR(300) NOT NULL)
insert into tbJobs values	('Chief Executive Officer'),
							('Vice President of Engineering'),
							('Engineering Manager'),
							('Senior Tool Designer'),
							('Design Engineer'),
							('Research and Development Manager'),
							('Senior Tool Designer'),
							('Tool Designer'),
							('Senior Design Engineer'),
							('Design Engineer'),
							('Marketing Manager'),
							('Marketing Assistant')
CREATE TABLE tbEmployees (
	EmployeeId INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
	FullName VARCHAR(300) NOT NULL, 
	Email varchar(1000) NULL, 
	CellPhone varchar(20) NULL, 
	Office varchar(20) NULL, 
	DepartmentId int NOT NULL, 
	JobId int NOT NULL)
ALTER TABLE tbEmployees ADD CONSTRAINT fk_DepartmentId_tbEmployees FOREIGN KEY (DepartmentId) REFERENCES tbDepartments (DepartmentId)
ALTER TABLE tbEmployees ADD CONSTRAINT fk_JobId_tbEmployees FOREIGN KEY (JobId) REFERENCES tbJobs (JobId)

--#######################################################
--to insert data into tbEmployees
--#######################################################
create table randam (number int)
GO
insert into randam values (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22),(23),(24)
GO
create view vRandam as select top 1 number from randam order by NEWID()
GO
create function get_random(@f int, @t int)
returns int
as
begin
declare @number int = null
while @number is null
begin
select @number = number from vRandam where number between @f and @t
end
return @number
end
GO
declare @id int
declare i cursor fast_forward
for
select number from randam order by newid()
open i 
fetch next from i into @id
while @@FETCH_STATUS = 0
begin
insert into tbEmployees (FullName, Email, CellPhone, Office, DepartmentId, JobId)
select firstname+' '+isnull(MiddleName+' ','')+lastname, EmailAddress, '05'+substring(cast(NationalIDNumber as varchar(15)),3,20), NULL,
dbo.get_random(1,4),  
dbo.get_random(1,16)
from AdventureWorks2017.Person.persons p inner join AdventureWorks2017.Person.EmailAddress e
on p.BusinessEntityID = e.BusinessEntityID
inner join AdventureWorks2017.HumanResources.Employee ep
on p.BusinessEntityID = ep.BusinessEntityID 
where p.BusinessEntityID = @id
fetch next from i into @id
end
close i
deallocate i
--#######################################################

CREATE TABLE tbServers (
	ServerId INT IDENTITY(1,1) NOT NULL, 
	ServerName VARCHAR(300) NOT NULL, 
	IpAddress VARCHAR(20) NOT NULL, 
	VLanId INT NOT NULL, 
	OsId INT NOT NULL,	
	EsxiClusterId INT NOT NULL, 
	DataCenterId INT NOT NULL,
	OwnerId INT NOT NULL,
	ServerType INT NOT NULL,
	ServerPurpose INT NOT NULL,
	IsCluster BIT NOT NULL,
	WindowsClusterId INT NULL,
	CreationDate DATETIME DEFAULT getdate())

CREATE UNIQUE CLUSTERED INDEX C_IPADDRESS_tbServers ON tbServers (IPADDRESS)
ALTER TABLE tbServers ADD CONSTRAINT pk_ServerId_tbServers PRIMARY KEY (ServerId) WITH (FILLFACTOR = 90)
ALTER TABLE tbServers ADD CONSTRAINT fk_VLanId_tbServers FOREIGN KEY (VLanId) REFERENCES tbVLans (VLanId)
ALTER TABLE tbServers ADD CONSTRAINT fk_OsId_tbServers FOREIGN KEY (OsId) REFERENCES tbOss (OsId)
ALTER TABLE tbServers ADD CONSTRAINT fk_EsxiClusterId_tbServers FOREIGN KEY (EsxiClusterId) REFERENCES tbEsxiClusters (EsxiClusterId)
ALTER TABLE tbServers ADD CONSTRAINT fk_DataCenterId_tbServers FOREIGN KEY (DataCenterId) REFERENCES tbDataCenters (DataCenterId)
ALTER TABLE tbServers ADD CONSTRAINT fk_ServerType_tbServers FOREIGN KEY (ServerType) REFERENCES tbServerTypes (ServerTypeId)
ALTER TABLE tbServers ADD CONSTRAINT fk_SServerPurpose_tbServers FOREIGN KEY (ServerPurpose) REFERENCES tbServerPurposes (ServerPurposeId)
ALTER TABLE tbServers ADD CONSTRAINT fk_WindowsClusterId_tbServers FOREIGN KEY (WindowsClusterId) REFERENCES tbWindowsClusters (WindowsClusterId)
ALTER TABLE tbServers ADD CONSTRAINT fk_OwnerId_tbServers FOREIGN KEY (OwnerId) REFERENCES tbEmployees (EmployeeId)

insert into tbServers values ('RAC-SQL-Cluster01','10.13.32.23',1,1,1,1,34,4,2,1,1,'2020-09-23')
insert into tbServers values ('RAC-SQL-Cluster02','10.13.32.53',1,1,1,1,34,4,2,1,1,'2020-09-23')
insert into tbServers values ('RAC-SQL-Cluster03','10.13.38.29',2,1,1,1,36,4,2,1,2,'2021-02-05')
insert into tbServers values ('RAC-SQL-Cluster04','10.13.38.30',2,1,1,1,36,4,2,1,2,'2021-02-05')

select * from tbServers
create nonclustered index idx_IpAddress_tbServers on tbServers (IpAddress) with (fillfactor = 80)
create nonclustered index idx_IpAddress_serverId_tbServers on tbServers (IpAddress, ServerId) with (fillfactor = 80)
create nonclustered index idx_ServerId_IpAddress_tbServers on tbServers (ServerId, IpAddress) with (fillfactor = 80)
create nonclustered index idx_IpAddress_ServerName_ServerId_tbServers on tbServers (IpAddress, ServerName, ServerId) with (fillfactor = 80)
create nonclustered index idx_ServerName_IpAddress_ServerId_tbServers on tbServers (ServerName, IpAddress, ServerId) with (fillfactor = 80)
create nonclustered index idx_ServerId_ServerName_IpAddress_tbServers on tbServers (ServerId, ServerName, IpAddress) with (fillfactor = 80)

ALTER INDEX C_IPADDRESS_tbServers ON tbServers REBUILD PARTITION = ALL
ALTER INDEX pk_ServerId_tbServers ON tbServers REBUILD PARTITION = ALL
ALTER INDEX idx_IpAddress_tbServers ON tbServers REBUILD PARTITION = ALL
ALTER INDEX idx_IpAddress_serverId_tbServers ON tbServers REBUILD PARTITION = ALL
ALTER INDEX idx_ServerId_IpAddress_tbServers ON tbServers REBUILD PARTITION = ALL
ALTER INDEX idx_IpAddress_ServerName_ServerId_tbServers ON tbServers REBUILD PARTITION = ALL
ALTER INDEX idx_ServerName_IpAddress_ServerId_tbServers ON tbServers REBUILD PARTITION = ALL
ALTER INDEX idx_ServerId_ServerName_IpAddress_tbServers ON tbServers REBUILD PARTITION = ALL

select dbp.index_id, i.name index_name, allocated_page_file_id, allocated_page_page_id, page_type_desc, page_level 
from sys.dm_db_database_page_allocations(db_id(), object_id('dbo.tbServers'), null, null, 'detailed') dbp inner join sys.indexes i
on dbp.object_id = i.object_id
and dbp.index_id = i.index_id
where is_allocated = 1
and page_type in (1,2)
and i.name+' '+cast(i.object_id as varchar(20)) in (
select index_name+' '+cast(object_id as varchar(20))
from (
select row_number() over(partition by i.name, i.object_id order by i.object_id, i.name) identity_column_position,
c.name index_column_name,c.is_identity, i.index_id, isnull(i.name,'') index_name, t.object_id, 
'['+schema_name(t.schema_id)+'].['+t.name+']' table_name, 
i.type_desc index_type, fill_factor WRONG_FillFactor_Val , 0 RIGHT_FillFactor_Val, is_unique, is_unique_constraint  
from sys.indexes i inner join sys.tables t
on i.object_id = t.object_id
inner join sys.index_columns ic
on i.index_id = ic.index_id
and i.object_id = ic.object_id
inner join sys.columns c
on c.object_id = ic.object_id
and c.column_id = ic.column_id
where fill_factor between 1 and 99
and ic.is_included_column = 0)a
where is_identity = 1 
and identity_column_position != 1)

select identity_column_position, index_column_name, is_identity, index_id, index_name, object_id, table_name, index_type, 
WRONG_FillFactor_Val, RIGHT_FillFactor_Val, is_unique, is_unique_constraint 
from (
select row_number() over(partition by i.name, i.object_id order by i.object_id, i.name) identity_column_position,
c.name index_column_name,c.is_identity, i.index_id, isnull(i.name,'') index_name, t.object_id, 
'['+schema_name(t.schema_id)+'].['+t.name+']' table_name, 
i.type_desc index_type, fill_factor WRONG_FillFactor_Val , 0 RIGHT_FillFactor_Val, is_unique, is_unique_constraint  
from sys.indexes i inner join sys.tables t
on i.object_id = t.object_id
inner join sys.index_columns ic
on i.index_id = ic.index_id
and i.object_id = ic.object_id
inner join sys.columns c
on c.object_id = ic.object_id
and c.column_id = ic.column_id
where fill_factor between 1 and 99
and ic.is_included_column = 0)a
where is_identity = 1 
and identity_column_position != 1
order by table_name, index_name

--insert and monitor the pages in all indexes
insert into tbServers values ('RACDOMAINCTL01','10.10.100.199',3,1,1,1,16,4,5,0,NULL,'2021-12-15')
select * from tbServers

dbcc traceon (3604,-1)
dbcc page (0, 1, 568, 3) -- clustered index (table)						          -- unfortunately it's very bad designed index because the clustered index 
                                                                        -- changes the pages orders
dbcc page (0, 1, 488, 3) -- pk_ServerId_tbServers						            -- good index no page split because the identity column
dbcc page (0, 1, 496, 3) -- idx_IpAddress_tbServers						          -- bad index because the first column makes page split
dbcc page (0, 1, 512, 3) -- idx_IpAddress_serverId_tbServers			      -- bad index because the first column makes page split
dbcc page (0, 1, 520, 3) -- idx_ServerId_IpAddress_tbServers			      -- good index no page split because the identity column
dbcc page (0, 1, 528, 3) -- idx_IpAddress_ServerName_ServerId_tbServers -- bad index and in this case there is a page split
dbcc page (0, 1, 536, 3) -- idx_ServerName_IpAddress_ServerId_tbServers -- bad index and by the chance there is no page split 
dbcc page (0, 1, 552, 3) -- idx_ServerId_ServerName_IpAddress_tbServers -- the perfect index because the identity column in the first ordering


