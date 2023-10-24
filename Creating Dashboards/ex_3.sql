SELECT date, paying_users, active_couriers,
       ROUND((paying_users::DECIMAL/total_users)*100, 2) as paying_users_share,
       ROUND((active_couriers::DECIMAL/total_couriers)*100, 2) as active_couriers_share
FROM
(SELECT date, active_couriers, total_couriers, paying_users, total_users
 FROM
 (SELECT date, active_couriers, total_couriers
  FROM
   ((SELECT time::DATE as date, COUNT(DISTINCT courier_id) as active_couriers
     FROM courier_actions
     WHERE order_id IN (SELECT order_id FROM courier_actions WHERE action = 'accept_order') AND order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order')
     GROUP BY date) couriers
 JOIN
 (SELECT date, SUM(COUNT(courier_id)) OVER(ORDER BY date rows between unbounded preceding AND current row)::INT as total_couriers
  FROM
   (SELECT DISTINCT courier_id, MIN(time)::DATE as date
    FROM courier_actions
    WHERE action = 'accept_order'
    GROUP BY courier_id) t2
  GROUP BY date) total2
 USING(date)) endcourier) kek1
JOIN
 (SELECT date, paying_users, total_users
  FROM
   ((SELECT time::DATE as date, COUNT(DISTINCT user_id) as paying_users
     FROM user_actions
     WHERE order_id IN (SELECT order_id FROM user_actions WHERE action = 'create_order') AND order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
     GROUP BY date) users
 JOIN
 (SELECT date, SUM(COUNT(user_id)) OVER(ORDER BY date rows between unbounded preceding AND current row)::INT as total_users
  FROM 
   (SELECT DISTINCT user_id, MIN(time)::DATE as date
    FROM user_actions
    WHERE action = 'create_order'
    GROUP BY user_id) t1
 GROUP BY date) total1
 USING(date)) enduser) kek2
USING (date)) smert
ORDER BY date