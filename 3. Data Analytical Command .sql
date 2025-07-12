-- 1. Total gross revenue
SELECT SUM(quantity * unit_price) AS total_gross_revenue FROM fact_transaction;

-- 2. Total net revenue (after discount)
SELECT SUM(quantity * unit_price * (1 - discount_percent)) AS total_net_revenue FROM fact_transaction;

-- 3. Total profit
SELECT SUM((unit_price * (1 - discount_percent) - unit_manufacturing_cost) * quantity) AS total_profit FROM fact_transaction;

-- 4. Orders placed by each customer segment
SELECT customer_segment, COUNT(DISTINCT order_id) AS orders_count FROM fact_transaction GROUP BY customer_segment;

-- 5. Top 5 best-selling products by quantity
SELECT dp.product_name, SUM(ft.quantity) AS total_quantity
FROM fact_transaction ft
JOIN dim_product dp ON ft.product_id = dp.product_id
GROUP BY dp.product_name
ORDER BY total_quantity DESC
LIMIT 5;

-- 6. Monthly gross revenue trend for 2015
SELECT MONTH(order_date) AS month, SUM(quantity * unit_price) AS monthly_gross_revenue
FROM fact_transaction
WHERE YEAR(order_date) = 2015
GROUP BY MONTH(order_date)
ORDER BY month;

-- 7. Sub-category with highest profit margin
SELECT dsc.sub_category_name,
       (SUM((ft.unit_price * (1 - ft.discount_percent) - ft.unit_manufacturing_cost) * ft.quantity) /
        SUM(ft.unit_price * ft.quantity)) * 100 AS profit_margin
FROM fact_transaction ft
JOIN dim_product dp ON ft.product_id = dp.product_id
JOIN dim_sub_category dsc ON dp.sub_category_id = dsc.sub_category_id
GROUP BY dsc.sub_category_name
ORDER BY profit_margin DESC
LIMIT 1;

-- 8. Continents with highest return percentage
WITH returned_orders AS (
  SELECT DISTINCT order_id FROM return_table WHERE returned = 'Yes'
),
continent_orders AS (
  SELECT ft.order_id, dl.continent
  FROM fact_transaction ft
  JOIN dim_location dl ON ft.location_id = dl.location_id
)
SELECT continent,
       COUNT(ro.order_id) / COUNT(co.order_id) * 100 AS return_percentage
FROM continent_orders co
LEFT JOIN returned_orders ro ON co.order_id = ro.order_id
GROUP BY continent
ORDER BY return_percentage DESC;

-- 9. Products with negative profit
SELECT dp.product_name,
       SUM((unit_price * (1 - discount_percent) - unit_manufacturing_cost) * quantity) AS profit
FROM fact_transaction ft
JOIN dim_product dp ON ft.product_id = dp.product_id
GROUP BY dp.product_name
HAVING profit < 0;

-- 10. Discount percentage correlation with order volume
SELECT discount_percent, COUNT(DISTINCT order_id) AS order_volume
FROM fact_transaction
GROUP BY discount_percent
ORDER BY discount_percent;

-- 11. Return rate by product category
WITH returned_orders AS (
  SELECT DISTINCT order_id FROM return_table WHERE returned = 'Yes'
),
category_orders AS (
  SELECT ft.order_id, dc.category_name
  FROM fact_transaction ft
  JOIN dim_product dp ON ft.product_id = dp.product_id
  JOIN dim_sub_category dsc ON dp.sub_category_id = dsc.sub_category_id
  JOIN dim_category dc ON dsc.category_id = dc.category_id
)
SELECT category_name,
       COUNT(ro.order_id) / COUNT(co.order_id) * 100 AS return_rate
FROM category_orders co
LEFT JOIN returned_orders ro ON co.order_id = ro.order_id
GROUP BY category_name
ORDER BY return_rate DESC;

-- 12. Most profitable shipping mode
SELECT ship_mode,
       SUM((unit_price * (1 - discount_percent) - unit_manufacturing_cost) * quantity) AS total_profit
FROM fact_transaction
GROUP BY ship_mode
ORDER BY total_profit DESC
LIMIT 1;

-- 13. Percentage of high priority orders
SELECT COUNT(CASE WHEN order_priority = 'High' THEN 1 END) / COUNT(*) * 100 AS high_priority_percentage
FROM fact_transaction;

-- 14. City with highest revenue per order
SELECT dl.city,
       SUM(ft.unit_price * ft.quantity) / COUNT(DISTINCT ft.order_id) AS revenue_per_order
FROM fact_transaction ft
JOIN dim_location dl ON ft.location_id = dl.location_id
GROUP BY dl.city
ORDER BY revenue_per_order DESC
LIMIT 1;

-- 15. Average profit per customer segment
WITH profit_per_order AS (
  SELECT order_id, customer_segment,
         SUM((unit_price * (1 - discount_percent) - unit_manufacturing_cost) * quantity) AS profit
  FROM fact_transaction
  GROUP BY order_id, customer_segment
)
SELECT customer_segment, AVG(profit) AS avg_profit
FROM profit_per_order
GROUP BY customer_segment;

-- 16. Year-over-year revenue growth by category
WITH revenue_by_year AS (
  SELECT dc.category_name, YEAR(order_date) AS year,
         SUM(unit_price * quantity * (1 - discount_percent)) AS revenue
  FROM fact_transaction ft
  JOIN dim_product dp ON ft.product_id = dp.product_id
  JOIN dim_sub_category dsc ON dp.sub_category_id = dsc.sub_category_id
  JOIN dim_category dc ON dsc.category_id = dc.category_id
  GROUP BY dc.category_name, year
),
lagged_revenue AS (
  SELECT *,
         LAG(revenue) OVER (PARTITION BY category_name ORDER BY year) AS prev_year_revenue
  FROM revenue_by_year
)
SELECT category_name, year, revenue, prev_year_revenue,
       ((revenue - prev_year_revenue) / prev_year_revenue) * 100 AS yoy_growth
FROM lagged_revenue
WHERE prev_year_revenue IS NOT NULL;

-- 17. Frequently purchased together products
SELECT p1.product_name AS product1, p2.product_name AS product2, COUNT(*) AS times_bought_together
FROM fact_transaction t1
JOIN fact_transaction t2 ON t1.order_id = t2.order_id AND t1.product_id < t2.product_id
JOIN dim_product p1 ON t1.product_id = p1.product_id
JOIN dim_product p2 ON t2.product_id = p2.product_id
GROUP BY p1.product_name, p2.product_name
ORDER BY times_bought_together DESC
LIMIT 10;

-- 18. Percentage of multi-product orders
WITH product_count AS (
  SELECT order_id, COUNT(DISTINCT product_id) AS products
  FROM fact_transaction
  GROUP BY order_id
)
SELECT COUNT(CASE WHEN products > 1 THEN 1 END) / COUNT(*) * 100 AS multi_product_order_percentage
FROM product_count;

-- 19. Orders with abnormally high shipping costs (>3 std deviations)
WITH shipping_costs AS (
  SELECT order_id, SUM(unit_shipping_cost * quantity) AS shipping_cost
  FROM fact_transaction
  GROUP BY order_id
),
stats AS (
  SELECT AVG(shipping_cost) AS avg_cost, STDDEV(shipping_cost) AS std_dev
  FROM shipping_costs
)
SELECT s.order_id, s.shipping_cost
FROM shipping_costs s, stats
WHERE s.shipping_cost > stats.avg_cost + 3 * stats.std_dev;

-- 20. Order value segmentation (Low <100, Medium 100-1000, High >1000)
WITH order_value AS (
  SELECT order_id, SUM(quantity * unit_price * (1 - discount_percent)) AS value
  FROM fact_transaction
  GROUP BY order_id
)
SELECT
  CASE
    WHEN value < 100 THEN 'Low'
    WHEN value BETWEEN 100 AND 1000 THEN 'Medium'
    ELSE 'High'
  END AS value_segment,
  COUNT(*) AS order_count
FROM order_value
GROUP BY value_segment;
