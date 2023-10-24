SELECT hour::INT, successful_orders, canceled_orders, ROUND(canceled_orders::DECIMAL/(successful_orders+canceled_orders), 3) as cancel_rate
FROM
(
(SELECT DATE_PART('hour', creation_time) as hour, COUNT(order_id) as successful_orders
FROM orders
WHERE order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order') AND order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
GROUP BY hour) tab1
JOIN
(SELECT DATE_PART('hour', creation_time) as hour, COUNT(order_id) as canceled_orders
FROM orders
WHERE order_id IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
GROUP BY hour) tab2
USING(hour)
) uni
ORDER BY hour