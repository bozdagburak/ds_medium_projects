
UPDATE [dbo].[prod_dimen]
SET Prod_id='Prod_16'
WHERE Prod_id=' RULERS AND TRIMMERS,Prod_16'

SELECT * FROM dbo.prod_dimen

/*
Join all tables and create a new table with all of the columns, called
combined_table. (market_fact, cust_dimen, orders_dimen, prod_dimen,
shipping_dimen)
*/

SELECT 
C.[Cust_id],C.[Customer_Name],C.[Province],C.[Region],C.[Customer_Segment],
M.[Ord_id],M.[Prod_id],M.[Sales],M.[Discount],M.[Order_Quantity],M.[Profit],
M.[Shipping_Cost],M.[Product_Base_Margin],O.[Order_Date],O.[Order_Priority],
P.[Product_Category],P.[Product_Sub_Category],S.[Ship_id],
S.[Ship_Mode],S.[Ship_Date]
INTO combined_table
FROM market_fact M
inner join
cust_dimen C ON M.Cust_id=C.Cust_id
inner join
orders_dimen O ON M.Ord_id=O.Ord_id
inner join
prod_dimen P on M.Prod_id=P.Prod_id
inner join
shipping_dimen S ON M.Ship_id=S.Ship_id

--Find the top 3 customers who have the maximum count of orders

SELECT TOP 3 Cust_id, Customer_Name, COUNT(DISTINCT Ord_id) num_ord
FROM
combined_table
GROUP BY
Cust_id, Customer_Name
ORDER BY
num_ord DESC

/*Create a new column at combined_table as DaysTakenForDelivery that
contains the date difference of Order_Date and Ship_Date.*/

ALTER TABLE combined_table
ADD DaysTakenForDelivery AS DATEDIFF(DAY,Order_Date,Ship_Date)

select * from combined_table

--Find the customer whose order took the maximum time to get delivered.

SELECT TOP 1 [Cust_id],[Customer_Name],DaysTakenForDelivery
FROM combined_table
ORDER BY 3 DESC

--Retrieve total sales made by each product from the data (Window function)

SELECT DISTINCT Prod_id, SUM(Sales) OVER (PARTITION BY Prod_id) total_sales
FROM
combined_table
ORDER BY Prod_id

--Retrieve total profit made from each product from the data (Window function)

SELECT DISTINCT Prod_id, SUM(Profit) OVER (PARTITION BY Prod_id) total_profit
from combined_table

/*Count the total number of unique customers in January and how many of them
came back every month over the entire year in 2011
*/

SELECT
Year(Order_Date) year, 
Month(Order_Date) AS month, 
count(distinct cust_id) 
FROM combined_table 
WHERE year(Order_Date)=2011 
AND cust_id IN 
			(
			SELECT DISTINCT cust_id 
			FROM combined_table 
			WHERE year(Order_Date) = 2011 AND month(Order_Date) = 01
			)
GROUP BY
Year(Order_Date),
Month(Order_Date)
ORDER BY
Month(Order_Date)

/* Find month-by-month customer retention rate since the start of the business
*/

/*Create a view where each user’s visits are logged by month, allowing for the
possibility that these will have occurred over multiple years since whenever
business started operations.
*/

create view user_visit as
select cust_id, Count_in_month, convert (date , month + '-01') Month_date
from
(
select Cust_id, SUBSTRING(cast(order_date as varchar), 1,7) as [Month], count(*) count_in_month
from combined_table
group by Cust_id, SUBSTRING(cast(order_date as varchar), 1,7)
) a

select *
from user_visit ;

--Identify the time lapse between each visit. So, for each person and for each month, we see when the next visit is


create view Time_lapse_vw as 
select  *, lead(Month_date) over (partition by cust_id order by Month_date) as Next_month_Visit
from user_visit; 


select * from time_lapse_vw;

--Calculate the time gaps between visits.

create view  time_gap_vw as 
select *, datediff ( month, Month_date, Next_month_Visit) as Time_gap 
from time_lapse_vw;

select * from time_gap_vw

--Categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned.

create view Customer_value_vw as 

select distinct cust_id, Average_time_gap,
case 
	when Average_time_gap<=1 then 'Retained'
    when Average_time_gap>1 then 'Irregular'
    when Average_time_gap is null then 'Churned'
    else 'Unknown data'
end  as  Customer_Value
from 
(
select cust_id, avg([Time_gap]) over(partition by cust_id) as Average_time_gap
from 
[dbo].[time_gap_vw]
) t;


select * from customer_value_vw;



select * from time_gap_vw
where
cust_id='Cust_1288';


select * from time_gap_vw


--Calculate the retention month wise.

create view retention_vw as 

select distinct next_month_visit as Retention_month,

sum(time_gap) over (partition by next_month_visit) as Retention_Sum_monthly

from time_gap_vw 
where time_gap<=1
--order by Retention_Sum_monthly desc;


select * from retention_vw;
