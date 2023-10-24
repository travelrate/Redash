SELECT weekday, weekday_number, 
       ROUND(price::DECIMAL/users, 2) as arpu,
       ROUND(price::DECIMAL/paying_users, 2) as arppu,
       ROUND(price::DECIMAL/orders, 2) as aov
FROM
(SELECT DATE_PART('isodow', time) as weekday_number, 
       COUNT(DISTINCT user_id) FILTER (WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) as paying_users, 
       COUNT(DISTINCT user_id) as users,
       COUNT(order_id) FILTER (WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) as orders
FROM user_actions
WHERE time BETWEEN '2022-08-26' AND '2022-09-09'
GROUP BY weekday_number) users
JOIN
(SELECT weekday, weekday_number, SUM(price) as price
FROM
(SELECT TO_CHAR(creation_time, 'Day') as weekday, 
        DATE_PART('isodow', creation_time) as weekday_number,
        order_id, 
        UNNEST(product_ids) as product_id 
 FROM orders
 WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
   AND creation_time BETWEEN '2022-08-26' AND '2022-09-09') as days
JOIN
(SELECT price, product_id 
 FROM products) ids
USING(product_id)
GROUP BY weekday_number, weekday) prices
USING(weekday_number)
ORDER BY weekday_number