WITH total_orders AS
(SELECT date, off_orders, del_orders, COALESCE(str_couriers, 0) as str_couriers
FROM
(SELECT time::DATE as date, COUNT(order_id) as off_orders
 FROM courier_actions
 WHERE action = 'accept_order' AND order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
 GROUP BY date) t1
JOIN
(SELECT time::DATE as date, COUNT(order_id) as del_orders
 FROM courier_actions
 WHERE action = 'deliver_order' AND order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
 GROUP BY date) t2
USING(date)
LEFT JOIN
(SELECT date, COUNT(courier_id) as str_couriers
 FROM
  (SELECT time::DATE as date, courier_id, SUM(COUNT(order_id)) OVER(PARTITION BY courier_id, time::DATE ORDER BY time::DATE) as count_orders
   FROM courier_actions
   WHERE action = 'deliver_order' AND order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
   GROUP BY date, courier_id) one
 WHERE count_orders >= 5
 GROUP BY date) t3
 USING(date)
 ORDER BY date),
 
day_revenue AS
(SELECT date, SUM(price) as revenue FROM
 (SELECT creation_time::DATE as date, order_id, UNNEST(product_ids) as product_id FROM orders
  WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) t1
JOIN (SELECT price, product_id FROM products) t2 USING(product_id)
GROUP BY date),

taxes AS
(SELECT date, SUM(tax) as tax FROM
(SELECT date, price, name, 
       CASE WHEN name IN ('сахар', 'сухарики', 'сушки', 'семечки', 'масло льняное', 'виноград', 'масло оливковое', 'арбуз', 'батон', 'йогурт', 'сливки', 'гречка', 'овсянка', 'макароны', 
       'баранина', 'апельсины', 'бублики', 'хлеб', 'горох', 'сметана', 'рыба копченая', 'мука', 'шпроты', 'сосиски', 'свинина', 'рис', 'масло кунжутное', 'сгущенка', 'ананас', 'говядина', 
       'соль', 'рыба вяленая', 'масло подсолнечное', 'яблоки', 'груши', 'лепешка', 'молоко', 'курица', 'лаваш', 'вафли', 'мандарины') 
       THEN ROUND(price/110*10, 2) ELSE ROUND(price/120*20, 2) END AS tax 
FROM
(SELECT creation_time::DATE as date, order_id, UNNEST(product_ids) as product_id 
 FROM orders
 WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) t1
JOIN 
(SELECT name, price, product_id 
 FROM products) t2 
USING(product_id)) taxes
GROUP BY date) 

SELECT date, revenue, costs, tax, revenue-(costs+tax) as gross_profit, 
       SUM(revenue) OVER(ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as total_revenue,
       SUM(costs) OVER(ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as total_costs,
       SUM(tax) OVER(ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as total_tax,
       SUM(revenue-(costs+tax)) OVER(ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as total_gross_profit,
       ROUND((revenue-(costs+tax))/revenue*100, 2) as gross_profit_ratio,
       ROUND(SUM(revenue-(costs+tax)) OVER(ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)/SUM(revenue) OVER(ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)*100, 2) as total_gross_profit_ratio
FROM
(SELECT date, revenue,
       CASE WHEN DATE_PART('month', date) = 8 THEN ROUND((off_orders*140)+(del_orders*150)+(str_couriers*400)+120000::DECIMAL, 2)
            WHEN DATE_PART('month', date) = 9 THEN ROUND((off_orders*115)+(del_orders*150)+(str_couriers*500)+150000::DECIMAL, 2)
            END AS costs, tax
FROM total_orders JOIN day_revenue USING(date) JOIN taxes USING(date)) three