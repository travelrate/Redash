SELECT date, revenue,
       SUM(revenue) OVER(ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as total_revenue,
       ROUND(((revenue-lag)/lag::DECIMAL)*100, 2) as revenue_change
FROM
(SELECT creation_time::DATE as date, COUNT(order_id) as orders, SUM(price) as revenue, LAG(SUM(price),1) OVER() as lag
 FROM
 (SELECT creation_time, order_id, UNNEST(product_ids) as product_id
  FROM orders) ids
 JOIN
 (SELECT product_id, price
  FROM products) price
 USING(product_id)
 WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
 GROUP BY date) unions