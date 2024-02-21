

-- 1) create temp_sme_pbx_BO for import the data call on pbx to check did they call by IP Phone or not
create table `temp_sme_pbx_BO` (
  `id` int(11) not null auto_increment,
  `customer_tel` varchar(255) default null,
  `pbx_status` varchar(255) default null,
  `date` datetime default null,
  `current_staff` varchar(255) default null,
  `type` varchar(255) default null,
  `month_type` int(11) default null comment '3=3 months or less, 6=6months or less, 9=9months or less, 12=12months or less',
  primary key (`id`)
) engine=innodb auto_increment=1 default charset=utf8mb3 collate=utf8mb3_general_ci;


-- 2) create temp_sme_pbx_SP for import the data call on pbx to check did they call by IP Phone or not
create table `temp_sme_pbx_SP` (
	`id` int(11) not null auto_increment,
	`broker_tel` varchar(255) default null,
	`pbx_status` varchar(255) default null,
	`date` datetime default null,
	primary key (`id`)
)engine=InnoDB auto_increment=1 default CHARSET=utf8mb3 collate=utf8mb3_general_ci;

-- 2.1 update current sales
update temp_sme_pbx_SP ts inner join tabsme_Sales_partner sp on (ts.id = sp.name)
set ts.current_staff = sp.current_staff ;

-- 2.2 insert new record to temp_sme_pbx_SP
insert into temp_sme_pbx_SP 
select sp.name `id`, sp.broker_tel, null `pbx_status`, null `date`, sp.current_staff from tabsme_Sales_partner sp inner join sme_org sme on (sp.current_staff = sme.staff_no)
where name not in (select id from temp_sme_pbx_SP);


-- SABC export the current list 
select * from temp_sme_pbx_BO tspb;

-- SABC Additional list for SABC less or 1 year
select bp.name `id`, bp.customer_tel, null `pbx_status`, null `date`, staff_no `current_staff`, 
	case when bp.rank_update in ('S', 'A', 'B', 'C') then bp.rank_update else bp.rank1 end `type`, 
	case when timestampdiff(month, bp.creation, date(now())) > 36 then 36 else timestampdiff(month, bp.creation, date(now())) end `month_type`,
	case when bp.contract_status = 'Contracted' then 'Contracted' when bp.contract_status = 'Cancelled' then 'Cancelled' else bp.rank_update end `Now Result`
from tabSME_BO_and_Plan bp 
where ( (bp.rank1 in ('S', 'A', 'B', 'C') and date_format(bp.creation, '%Y-%m-%d') between '2024-01-01' and '2024-01-31' and bp.rank_update not in ('FFF') )
	or bp.rank_update in ('S', 'A', 'B', 'C') )
	and bp.contract_status not in ('Contracted', 'Cancelled');

-- _________________________________________________________________ check and update staff no _________________________________________________________________
select * from temp_sme_pbx_BO tspb; -- 422,582

-- check
select bp.staff_no, tb.current_staff  from tabSME_BO_and_Plan bp inner join temp_sme_pbx_BO tb on (tb.id = bp.name)
where bp.staff_no != tb.current_staff;

-- update
update tabSME_BO_and_Plan bp inner join temp_sme_pbx_BO tb on (tb.id = bp.name)
set bp.staff_no = tb.current_staff where tb.`type` = 'F'; -- 369,654

update tabSME_BO_and_Plan bp inner join temp_sme_pbx_BO tb on (tb.id = bp.name)
set tb.current_staff = bp.staff_no where tb.`type` in ('S','A','B','C'); -- 52,928

update tabSME_BO_and_Plan bp inner join tabSME_BO_and_Plan_bk bpk on (bp.name = bpk.name)
set bp.staff_no = bpk.staff_no where bp.name in (select id from temp_sme_pbx_BO );

-- check
select * from temp_sme_pbx_SP ; -- 43,283

select sp.name, sp.current_staff, ts.current_staff from tabsme_Sales_partner sp inner join temp_sme_pbx_SP ts on (ts.id = sp.name)
where sp.current_staff != ts.current_staff ;

-- update 
update tabsme_Sales_partner sp inner join temp_sme_pbx_SP ts on (ts.id = sp.name)
set ts.current_staff = sp.current_staff;

-- export to check pbx SP
select sp.name `id`, sp.broker_tel, null `pbx_status`, null `date`, sp.current_staff
from tabsme_Sales_partner sp left join sme_org sme on (case when locate(' ', sp.current_staff) = 0 then sp.current_staff else left(sp.current_staff, locate(' ', sp.current_staff)-1) end = sme.staff_no)
inner join temp_sme_pbx_SP ts on (ts.id = sp.name)
where sp.refer_type = 'LMS_Broker' -- SP
	or (sp.refer_type = 'tabSME_BO_and_Plan' and sme.`unit_no` is not null) -- XYZ
	or (sp.refer_type = '5way' and sp.owner_staff = sp.current_staff and sme.`unit_no` is not null) -- 5way
order by sme.id ;














