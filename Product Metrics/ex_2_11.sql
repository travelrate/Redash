SELECT DATE_TRUNC('month', start_date)::DATE as start_month, start_date, date-start_date as day_number, 
       ROUND(COUNT(DISTINCT user_id)::DECIMAL/MAX(COUNT(DISTINCT user_id)) OVER(PARTITION BY start_date), 2) as retention
FROM
(SELECT user_id, MIN(time::DATE) OVER(PARTITION BY user_id) as start_date, time::DATE as date
 FROM user_actions) tab
GROUP BY start_date, date 