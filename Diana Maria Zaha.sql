create database SampleCSV
use SampleCSV


drop table if exists Companies

create table Companies (
	input_row_key int,
	input_company_name varchar(100),
	company_name varchar(255),
	company_legal_names varchar(255),  
	company_commercial_names varchar(255),       
	input_main_country_code varchar(100),
    	input_main_country varchar(100),
	year_founded varchar(100),
	company_type varchar(50),
	veridion_id varchar(255),
   	 match_status varchar(255)
);


bulk insert Companies
from 'C:\temp\Sample_Companies_Final.csv'
with
(
    firstrow = 2,              
    fieldterminator = ',',    
    rowterminator = '\n',     
    codepage = '65001',       
    tablock
);


--curatare tabel:
update Companies

set input_company_name = ltrim(rtrim(lower(
      replace(replace(replace(replace(input_company_name, '.', ''), ',', ''), '(', ''), ')', '')
))),
	company_name = ltrim(rtrim(lower(
      replace(replace(replace(replace(input_company_name, '.', ''), ',', ''), '(', ''), ')', '')
))),
	company_legal_names = ltrim(rtrim(lower(
	 replace(replace(replace(replace(input_company_name, '.', ''), ',', ''), '(', ''), ')', '')
))),
	company_commercial_names = ltrim(rtrim(lower(
	replace(replace(replace(replace(input_company_name, '.', ''), ',', ''), '(', ''), ')', '')
)));


--curatare coloana company name:
update Companies
set company_name = ltrim(rtrim(
	case
	when right(lower(company_name), 2) = 'ag' then left(company_name, len(company_name)-2)
	when right(lower(company_name), 3) = 'inc' then left(company_name, len(company_name)-3)
	when right(lower(company_name), 4) = 'press' then left(company_name, len(company_name)-4)
	when right(lower(company_name), 5) = 'b2452' then left(company_name, len(company_name)-5)
	when right(lower(company_name), 6) = 'nordic' then left(company_name, len(company_name)-6)
	when right(lower(company_name), 7) = 'ireland' then left(company_name, len(company_name)-7)
	when right(lower(company_name), 8) = 'pakistan' then left(company_name, len(company_name)-8)
	when right(lower(company_name), 9) = 'singapore' then left(company_name, len(company_name)-9)
	when right(lower(company_name), 10) = 'bangladesh' then left(company_name, len(company_name)-10)
		else company_name
    end
));




select * from Companies 
order by company_name asc


select * from Companies
where match_status = 'matched'






--gasesc duplicate dupa input(numele companiei)
select input_company_name, count(*)
from Companies
group by input_company_name
having count(*) > 1;

--gasesc duplicate dupa combinatia rowkey si numele companiei
select input_row_key, company_name, count(*) as cnt
from Companies
group by input_row_key, company_name
having count(*) > 1;


--deduplic tabelul
with cte_dedup as (
	select *,
		row_number() over (partition by input_row_key, company_name 
			order by 
				case when match_status = 'matched' then 1 else 2 end,
				input_row_key) as rn
	from Companies
)
delete from cte_Dedup
where rn > 1;


--selectarea unei singure potriviri
with BestMatch as (
	select *,
		row_number() over (partition by input_row_key
		order by	
			case when match_status = 'matched' then 1 else 2 end
	) as rn
	from Companies
)

select * into Companies_Best_Matches
from BestMatch
where rn=1


-- verific daca mai exista duplicate
select input_row_key, count(*) as cnt
from Companies_Best_Matches
group by input_row_key
having count(*) > 1


--verificare potriviri
select match_status, count(*) AS num_results
from Companies_Best_Match
group by match_status;

select * from Companies_Best_Matches 


--tabel doar cu inregistrari matched:
select 
	input_row_key,
	company_name,
	input_main_country_code,
	input_main_country,
	year_founded,
	company_type,
	veridion_id,
	match_status
into Clean_Companies
from Companies_Best_Matches
where match_status = 'matched';

select * from Clean_Companies



