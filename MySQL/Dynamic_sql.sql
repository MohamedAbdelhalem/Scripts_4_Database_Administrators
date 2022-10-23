DELIMITER $$
CREATE PROCEDURE `SELECT_Table_Multi`
(
in p_table_name varchar(500), 
in p_from_timestamp bigint,
in p_to_timestamp bigint,
in p_devtype varchar(100),
in p_parttype varchar(100),
in p_metric varchar(100),
in p_object varchar(100),
in p_calc varchar(100),
in p_instance varchar(100)
)
BEGIN
DECLARE start  INT DEFAULT 0;      

DECLARE v_finished INTEGER DEFAULT 0;
DECLARE v_tables varchar(4000) default '';
DECLARE v_table_name varchar(500); 
DECLARE v_from_timestamp varchar(200);
DECLARE v_to_timestamp varchar(200); 
DECLARE str varchar(4000); 

#select @v_x1 := start;
#select @v_x2 := start;

DECLARE curs_tab CURSOR 
FOR 
select table_name, from_timestamp, to_timestamp
  from (
        select t1.table_name, t1.my_conv from_timestamp,  case when t2.my_conv is null then current_timestamp() else t2.my_conv end to_timestamp
          from (
                select id1, id1 +1 id2, table_name, my_conv
                  from (
                        select (@v_x1 := @v_x1 + 1) id1, table_name, my_conv
                          from (
                                select table_name, FROM_UNIXTIME(time_stamp) my_conv
                                  from (
                                        select table_name, substring(replace(table_name, p_table_name,''), instr(replace(table_name, p_table_name,''), '_')+1,length(table_name)) time_stamp
                                          from information_schema.tables
                                         where table_name like concat(p_table_name,'%')
                                           and table_name != p_table_name
                                           and TABLE_SCHEMA = database()
                                       )as a
                               )as b, (select @v_x1 := 0) r
                       )as c 
               )t1 left outer join (
                                    select id1, id1 +1 id2,table_name, my_conv
                                      from (
                                      select (@v_x2 := @v_x2 + 1) id1, table_name, my_conv
                                              from (
                                                    select table_name, FROM_UNIXTIME(time_stamp) my_conv
                                                      from (select table_name, substring(replace(table_name, p_table_name,''), instr(replace(table_name, p_table_name,''), '_')+1,length(table_name)) time_stamp
                                                              from information_schema.tables
                                                             where table_name like concat(p_table_name,'%')
	                                                       and table_name != p_table_name
                                                               and TABLE_SCHEMA = database()
                                                           )as a
                                                   )as b, (select @v_x2 := 0) r
                                           )as c
                                   )as t2
                     on t1.id2 = t2.id1
               )e
where to_timestamp >= cast(date_add('1970-01-01 03:00:00', interval p_from_timestamp second) as char) 
and from_timestamp <= cast(date_add('1970-01-01 03:00:00', interval p_to_timestamp second) as char);

DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_finished = 1;
OPEN curs_tab;
get_tables: LOOP
FETCH curs_tab INTO v_table_name, v_from_timestamp, v_to_timestamp;
IF v_finished = 1 THEN 
LEAVE get_tables;
END IF;

set v_tables = concat(v_tables, concat('select * from ',v_table_name,'#union all '));

END LOOP get_tables;
CLOSE curs_tab;

set str = replace(reverse(substring(reverse(v_tables), instr(reverse(v_tables),'#')+1,length(v_tables))),'#',' ');


set str = concat('select timestamp AS TS, ',p_calc,'(average) AS V, p.',p_instance,' as INSTANCE  
from (
',str,') as d inner join data_property_flat p
on p.id = d.variable
where p.devtype  = ','''',p_devtype,'''','
  and p.parttype = ','''',p_parttype,'''','
  and p.name = ','''',p_metric,'''','
  and p.device = ','''',p_object,'''','
  and d.timestamp between ',p_from_timestamp,' and ',p_to_timestamp,
' group by d.timestamp, p.',p_instance,'');

#select str;

set @SQL := str;
PREPARE STMT FROM @SQL; 
EXECUTE STMT; 
DEALLOCATE PREPARE STMT;

END$$
DELIMITER ;

