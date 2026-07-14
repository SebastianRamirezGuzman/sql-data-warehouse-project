Create view gold.report_customers as 
with base_query as (
/*--------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
--------------------------------------------------------------------------*/
select 
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number, 
CONCAT(c.first_name, ' ', c.last_name) as customer_name,
c.brithdate,
datediff(year, c.brithdate, getdate()) as age 
from gold.fact_sales f
left join gold.dim_customers c
on c.customer_key=f.customer_key
where order_date is not null 
),

/*--------------------------------------------------------------------------
2) customer aggregations: Summarizes key metrics at the customer level
--------------------------------------------------------------------------*/
customer_aggregation as (
select 
customer_key,
customer_number,
customer_name,
age,
count(distinct order_number) as total_orders,
sum(sales_amount) as total_sales, 
sum(quantity) as total_quantity,
count(distinct product_key) as total_products,
max(order_date) as last_order_date,
DATEDIFF(month, min(order_date), max(order_date)) as lifespan
from base_query
group by 
		customer_key,
		customer_number,
		customer_name,
		age
) 
Select 
	customer_key,
	customer_number,
	customer_name,
	age,
	case when age < 20 then 'Under 20'
		 when age between 20 and 29 then '20-29'
		 when age between 20 and 29 then '30-39'
		 when age between 20 and 29 then '40-49'
	else '50 and above'
	end as age_group,
		case when lifespan >= 12 and total_sales > 5000 then 'VIP'
		 when lifespan >= 12 and total_sales <= 5000 then 'Regular'
		 else 'New'
	end customers_segment,
	last_order_date,
	datediff(month, last_order_date, getdate()) as recency,
	total_orders, 
	total_sales,
	total_quantity, 
	total_products,
	lifespan,
	-- Compuate average order value (avo)
	case when total_orders = 0 then 0 
		 else total_sales / total_orders
	end as avg_order_value,
	-- compuate average monthly spend 
	case when lifespan = 0 then total_sales
		else total_sales / lifespan
	end as avg_monthly_spend
	from customer_aggregation
