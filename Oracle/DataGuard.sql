https://www.youtube.com/watch?v=wfzEfeNvr_Q
https://www.youtube.com/watch?v=1UsKglLEvtc

http://ocptechnology.com/oracle-dataguard/

show parameter db_name
show parameter db_unique_name

archive log list

select log_mode from $database;

shutdown immediate 

alter database archivelog;

select force_logging from v$database;

alter database force logging;

select force_logging from v$database;

alter system set log_archive_config='DG_CONFIG=(db11g,std)';

host
netmgr 
add service naming

Net Service Name		std				next
comunicate with the database	TCP/IP (Internet Protocol)	next
Host Name			192.168.1.20
Port Number			1521				next
Service Name			std
Connection Type			Database Default		next
								finish
File				Save Network Configuration	Exit

lsnrctl start

alter system set log_archive_dest_2=;SERVICE=std VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=std';
System altered.

alter system set log_archive_desc_state_2=ENABLE;
System altered.

show parameter remote_login_passwordfile

alter system set remote_login_passwordfile=exclusive scope=spfile;
system altered.

alter system set FAL_SERVER=std;
system altered.

alter system set DB_FILE_NAME_CONVERT='std','db11g' scope=spfile;
system altered.

alter system set log_file_name_convert='std','db11g' scope=spfile;

alter system set standby_file_management=auto;

rman target/

backup database plus archivelog;

SQL>

alter database create standby controlfile as '/u01/stdcontrol.ctl';

create pfile='u01/initstd.ora' from spfile;

vi /u01/initstd.ora
i

change from db11g to std in all parameters

*.db_file_name_convert='db11g','std'
*.db_name='db11g'
*.db_unique_name='std'
*.fal_server
*.log_archive_dest_2='SERVICE=db11g VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=db11g'
*.log_file_name_convert='db11g','std'

create the directories for in the standby database
and offcaurse all directories in the initstd.ora

ssh@192.168.1.20
password: 

*.audit_file_dest parameter
mkdir -p /u01/app/oracle/admin/std/adump

*.control_files
mkdir -p /u01/app/oracle/oradata/std
mkdir -p /u01/app/oracle/fast_recovery_area/std


save the initstd.ora

copy the files

scp /u01/initstd.ora oracle@192.168.1.20:/u01/
password:
scp /u01/stdcontrol.ctl oracle@192.168.1.20:/u01
password:
scp /u01/stdcontrol.ctl oracle@192.168.1.20:/u01/app/oracle/oradata/std/control01.ctl
password:
scp /u01/stdcontrol.ctl oracle@192.168.1.20:/u01/app/oracle/fast_recovery_area/std/control02.ctl
password:


scp -r /u01/app/oracle/fast_recovery_area/DB11G oracle@192.168.1.20:/u01/app/oracle/fast_recovery_area
password:

scp /u01/app/oracle/product/11.2.0.4/db_1/dbs/orapwdb11g oracle@192.168.1.20:/u01/app/oracle/product/11.2.0.4/db_1/dbs/orapwstd
password:

connect to standby database

export ORACLE_BASE=/u01/app
export ORACLE_HOME=$ORACLE_BASE/oracle/product/11.2.0.4/db_1
netmgt

open Naming Services

add Naming Services for the two databases db11g and std
Net Service Name		db11g				next
comunicate with the database	TCP/IP (Internet Protocol)	next
Host Name			192.168.1.10	
Port				1521				next
Service Name 			db11g				
Connection Type			Database Default		next
								finish
add another service

Net Service Name		std				next
comunicate with the database	TCP/IP (Internet Protocol)	next
Host Name			192.168.1.20
Port				1521				next
Service Name			std	
Connection Type			Database Default		next
								finish

file				Save Network Configuration	exit

lsnrctl start

lsnrctl stop 
lsnrctl start


vi /etc/oratab

and then add this line in the last line

std:/u01/app/oracle/product/11.2.0.1/db_1:N

export ORACLE_SID=std
export sqlplus / as sysdba

create spfile from pfile='/u01/initstd.ora';
host

rman target/

starup mount

restore database;

Finished restore at 05-APR-17

RMAN> exit

sqlplus / as sysdba

create standby redolog files

go to the primary database

select group#, member from v$logfile;

go again to the standby database

alter database add standby logfile ('u01/app/oracle/oradata/std/standby_redo01.log') size 50m;
alter database add standby logfile ('u01/app/oracle/oradata/std/standby_redo02.log') size 50m;
alter database add standby logfile ('u01/app/oracle/oradata/std/standby_redo03.log') size 50m;
alter database add standby logfile ('u01/app/oracle/oradata/std/standby_redo04.log') size 50m;


desc v$logfile

select group#, member from v$logfile where type = 'STANDBY';

go to primary database server

SQL>

alter database add standby logfile ('u01/app/oracle/oradata/db11g/standby_redo01.log') size 50m;
alter database add standby logfile ('u01/app/oracle/oradata/db11g/standby_redo02.log') size 50m;
alter database add standby logfile ('u01/app/oracle/oradata/db11g/standby_redo03.log') size 50m;
alter database add standby logfile ('u01/app/oracle/oradata/db11g/standby_redo04.log') size 50m;


select group#, member from v$logfile where type = 'STANDBY';

host

tail -f /u01/app/oracle/diag/rdbms/std/std/trace/alert_std.log

exit

SQL> alter database recover managed standby database disconnect from session;

Database altered.

check the redo sequence number

in primary database

select sequence#, first_time, next_time 
from v$archive_log
order by sequence#;

then check the redo sequence number

in standby database

select sequence#, first_time, next_time, applied
from v$archive_log
order by sequence#;

then test the archive logs in the primary to standby database

in primary database 

alter system switch logfile;

select sequence#, first_time, next_time 
from v$archive_log
order by sequence#;

then check in the standby database what happened

select sequence#, first_time, next_time, applied
from v$archive_log
order by sequence#;

in standby database

select name, open_mode, database_role, db_unique_name, protection_mode 
from v$database;

NAME	OPEN_MODE		DATABASE_ROLE		DB_UNIQUE_NAME		PROTECTION_MODE
------- ----------------------- ----------------------- ----------------------- ---------------------
DB11G    MOUNTED		PHYSICAL STANDBY	std			MAXIMUM PERFORMANCE

then run this queury to check the mode of the primary database

select name, open_mode, database_role, db_unique_name, protection_mode 
from v$database;

NAME	OPEN_MODE		DATABASE_ROLE		DB_UNIQUE_NAME		PROTECTION_MODE
------- ----------------------- ----------------------- ----------------------- ---------------------
DB11G    READ WRITE		PRIMARY			db11g			MAXIMUM PERFORMANCE

