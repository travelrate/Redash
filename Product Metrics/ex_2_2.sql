WITH order_price AS
(SELECT date, SUM(price) as revenue
 FROM
 (SELECT order_id, creation_time::DATE as date, UNNEST(product_ids) as product_id
  FROM orders) ids
 JOIN
 (SELECT price, product_id
  FROM products) price
 USING(product_id)
WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
GROUP BY date
ORDER BY date)

SELECT date, 
       ROUND(revenue/users::DECIMAL, 2) as arpu,
       ROUND(revenue/paying_users::DECIMAL, 2) as arppu,
       ROUND(revenue/orders::DECIMAL, 2) as aov
FROM
(SELECT time::DATE as date, COUNT(DISTINCT user_id) as paying_users, COUNT(order_id) as orders
 FROM user_actions
 WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
 GROUP BY date) users
JOIN order_price
USING(date)
JOIN 
(SELECT time::DATE as date, COUNT(DISTINCT user_id) as users
 FROM user_actions
 GROUP BY date
 ORDER BY date) user_c
USING(date)