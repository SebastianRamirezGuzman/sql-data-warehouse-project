
-- Change over time 
select 
Year(order_date) as order_year,
month(order_date) as order_month,
sum(sales_amount) as total_Sales,
count(distinct customer_key) as total_costumers,
sum(quantity) as quantity
from gold.fact_sales
where order_date is not null
group by year(order_date), month(order_date)
order by year(order_date), month(order_date)

-- Cumulative analysis 
-- Calculate the total sales per month
select
order_date,
total_sales,
sum(total_sales) over (order by order_date) as running_total_Sales
from
(
select 
cast(FORMAT(order_date, 'yyyy-MM') as varchar(7)) as order_date,
sum(sales_amount) as total_sales
from gold.fact_sales
where order_date is not null
group by FORMAT(order_date, 'yyyy-MM')
) t

-- sales over the year
select
year(order_date),
total_sales,
sum(total_sales) over (order by order_date) as running_total_Sales,
avg(avg_price) over (order by order_date) as moving_average_price
from
(
select 
year(order_date) as order_date,
sum(sales_amount) as total_sales,
avg(price) as avg_price
from gold.fact_sales
where order_date is not null
group by year(order_date)
) t



-- Analyze the yearly performance of products by comparing their sales
-- to both the average sales performance of the products and the previous year's sales
with yearly_product_sales as (
select 
year(f.order_date) as order_year,
p.product_name,
sum(f.sales_amount) as current_sales
from gold.fact_sales f 
left join gold.dim_products p 
on f.product_key = p.product_key
where order_date is not null
group by year(f.order_date), p.product_name
)

select 
order_year,
product_name,
current_sales,
avg(current_sales) over (partition by product_name) avg_sales,
current_sales - avg(current_sales) over (partition by product_name) as diff_avg,
case when current_sales - avg(current_sales) over (partition by product_name) > 0 then 'above avg' 
	 when current_sales - avg(current_sales) over (partition by product_name) < 0 then 'below avg'
	 else 'avg'
end avg_change,
-- year over year analysis -- 
lag(current_sales) over (partition by product_name order by order_year) as py_sales, 
current_sales - lag(current_sales) over (partition by product_name order by order_year) as diff_py,
case when current_sales - lag(current_sales) over (partition by product_name order by order_year) > 0 then 'increase' 
	 when current_sales - lag(current_sales) over (partition by product_name order by order_year) < 0 then 'decrease'
	 else 'no change'
end py_change
from yearly_product_sales
order by product_name, order_year


-- which categories contribute the most to overall sales? 
with category_sales as (
select 
category, 
sum(sales_amount) total_Sales
from gold.fact_sales f 
left join gold.dim_products p 
on p.product_key = f.product_key 
group by category)

select 
category,
total_sales, 
sum(total_Sales) over () overall_sales,
concat(round((cast(total_sales as float) / sum(total_Sales) over())*100,2), '%') as percentage_of_total 
from category_sales
order by total_Sales desc 


/* segment products into cost ranges and 
count how many products fall into each segment*/

with product_segments as (
select 
product_key,
product_name, 
cost,
case when cost < 100 then 'below 100'
	 when cost between 100 and 500 then '100-500'
	 when cost between 500 and 1000 then '500-1000'
	 else 'above 1000'
end cost_range 
from gold.dim_products) 

select
cost_range,
count(product_key) as total_products
from product_segments
group by cost_range
order by total_products desc

/* Group customers into three segments based on their spending behavior: 
	- VIP: Customers with at least 12 months of history and spending more than $5000
	- Regular: Customers with at least 12 months of history but spending $5,000 or less.
	- New: Customers with a lifespan less than 12 months.

And find the total number of customers by each group.
*/
with costumers_spending as (
select 
c.customer_key,
sum(f.sales_amount) as total_spending, 
min(order_date) as first_order, 
max(order_date) as last_order,
DATEDIFF(month, min(order_date), max(order_date)) as lifespan
from gold.fact_sales f 
left join gold.dim_customers c
on f.customer_key=c.customer_key
group by c.customer_key
)

select 
customers_segment, 
count(customer_key) as total_customers
from (
	select 
	customer_key,
	case when lifespan >= 12 and total_spending > 5000 then 'VIP'
		 when lifespan >= 12 and total_spending <= 5000 then 'Regular'
		 else 'New'
	end customers_segment
	from costumers_spending) t 
group by customers_segment
order by total_customers desc
