create table order_list(
Order_ID varchar(50) primary key,
Order_Date	date,
CustomerName varchar(100),
States	varchar(50),
City varchar(50)
);

create table order_detail(
Order_ID varchar(50),	
Amount	numeric(7,2),
Profit	numeric(7,2),
Quantity	int,
Category	varchar(50),
Sub_Category varchar(50),
constraint fk_order_detail foreign key (order_id) references order_list(order_id)
);

create table sale_target(
Month_of_Order_Date	varchar(50),
Category varchar(50),
Target numeric(7,2)
);

copy order_list from 'D:\(DATA) Data Analysis\E-commerce(list of orders).csv' delimiter ',' csv header;
copy order_detail from 'D:\(DATA) Data Analysis\E-commerce(order details).csv' delimiter ',' csv header;
copy sale_target from 'D:\(DATA) Data Analysis\E-commerce(sale target).csv' delimiter ',' csv header;

select * from order_detail;
select * from order_list;
select * from sale_target;

                     --🔹 Beginner Problems (Querying Basics)

--List all orders placed in January 2019 with customer name, state, and city.

select ol.order_date, ol.customername, ol.states, ol.city
from order_list ol
join order_detail od on ol.order_id=od.order_id
where order_date between '2019-01-01' and '2019-01-31';

--Find the top 10 customers by total purchase amount.

select ol.customername, sum(od.amount)
from order_list ol
join order_detail od on ol.order_id=od.order_id
group by ol.customername
order by sum(od.amount) desc
limit 10;

--Get all orders from "California" where profit was negative.

select ol.city, od.profit
from order_list ol
join order_detail od on od.order_id=ol.order_id
where od.profit <0 
order by od.profit;

--Find the distinct categories and subcategories sold in each state.

select distinct od.category, od.sub_category, ol.states
from order_list ol
join order_detail od on od.order_id=ol.order_id;

--Calculate total quantity sold by each customer.

select ol.customername, sum(od.quantity) as total_quantity
from order_list ol
join order_detail od on ol.order_id=od.order_id
group by ol.customername
order by sum(od.quantity) desc;

                  --🔹 Intermediate Problems (Aggregations & Joins)

--Monthly Sales Report: Show total Amount and Profit grouped by month.

select to_char(ol.order_date, 'Month'), sum(od.amount) as total_amount, sum(od.profit) as total_profit
from order_list ol
join order_detail od on ol.order_id=od.order_id
group by to_char(ol.order_date, 'Month')
order by sum(od.amount), sum(od.profit);

--Category-wise Profitability: Calculate total sales, profit, and average quantity per category.

select category, sum(amount) as total_sales, sum(profit) as total_profit, avg(quantity) as avg_quantity
from order_detail
group by category;

--State Performance: For each state, find the number of unique customers and total sales.

select ol.states, sum(od.amount)as total_sale, count(distinct ol.customername) as unique_customers
from order_list ol
join order_detail od on ol.order_id=od.order_id
group by ol.states
order by sum(od.amount) desc, count(distinct ol.customername) ;

--Most Profitable City: Find the city with the highest total profit.

select ol.city, sum(od.profit) as total_profit
from order_list ol
join order_detail od on ol.order_id=od.order_id
group by city
order by sum(od.profit) desc
limit 1;

--Customer Loyalty: Identify customers who placed more than 5 orders.

select customername, count(order_id)
from order_list
group by customername
having count(order_id) >5;

                     --🔹 Advanced Problems (Targets, KPIs & Business Insights)

--Target Achievement: Compare actual sales with sale_target per category and month. Show whether the target was Achieved or Missed.

select 
st.month_of_order_date,
st.category,
st.target,
sum(od.amount) as actual_sales,
case
when sum(od.amount)>=st.target then 'Achived '
else 'Missed'
end as target_status
from sale_target st
left join order_detail od 
on st.category=od.category
left join order_list ol
on od.order_id=ol.order_id
and to_char(ol.order_date, 'YYYY-MM') = st.Month_of_order_date
group by st.Month_of_order_date, st.category, st.target
order by st.Month_of_order_date, st.category;

--Subcategory Growth: For each subcategory, calculate month-over-month sales growth.

WITH subcat_monthly AS (
    SELECT 
        od.sub_category,
        DATE_TRUNC('month', ol.order_date) AS month,
        SUM(od.amount) AS total_sales
    FROM order_detail od
    JOIN order_list ol ON od.order_id = ol.order_id
    GROUP BY od.sub_category, DATE_TRUNC('month', ol.order_date)
)
SELECT 
    sub_category,
    TO_CHAR(month, 'YYYY-MM') AS month,
    total_sales,
    LAG(total_sales) OVER (PARTITION BY sub_category ORDER BY month) AS prev_month_sales,
    ROUND(
        ( (total_sales::numeric - LAG(total_sales) OVER (PARTITION BY sub_category ORDER BY month)) 
        / NULLIF(LAG(total_sales) OVER (PARTITION BY sub_category ORDER BY month), 0) ) * 100, 2
    ) AS mom_growth_percent
FROM subcat_monthly
ORDER BY sub_category, month;


--Top Product Category in Each Month: Use a window function to get the category with the highest sales per month.

with category_monthly as (
select od.category, 
date_trunc('month', ol.order_date) as months,
sum(od.amount) as total_sales
from order_detail od
join order_list ol on od.order_id=ol.order_id
group by od.category, date_trunc('month', ol.order_date)
),
ranked as (
select category, months , total_sales, 
rank() over (partition by months order by total_sales desc )as sales_rnk
from category_monthly
)
select 
to_char(months, 'YYYY_MM') as months,
category,
total_sales
from ranked
where sales_rnk = 1
order by months;

--Profit Margin Analysis: Calculate profit margin percentage (Profit/Amount * 100) by category.

select amount, profit,
round ((profit/amount)*100, 2) as profit_margin_perc 
from order_detail;


--High vs Low Margin Orders: Classify each order as “High Margin” or “Low Margin” based on whether profit margin is above or below 20%.

select amount, profit, round((profit/amount)*100, 2) as profit_margin_perc,
case
when round((profit/amount)*100, 2) >= 20 then 'High Margin'
when round((profit/amount)*100, 2) <20 and round((profit/amount)*100, 2) >0 then 'Low Margin'
when round((profit/amount)*100, 2) = 0 then 'No Profit No Lose'
else 'We Are Making Lose'
end as Margin_cat
from order_detail;

                          --🔹 Expert-Level Problems (Dashboards & Business Scenarios)

--Customer Segmentation: Classify customers into:
--High Value (> ₹50,000 total sales),
--Medium Value (₹20,000–₹50,000), and
--Low Value (< ₹20,000).

select ol.customername, sum(od.amount) as Total_Sales,
case
when sum(od.amount)> 5000 then 'High Value'
when sum(od.amount)< 5000 and sum(od.amount)> 2000 then 'Medium Value'
else 'Low Value'
end as Customer_Segmentation
from order_detail od
join order_list ol on ol.order_id=od.order_id
group by customername
order by sum(od.amount) desc;

--Sales Forecasting Prep: Create a dataset of monthly category sales that can be used for forecasting.

select date_trunc ('month', ol.order_date) as months,
od.category,
sum(od.amount) as total_sales
from order_detail od
join order_list ol on ol.order_id=od.order_id
group by date_trunc('month', ol.order_date) , od.category
order by months, od.category;

--Sales Contribution: Show which 20% of customers contribute to 80% of revenue (Pareto Principle / 80-20 analysis).

with customer_revenue as (
select ol.customername,
sum(od.amount) as total_revenue
from order_detail od
join order_list ol on ol.order_id=od.order_id
group by ol.customername
),
ranked as (
select
customername,
total_revenue,
rank() over (order by total_revenue desc) as revenue_rank,
sum(total_revenue) over() as overall_revenue,
sum(total_revenue) over (order by total_revenue desc) as  running_revenue
from customer_revenue
)
select 
customername, total_revenue, round((running_revenue/overall_revenue)*100, 2) as cumulative_revenue_percent
from ranked
where (running_revenue/overall_revenue)<=0.80
order by total_revenue desc;

--Churn Risk: Find customers who purchased last year but not in the current year.

with customer_year as (
select customername,
extract(year from order_date) as order_year
from order_list
group by customername, extract(year from order_date)
),
churn_candidates as(
select 
cy.customername,
cy.order_year,
(cy.order_year+1) as next_year
from customer_year cy
)
select 
c.customername,
c.order_year as last_pur_year
from churn_candidates c
left join customer_year cy2
on c.customername=cy2.customername
and c.next_year=cy2.order_year
where cy2.customername is null
order by c.order_year, c.customername;



