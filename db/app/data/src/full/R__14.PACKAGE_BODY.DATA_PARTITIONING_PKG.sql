CREATE OR REPLACE PACKAGE BODY "DATA_PARTITIONING_PKG" 
is

create or replace procedure drop_old_partitions 
                            (p_table_name IN VARCHAR2
                           , p_threshold IN NUMBER)
   is
    
     cursor tab_interval IS
      select partition_name
                  , high_value
            from user_tab_partitions
           where table_name = p_table_name
             and interval = 'YES';
     
   begin
   for part in tab_interval
   loop
     execute immediate 
       'begin
          if months_between(sysdate
             , '||part.high_value||') > ' 
                || p_threshold || 'then
            execute immediate
              ''alter table '|| p_table_name ||' drop partition ' 
            || part.partition_name
            ||''';
          end if;
         end;';
   end loop;
   end;

end DATA_PARTITIONING_PKG;
/

