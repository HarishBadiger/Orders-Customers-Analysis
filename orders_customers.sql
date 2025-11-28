select * from customers;
select * from orders;

/* Q1. How many customers are registered in the system? */
select count(distinct customer_id) as total_customers from customers;

/* Q2. How many total orders were placed? */
select count(distinct order_id) as total_orders from orders;

/* Q3. List all distinct cities where customers come from. */
select distinct city from customers;

/* Q4. Count how many orders fall in each order status (Completed / Cancelled / Returned). */
select order_status, count(*) as cnt
from orders
group by order_status;

/* Q5. Find customers who have placed at least 1 order.*/
select o.customer_id, count(distinct o.order_id) as cnt
from orders o left join customers c
on o.customer_id = c.customer_id
group by o.customer_id
having count(distinct o.order_id)>=1
order by cnt asc;

/* Q6. How many orders did each customer place? (Top 10 customers) */
select top 10 o.customer_id, count(distinct o.order_id) as cnt
from orders o left join customers c
on o.customer_id = c.customer_id
group by o.customer_id
order by cnt desc

/* Q7. List customers who never placed an order. */
select c.customer_id, c.customer_name
from customers c left join orders o 
on c.customer_id = o.customer_id
where o.order_id is null;

/* Q8. For each city, how many customers have placed at least one completed order? */
with cte as (
select c.city, c.customer_id, count(o.customer_id) as no_of_customers
from orders o left join customers c
on o.customer_id = c.customer_id
where o.order_status = 'Completed'
group by c.city, c.customer_id
having count(o.customer_id) >= 1)
select count(*) as no_of_customers from cte ;

/* Q9. Calculate the total revenue from Completed orders. */
select sum(amount) as Total_Revenue from orders
where order_status = 'Completed';

/* Q10. What is the total revenue per city?*/
select c.city, sum(o.amount) as Total_Revenue
from orders o left join customers c
on o.customer_id = c.customer_id
group by c.city;

/* Q11. Identify top 5 highest revenue customers. */
with cte as (
select c.customer_id, sum(o.amount) as Revenue
from orders o left join customers c
on o.customer_id = c.customer_id
group by c.customer_id)
,cte2 as (
select *, dense_rank()over(order by Revenue desc) as rnk
from cte)
select * from cte2 where rnk <=5;

/* Q12. Find monthly sales (YYYY-MM) for 2024 and show top 3 months by sales. */
select top 3 format(order_date, 'yyyy-MM') as order_yr_month, sum(amount) as revenue
from orders
where year(order_date)=2024
group by format(order_date, 'yyyy-MM')
order by revenue desc;

/* Q13. Calculate year-over-year growth (if data contains multiple years). */
with cte as (
select year(order_date) as Order_Year, sum(amount) as Revenue
from orders
group by year(order_date))
,cte2 as (
select *, lag(Revenue,1)over(order by Order_Year asc) as prev_year_revenue
from cte)
select Order_Year,Revenue,prev_year_revenue
,concat(coalesce(cast((Revenue-prev_year_revenue)*100.0/prev_year_revenue as decimal(10,2)),0),'%') as Percentage_growth
from cte2;

/* Q14. Find the average time between customer signup and their first order. */
with cte as(
select o.customer_id,o.order_id,c.signup_date,o.order_date
from orders o left join customers c
on o.customer_id = c.customer_id)
,first_order_per_customer as (
select customer_id,signup_date, min(order_date) as First_Order_date
from cte
group by customer_id,signup_date)
select avg(datediff(day,signup_date,First_Order_date)) as Avg_Time
from first_order_per_customer;

/* Q15. What percentage of customers placed more than 3 orders? */
with cte as 
(select o.customer_id, count(distinct o.order_id) as cnt_of_orders
from orders o left join customers c
on o.customer_id = c.customer_id
group by o.customer_id
having count(distinct o.order_id) = 3)
select concat(cast(count(*)*100.0/(select count(customer_id) from customers) as decimal(10,2)),'%') as Percentage_of_customers
from cte;

/* Q16. Identify churned customers (no orders in last 3 months). */
with cutoff as (
select dateadd(month,-3,max(order_date)) as cutoff_date from orders)
select c.customer_id
from customers c 
cross join cutoff
left join orders o
on c.customer_id = o.customer_id
and o.order_date >= cutoff.cutoff_date
where o.order_id is NULL;

/* Q17. Rank customers by total spending. */
with cte as (
select customer_id,sum(amount) as total_spending
from orders
group by customer_id)
,cte2 as (
select *, DENSE_RANK()over(order by total_spending desc) as rnk
from cte)
select * from cte2 where rnk<=5;

/* Q18. For each city, find the top 3 spending customers. */

with cte as (
select c.city,o.customer_id,sum(o.amount) as total_spending
from orders o left join customers c
on c.customer_id = o.customer_id
group by c.city,o.customer_id)
,cte2 as (
select *, DENSE_RANK()over(partition by city order by total_spending desc) as rnk
from cte)
select * from cte2 where rnk<=3;

/* Q19. Find running total revenue by order date.*/
select order_date,amount
,sum(amount)over(order by order_date rows between unbounded preceding and current row ) as running_total
from orders;