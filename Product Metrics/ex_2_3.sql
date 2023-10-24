WITH order_price AS
(SELECT date, SUM(price) as revenue, 
        SUM(SUM(price)) OVER(ORDER BY date rows between unbounded preceding and current row) as o_revenue
 FROM
 (SELECT order_id, creation_time::DATE as date, UNNEST(product_ids) as product_id FROM orders) ids
 JOIN
 (SELECT price, product_id FROM products) price
 USING(product_id)
WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
GROUP BY date
ORDER BY date)

SELECT date, 
       ROUND(o_revenue::DECIMAL/on_users, 2) as running_arpu,
       ROUND(o_revenue::DECIMAL/op_users, 2) as running_arppu,
       ROUND(o_revenue::DECIMAL/o_orders, 2) as running_aov

FROM
(SELECT first_date::DATE as date, COUNT(DISTINCT user_id) as new_users, 
       SUM(COUNT(DISTINCT user_id)) OVER(ORDER BY first_date::DATE rows between unbounded preceding and current row) as on_users
FROM
(SELECT user_id, MIN(time) OVER(PARTITION BY user_id) as first_date
 FROM user_actions) t1
GROUP BY date) tab1
JOIN
(SELECT first_date::DATE as date, COUNT(DISTINCT user_id) as paying_users,
       SUM(COUNT(DISTINCT user_id)) OVER(ORDER BY first_date::DATE rows between unbounded preceding and current row) as op_users
FROM
(SELECT user_id, MIN(time) OVER(PARTITION BY user_id) as first_date
 FROM user_actions
 WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) t1
GROUP BY date) tab2
USING(date)
JOIN
(SELECT time::date as date,
       COUNT(DISTINCT order_id) as orders, 
       SUM(COUNT(DISTINCT order_id)) OVER(ORDER BY time::DATE rows between unbounded preceding and current row) as o_orders
FROM user_actions
WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
GROUP BY date) tab3
USING(date)
JOIN order_price USING(date)