SELECT date, 
       ROUND(((single/total::DECIMAL)*100), 2) as single_order_users_share, 
       ROUND(((several/total::DECIMAL)*100), 2)as several_orders_users_share
FROM
(SELECT date, COUNT(user_id) FILTER (WHERE orders = 1) as single, COUNT(user_id) FILTER (WHERE orders > 1) as several, SUM(COUNT(user_id)) OVER(PARTITION BY date ORDER BY date) as total
 FROM
 (SELECT time::DATE as date, user_id, COUNT(order_id) as orders 
  FROM user_actions
  WHERE order_id in (SELECT order_id FROM user_actions WHERE action = 'create_order') and order_id not in (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
  GROUP BY date, user_id
  ORDER BY date) users
GROUP BY date) ready
ORDER BY date