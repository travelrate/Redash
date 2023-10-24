WITH name_price AS
(SELECT date, product_name, price
 FROM
 (SELECT creation_time::DATE as date, order_id, UNNEST(product_ids) as product_id
  FROM orders
  WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) dates
JOIN
 (SELECT name as product_name, price, product_id
  FROM products) name_price
USING(product_id)),

product_revenue AS
(SELECT product_name, SUM(price) as revenue, ROUND((SUM(price)/SUM(SUM(price)) OVER())*100, 2) as share
 FROM name_price
 GROUP BY product_name
 ORDER BY product_name),

endt AS
(SELECT CASE WHEN share >= 0.5 THEN product_name
            ELSE 'ДРУГОЕ' END as product_name,
       CASE WHEN share >= 0.5 THEN revenue
            ELSE (SELECT SUM(revenue) FROM product_revenue WHERE share < 0.5) END AS revenue,
       CASE WHEN share >= 0.5 THEN share
            ELSE (SELECT SUM(share) FROM product_revenue WHERE share < 0.5) END AS share_in_revenue
FROM product_revenue)

SELECT DISTINCT product_name, revenue, share_in_revenue
FROM endt
ORDER BY revenue DESC