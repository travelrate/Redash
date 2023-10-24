SELECT date, CEIL(AVG(diff_min))::int as minutes_to_deliver
FROM
(SELECT date, accept, deliver, DATE_PART('min', AGE(deliver, accept))::INT as diff_min
 FROM
 ((SELECT order_id, time as accept
   FROM courier_actions
   WHERE action = 'accept_order') tab1
 JOIN
  (SELECT order_id, time as deliver
   FROM courier_actions
   WHERE action = 'deliver_order') tab2
 USING(order_id)) acc_del
 JOIN
  (SELECT order_id, time::DATE as date 
   FROM courier_actions
   WHERE action = 'deliver_order') dates
 USING(order_id)
 WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) diff
GROUP BY date
ORDER BY date