-- creating the database and uploading tables
create database salesflexo character set utf16;
-- working on the sales table
use salesflexo;

-- A. data cleaning 
-- 1.modify name of columns
alter table  sales 
rename column `ï»¿Date` to `Date`;

alter table  collection 
rename column `ï»¿Invoice No.` to `Invoice No`;

-- 2.duplicate rows
SELECT `Invoice No.`, COUNT(`Invoice No.`) as Count
FROM sales
GROUP BY `Invoice No.`
Having COUNT(`Invoice No.`) > 1;
-- we already have duplicate values as this data are transaction date not database and regarding
-- invoice no. is can be used as a unique key but each invoice can iclude more than one order which it entered in seperate row

-- 3. seaech for null values
SELECT * FROM sales
WHERE Brand IS NULL
or 
`Item Category` IS NULL
or 
`Item Group` IS NULL
or 
`Sub Item Group` IS NULL
or 
Thickness IS NULL
or 
Size IS NULL;

-- 3. Deal with price that include currency
-- FIRST DELETE CURRENCY, SPACES
update sales
SET 
`Value Without Vat`= REPLACE(REPLACE(REPLACE(`Value Without Vat`, 'EGP', ''), ',', ''), ' ', ''),
`Vat 14%`= REPLACE(REPLACE(REPLACE(`Vat 14%`, 'EGP', ''), ',', ''), ' ', ''),
`Total Value`= REPLACE(REPLACE(REPLACE(`Total Value`, 'EGP', ''), ',', ''), ' ', ''),
`Total Cost` = REPLACE(REPLACE(REPLACE(`Total cost`, 'EGP', ''), ',', ''), ' ', ''),
`Cost per Box` = REPLACE(REPLACE(REPLACE(`Cost per Box`, 'EGP', ''), ',', ''), ' ', '');

ALTER TABLE sales 
MODIFY COLUMN `Value Without Vat` DECIMAL(10,2),
MODIFY COLUMN `Vat 14%` DECIMAL(10,2),
MODIFY COLUMN `Total Value` DECIMAL(10,2),
MODIFY COLUMN `Total Cost` DECIMAL(10,2);

-- B.Data exploration
-- 1.calcuate measures for sales table
select sum(`Value Without Vat`) as total_Profit
from sales;
-- total profit = 63266889.00
select sum(`Total Value`) as total_sales
from sales;
-- total_sales = 72124255.00
select sum(`Total cost`) as total_cost
from sales;
-- total_cost = 53425123.00
select avg(Margin) as Margin
from sales;
-- Margin = 16.03%

-- 2.calculate top customers consumption in qty
select `Customer Name`, sum(`QTY/Box`) as total_qty
from sales
group by `Customer Name`
order by total_qty desc
limit 10;
-- the biggest client is Kortuba with 210 boxes

-- working on the collection table
-- A. data cleaning 
-- 1. Deal with price that include currency
-- FIRST DELETE CURRENCY, SPACES
update collection
SET 
`Collection Value`= REPLACE(REPLACE(REPLACE(`Collection Value`, 'EGP', ''), ',', ''), ' ', '');

-- 2.calculate top sales representative commission
select `Sales Rep`, sum(`Sales Commission Value`) as com_value
from collection
group by `Sales Rep`
order by com_value desc;
-- the biggest commission value is 20050 for Islam fawzy

-- collecting the open invoices
select `Collection Status`, `Customer Name`,
sum(`Collection Value`) as `collected value`
from collection
where `Collection Status` = 'Collected'
group by `Customer Name`, `Collection Status` 
order by `collected value` desc
limit 10;

-- linking between sales and collection table
select
s.`Invoice No.`,
s. `Customer Name`,
s. Brand,
s. `Item Name`,
s. `Total Value`as `sales value`,
s. Margin,
s. `Shipment Lead Time`,
c. `Collection Type`,
c. `Agreed Collection Date`,
c. `Actual Collection Date`,
c. `Collection Delay`,
c. `Collection Status`,
c. `Sales Rep`,
c. `Sales Commission Value`
from sales s
left join collection c on s.`Invoice No.` = c.`Invoice No`;

-- linking stock lead time with collection delay for each brand
select 
s. Brand,
s. Thickness,
s. `Customer Name`,
-- to get avg of shipment lead time
avg(s. `Shipment Lead Time`) as avg_days_stock,
-- to get avg of collection delay
avg(c. `Collection Delay`) as avg_collection_delay,
-- getting total sales value
sum(s. `Value Without Vat`) as total_value
from sales s
left join collection c on s.`Invoice No.` = c.`Invoice No`
group by s. brand, s. `Customer Name`, s. Thickness
order by avg_collection_delay desc, avg_days_stock desc;

