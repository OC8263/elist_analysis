-- What were the order counts, sales, and AOV for Macbooks sold in North America for each quarter across all years?

SELECT DATE_TRUNC(a.purchase_ts, quarter) AS purchase_quarter,
  COUNT(DISTINCT a.id) AS order_count,
  ROUND(SUM(a.usd_price),2) AS total_sales,
  ROUND(AVG(a.usd_price),2) AS aov
FROM core.orders a
LEFT JOIN core.customers b
  ON a.customer_id = b.id
LEFT JOIN core.geo_lookup c
  ON b.country_code = c.country_code
WHERE lower(a.product_name) LIKE '%macbook%'
  AND region = 'NA'
GROUP BY 1
ORDER BY 1 DESC;


--For products purchased in 2022 on the website or products purchased on mobile in any year, which region has the average highest time to deliver?

SELECT d.region, 
  ROUND(AVG(DATE_DIFF(a.delivery_ts, a.purchase_ts, day)),1) AS time_to_deliver
FROM core.order_status a
LEFT JOIN core.orders b
  ON a.order_id = b.id
LEFT JOIN core.customers c
  ON c.id = b.customer_id
LEFT JOIN core.geo_lookup d
  ON d.country_code = c.country_code
WHERE (extract(year from b.purchase_ts) = 2022 and b.purchase_platform = 'website')
  OR purchase_platform = 'mobile app'
GROUP BY 1
ORDER BY 2 DESC;



--What was the refund rate and refund count for each product overall?

SELECT case when a.product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' ELSE a.product_name END AS product_clean,
    SUM(CASE WHEN b.refund_ts is not null THEN 1 ELSE 0 END) AS refunds,
    AVG(CASE WHEN b.refund_ts is not null THEN 1 ELSE 0 END) AS refund_rate
FROM core.orders a
JOIN core.order_status b
ON a.id = b.order_id
GROUP BY 1
ORDER BY 1;


--Within each region, what is the most popular product?

WITH order_count_cte AS (
SELECT c.region, 
  CASE WHEN a.product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' ELSE a.product_name END AS product_clean,
  COUNT(DISTINCT a.id) AS order_count
FROM core.orders a
JOIN core.customers b
ON a.customer_id = b.id
JOIN core.geo_lookup c
ON b.country_code = c.country_code
GROUP BY 1,2),

ranking_cte as(
SELECT *,
 ROW_NUMBER() OVER(PARTITION BY region ORDER BY order_count DESC) AS ranking
FROM order_count_CTE)

SELECT *
FROM ranking_cte 
WHERE ranking = 1;

--OR--

WITH order_count_CTE AS (
SELECT c.region, 
  CASE WHEN a.product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' ELSE a.product_name END AS product_clean,
  COUNT(DISTINCT a.id) AS order_count
FROM core.orders a
JOIN core.customers b
ON a.customer_id = b.id
JOIN core.geo_lookup c
ON b.country_code = c.country_code
GROUP BY 1,2)
SELECT *,
 ROW_NUMBER() OVER(PARTITION BY region ORDER BY order_count DESC) AS ranking
FROM order_count_CTE
QUALIFY ROW_NUMBER() OVER(PARTITION BY region ORDER BY order_count DESC) = 1;



--How does the time to make a purchase differ between loyalty customers vs. non-loyalty customers?

SELECT a.loyalty_program,
  round(avg(date_diff(b.purchase_ts,a.created_on, day)),1) as time_to_purchase_days,
  round(avg(date_diff(b.purchase_ts,a.created_on, month)),1) as time_to_purchase_months
FROM core.customers a
JOIN core.orders b
ON a.id = b.customer_id
JOIN core.order_status c
ON c.order_id = b.id
GROUP BY 1;
GROUP BY 1;
