SELECT date, new_users, new_couriers, total_users, total_couriers, new_users_change, new_couriers_change, total_users_growth, total_couriers_growth
FROM
(SELECT date, new_users, total_users, 
        ROUND(((new_users-new_lag)::DECIMAL/new_lag) * 100, 2) AS new_users_change, 
        ROUND(((total_users-total_lag)::DECIMAL/total_lag) * 100, 2) AS total_users_growth
FROM
 (SELECT date, new_users, total_users, LAG(new_users, 1) OVER() AS new_lag, LAG(total_users, 1) OVER() AS total_lag
  FROM
   (SELECT first_time::DATE AS date, COUNT(user_id) AS new_users, SUM(COUNT(user_id)) OVER(ORDER BY first_time::DATE ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)::INT AS total_users
    FROM
     (SELECT DISTINCT user_id, MIN(time) AS first_time
      FROM user_actions
      WHERE action = 'create_order'
      GROUP BY user_id
      ORDER BY first_time) first
  GROUP BY date
  ORDER BY date) users) ulags) uchange
JOIN
(SELECT date, new_couriers, total_couriers, 
        ROUND(((new_couriers-new_lag_c)::DECIMAL/new_lag_c) * 100, 2) AS new_couriers_change, 
        ROUND(((total_couriers-total_lag_c)::DECIMAL/total_lag_c) * 100, 2) AS total_couriers_growth
 FROM
  (SELECT date, new_couriers, total_couriers, LAG(new_couriers, 1) OVER() AS new_lag_c, LAG(total_couriers, 1) OVER() AS total_lag_c
   FROM
    (SELECT first_time::DATE AS date, COUNT(courier_id) AS new_couriers, SUM(COUNT(courier_id)) OVER(ORDER BY first_time::DATE ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)::INT AS total_couriers
     FROM
      (SELECT DISTINCT courier_id, MIN(time) AS first_time
       FROM courier_actions
       WHERE action = 'accept_order'
       GROUP BY courier_id
       ORDER BY first_time) first
   GROUP BY date
   ORDER BY date) couriers) clags) cchange 
USING(date)
ORDER BY date