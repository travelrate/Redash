SELECT table4.date, revenue, SUM(price) AS new_users_revenue,
       round(SUM(price)::decimal / revenue * 100, 2) as new_users_revenue_share,
       round((revenue - SUM(price))::decimal / revenue * 100, 2) as old_users_revenue_share
FROM
(SELECT min_time, date, price, user_id
 FROM
  (SELECT MIN(time)::DATE as min_time, user_id
   FROM user_actions
   GROUP BY user_id) first_date_user
  JOIN
  (SELECT date, user_id, SUM(price) as price
   FROM
    (SELECT order_id, time::DATE as date, user_id
     FROM user_actions
     WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) user_order
    JOIN
    (SELECT order_id, SUM(price) as price
     FROM
      (SELECT order_id, UNNEST(product_ids) as product_id
       FROM orders) AS produst
      JOIN products USING(product_id)
      GROUP BY order_id) AS order_prise
      USING(order_id)
     GROUP BY user_id, date) price_order
     USING(user_id)) table3
JOIN
(SELECT date, SUM(price) as revenue
 FROM
 (SELECT creation_time::DATE as date, order_id, UNNEST(product_ids) as product_id
  FROM orders
  WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) one
 JOIN
 (SELECT price, product_id FROM products) two
 USING(product_id)
GROUP BY date) table4
ON table3.date=table4.date
WHERE table4.date=min_time
GROUP BY table4.date, revenue
ORDER BY table4.date