SELECT date, new_users, new_couriers, total_users, total_couriers
FROM
(SELECT first_time::DATE AS date, 
        COUNT(user_id) AS new_users, 
        SUM(COUNT(user_id)) OVER(ORDER BY first_time::DATE ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)::INT AS total_users
 FROM
  (SELECT DISTINCT user_id, MIN(time) AS first_time
   FROM user_actions
   WHERE action = 'create_order'
   GROUP BY user_id
   ORDER BY first_time) first
 GROUP BY date
 ORDER BY date) users
JOIN
(SELECT first_time::DATE AS date, 
        COUNT(courier_id) AS new_couriers, 
        SUM(COUNT(courier_id)) OVER(ORDER BY first_time::DATE ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)::INT AS total_couriers
 FROM
  (SELECT DISTINCT courier_id, MIN(time) AS first_time
   FROM courier_actions
   WHERE action = 'accept_order'
   GROUP BY courier_id
   ORDER BY first_time) first
 GROUP BY date
 ORDER BY date) couriers 
USING(date)