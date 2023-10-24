SELECT date, orders, first_orders, new_users_orders,
       ROUND((first_orders/orders::DECIMAL)*100, 2) as first_orders_share,
       ROUND((new_users_orders/orders::DECIMAL)*100, 2) as new_users_orders_share
FROM
(
(SELECT time::DATE as date, COUNT(order_id) as orders
 FROM user_actions
 WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
 GROUP BY date
 ORDER BY date) tab1
JOIN
(SELECT time::DATE as date, COUNT(DISTINCT user_id) as first_orders
 FROM
 (SELECT user_id, order_id, time, RANK() OVER(PARTITION BY user_id ORDER BY time) as rank
  FROM user_actions
   WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
   GROUP BY user_id, time, order_id
   ORDER BY user_id) ranks
  WHERE rank = 1
  GROUP BY date) tab2
USING(date)
JOIN
(SELECT min_date.date as date, COALESCE(COUNT(DISTINCT orders.order_id), 0) as new_users_orders
 FROM
  ((SELECT user_id, MIN(time)::DATE as date
    FROM user_actions
    GROUP BY user_id) min_date
 LEFT JOIN
 (SELECT time::DATE as date, user_id, order_id
  FROM user_actions
  WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) orders
 ON min_date.user_id = orders.user_id AND min_date.date = orders.date)
 GROUP BY min_date.date
 ORDER BY min_date.date) tab3
USING(date)
) uni