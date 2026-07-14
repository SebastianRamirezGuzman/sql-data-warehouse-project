create view gold.report_products as 
/*--------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
--------------------------------------------------------------------------*/
with base_query as(
select 
f.order_number,
f.customer_key,
f.order_date,
f.sales_amount,
f.quantity,
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost
from gold.fact_sales f 
left join gold.dim_products p 
on f.product_key=p.product_key
where f.order_number is not null
), 
/*--------------------------------------------------------------------------
2) customer aggregations: Summarizes key metrics at the customer level
--------------------------------------------------------------------------*/
product_aggregation as (
select  
product_key,
product_name,
category,
subcategory,
cost,
datediff(MONTH, min(order_date), max(order_date)) as lifespan,
max(order_date) as last_sale_date, 
count(distinct order_number) as total_orders,
sum(sales_amount) as total_sales, 
sum(quantity) as total_quantity, 
count(distinct customer_key) as total_customers,
round(avg(cast(sales_amount as float) / nullif(quantity,0)),1) as avg_selling_price
from base_query
group by 
		product_key,
		product_name,
		category,
		subcategory,
		cost
) 
/*--------------------------------------------------------------------------
3) Final Query: Combines all product results into one output 
--------------------------------------------------------------------------*/
select 
product_key,
product_name,
category,
subcategory, 
cost, 
datediff(month, last_sale_date, getdate()) as recency_in_months,
Case 
	when total_sales > 5000 then 'High-performer'
	when total_sales >= 1000 then 'Mid-performer'
	else 'Low_performer'
	end as product_segmenter,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers, 
	avg_selling_price,
	-- Compuate average order revenue (aor)
	case when total_orders = 0 then 0
	else total_sales / total_orders 
	end as avg_order_revenue,
	-- compuate average monthly revenue
	case when lifespan = 0 then 0
	else total_sales / lifespan
	end as avg_monthly_revenue 

from product_aggregation 
