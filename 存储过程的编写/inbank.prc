create or replace procedure inbank is
    recorddate receivables.yearmonth%type;
    balance device.balance%type;
    total device.balance%type;
    month_pay device.balance%type;
    currenttype device.type%type;
    currentid device.deviceid%type;
    basicfee device.balance%type;
    flag receivables.flag%type;
    sysyear number;
    sysmonth number;
    recordyear number;
    recordmonth number;

    
    --�ҵ�ǰһ�췢���䶯���豸id
    cursor id_cursor is
           select d.deviceid,p.paymoney
           from device d,payfee p
           where to_char(p.paydate,'yyyyMMdd')
           =to_char(sysdate-1,'yyyyMMdd')
           and d.deviceid=p.deviceid
           and (p.type='2000' or p.type='2002');

    
    --�ҵ�Ӧ�շ����е�������Ӧ���Ľ��
    cursor month_cursor is
           select r.basicfee,r.yearmonth,r.flag
           from receivables r
           where r.deviceid=currentid
           and flag = 0--�ҳ�δ���Ĳ���
           order by r.yearmonth desc;
begin
  
      open id_cursor;
      
      loop 
        fetch id_cursor into currentid,total;
        exit when id_cursor%notfound;
        dbms_output.put_line(123); 
        select device.balance,device.type
        into balance,currenttype
        from device
        where device.deviceid=currentid;
        
        total:=total+balance;
        
        
        open month_cursor;
        loop
          fetch month_cursor into basicfee,recorddate,flag;
          exit when month_cursor%notfound;
         --�Ե�ǰ���豸����ÿ���µĽɷѱ���
         
          --���ӷ���
          month_pay:=basicfee*1.08;
          if currenttype = '01' then
            month_pay:=month_pay+basicfee*0.1;
            else
              month_pay:=month_pay+basicfee*0.15;
            end if;
            
          --ΥԼ��
          sysyear:=to_number(to_char(sysdate,'yyyy'));
          sysmonth:=to_number(to_char(sysdate,'mm'));
          recordyear:=to_number(to_char(to_date(recorddate,'yyyymm'),'yyyy'));
          recordmonth:=to_number(to_char(to_date(recorddate,'yyyymm'),'mm'));
          
          if currenttype = '02' then
             if sysyear = recordyear and sysmonth > recordmonth then
               month_pay:= month_pay + round(sysdate - add_months(to_date(recorddate,'yyyymm'),1))*basicfee*0.002;
             elsif sysyear > recordyear then
               --δ���겿�ְ���0.002
               month_pay:= month_pay + round(to_date(1231,'yyyymm') - add_months(to_date(recordmonth,'yyyymm'),1))*basicfee*0.002;
               --���겿�ְ���0.003
               month_pay:= month_pay + round(sysdate - add_months(to_date(recordyear,'yyyy'),12))*basicfee*0.003;
             end if;
          else
            month_pay:=month_pay + round(sysdate - add_months(to_date(recorddate,'yyyymm'),1))*basicfee*0.001;
           end if; 
             
           dbms_output.put_line(month_pay);
           
          --��ǰ��total��������������¼��payfee  
          if month_pay>total then
           update device set device.balance=device.balance+total where device.deviceid = currentid;
           commit;
           update payfee set payfee.type='2001' where payfee.deviceid=currentid;
           commit;
           exit;
           else 
             --�������total�۳�Ӧ�ɷ���
             total:=total-month_pay;
             update receivables set flag=1 where receivables.deviceid = currentid
             and receivables.yearmonth = recorddate;
             commit;
            end if;   

        end loop;
        close month_cursor;
        
        --�������Ǯ����ʣ�ͷŻ����
        if total>0 then
            update device set device.balance=total where device.deviceid = currentid;
            commit;
            update payfee set payfee.type='2001' where payfee.deviceid=currentid;
            commit;
           end if;  

      end loop;
      close id_cursor;
         
end inbank;
/
