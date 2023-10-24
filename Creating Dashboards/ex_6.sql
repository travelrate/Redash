SELECT date, 
       ROUND(paying_user::DECIMAL/active_courier, 2) as users_per_courier, 
       ROUND(orders::DECIMAL/active_courier, 2) as orders_per_courier
FROM
(
SELECT date, orders, paying_user, active_courier
FROM
(
(SELECT time::DATE as date, COUNT(DISTINCT user_id) as paying_user
 FROM user_actions
 WHERE order_id IN (SELECT order_id FROM user_actions WHERE action = 'create_order') 
   AND order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
 GROUP BY date) us
JOIN
(SELECT time::DATE as date, COUNT(DISTINCT courier_id) as active_courier
 FROM courier_actions
 WHERE order_id IN (SELECT order_id FROM courier_actions WHERE action = 'accept_order')
   AND order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order')
 GROUP BY date) co
 USING(date)
JOIN
(SELECT creation_time::DATE as date, COUNT(order_id) as orders
 FROM orders
 WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
 GROUP BY date) ord
 USING(date)
) tables
) endtable
ORDER BY date