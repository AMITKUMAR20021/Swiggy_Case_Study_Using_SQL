-- 1. How many customers have not placed any orders?
SELECT user_id 
FROM users 
WHERE user_id NOT IN (
    SELECT DISTINCT user_id 
    FROM orders 
    WHERE user_id IS NOT NULL
);

-- 2a. What is the average price of each food type?
SELECT type, 
       ROUND(AVG(price), 2) AS "Average Price"
FROM food f
JOIN menu m ON f.f_id = m.f_id
GROUP BY type
ORDER BY "Average Price" DESC;

-- 2b. What is the average price of food for each restaurant?
SELECT r.R_Name AS "Restaurant Name", 
       CONCAT('$ ', ROUND(AVG(price), 2)) AS "Average Price"
FROM restaurants r
JOIN menu m ON r.r_id = m.r_id
GROUP BY r.R_Name
ORDER BY r.R_Name;

-- 3. Find the top restaurant in terms of the number of orders for all months
WITH res AS (
    SELECT DATE_FORMAT(o.order_date, '%M') AS order_month, 
           r.r_name, 
           COUNT(*) AS order_count
    FROM orders o
    JOIN restaurants r ON o.r_id = r.r_id
    GROUP BY MONTH(o.order_date), r.r_name
)
SELECT order_month, r_name
FROM (
    SELECT order_month, r_name, 
           RANK() OVER (PARTITION BY order_month ORDER BY order_count DESC) AS res_rank
    FROM res
) ranked_res
WHERE res_rank = 1
ORDER BY MONTH(STR_TO_DATE(order_month, '%M'));

-- 4. Find the top restaurant in terms of the number of orders for the month of June
SELECT *
FROM restaurants r
JOIN orders o ON r.r_id = o.r_id
WHERE MONTHNAME(o.ORDER_DATE) = 'June';

-- 5. Restaurants with monthly revenue greater than 500
WITH res AS (
    SELECT DATE_FORMAT(o.order_date, '%M') AS order_month, 
           r.r_name, 
           SUM(m.price) AS price
    FROM restaurants r
    JOIN orders o ON r.r_id = o.r_id
    JOIN menu m ON o.r_id = m.r_id
    GROUP BY order_month, r.r_name
    HAVING price >= 500
)
SELECT * 
FROM res
ORDER BY MONTH(STR_TO_DATE(order_month, '%M'));

-- 6. Show all orders with order details for a particular customer in a particular date range
SELECT * 
FROM users u
JOIN orders o ON u.user_id = o.user_id
WHERE u.user_id = 1 
  AND o.order_date BETWEEN STR_TO_DATE('15-05-22', '%d-%m-%y') AND STR_TO_DATE('15-06-22', '%d-%m-%y');

-- 7. Which restaurant has the highest number of repeat customers?
WITH repeated_cust AS (
    SELECT r.r_name, o.user_id, COUNT(*) AS order_count
    FROM restaurants r
    JOIN orders o ON r.r_id = o.r_id
    GROUP BY r.r_name, o.user_id
    HAVING order_count > 1
), loyal_cust AS (
    SELECT r_name, COUNT(user_id) AS Repeated_customers 
    FROM repeated_cust
    GROUP BY r_name
    ORDER BY Repeated_customers DESC
)
SELECT * 
FROM loyal_cust
LIMIT 1;

-- 8. Month over month revenue growth of the platform
WITH month_rev AS (
    SELECT DATE_FORMAT(o.order_date, '%M') AS order_month, 
           SUM(m.price) AS monthly_rev
    FROM orders o
    JOIN menu m ON o.r_id = m.r_id
    GROUP BY order_month
)
SELECT order_month, 
       SUM(monthly_rev) OVER (ORDER BY MONTH(STR_TO_DATE(order_month, '%M'))) AS Rolling_Monthly_Rev
FROM month_rev;

-- 9. Find the top 3 most ordered dishes
SELECT f.F_NAME, COUNT(*) AS order_count 
FROM order_details od
JOIN food f ON f.f_id = od.f_id
GROUP BY F_NAME
ORDER BY order_count DESC
LIMIT 3;

-- 10. Month over month revenue growth of each restaurant
WITH res_grouped AS (
    SELECT r.r_name, 
           DATE_FORMAT(o.order_date, '%M') AS order_month, 
           SUM(m.price) AS price
    FROM orders o
    JOIN restaurants r ON o.r_id = r.r_id
    JOIN menu m ON o.r_id = m.r_id
    GROUP BY r.r_name, order_month
)
SELECT r_name, order_month,
       SUM(price) OVER (
           PARTITION BY r_name
           ORDER BY MONTH(STR_TO_DATE(order_month, '%M')) ASC
       ) AS res_rolling_month_rev
FROM res_grouped;

-- 11. What is the overall revenue generated by the platform during a specific time period?
SELECT SUM(amount) AS total_revenue
FROM orders
WHERE order_date BETWEEN STR_TO_DATE('01-05-22', '%d-%m-%y') AND STR_TO_DATE('01-06-22', '%d-%m-%y');

-- 12. What is the average order value per user?
SELECT user_id, AVG(amount) AS avg_order_value
FROM orders
GROUP BY user_id;

-- 13. What is the average delivery time for each restaurant, and how does it affect customer satisfaction?
SELECT r.r_name, 
       ROUND(AVG(o.delivery_time), 2) AS avg_delivery_time, 
       ROUND(AVG(o.delivery_rating), 2) AS avg_delivery_rating
FROM orders o
JOIN restaurants r ON o.r_id = r.r_id
GROUP BY r.r_name;

-- 14. What is the average rating for each restaurant and delivery partner?
SELECT r.r_name, 
       ROUND(AVG(o.restaurant_rating), 2) AS avg_restaurant_rating
FROM orders o
JOIN restaurants r ON o.r_id = r.r_id
GROUP BY r.r_name;

SELECT dp.partner_name, 
       ROUND(AVG(o.delivery_rating), 2) AS avg_delivery_rating
FROM orders o
JOIN delivery_partner dp ON o.partner_id = dp.partner_id
GROUP BY dp.partner_name;

-- 15. How do the ratings for restaurants and delivery partners correlate with customer retention?
-- MySQL does not support CORR function directly, so this part requires custom implementation.

-- 16. Which days and times see the highest order volume, and are there any patterns in user behavior?
SELECT DAYNAME(order_date) AS order_day, 
       HOUR(order_date) AS order_hour, 
       COUNT(order_id) AS order_count
FROM orders
GROUP BY DAYNAME(order_date), HOUR(order_date)
ORDER BY order_count DESC;

-- 17. How many orders were delivered by each delivery partner and what is their average delivery rating?
SELECT dp.PARTNER_ID, dp.PARTNER_NAME, 
       COUNT(*) AS DELIVERY_COUNT, 
       AVG(o.DELIVERY_RATING) AS AVG_DELIVERY_RATING
FROM orders o
JOIN delivery_partner dp ON o.PARTNER_ID = dp.PARTNER_ID
GROUP BY dp.PARTNER_ID, dp.PARTNER_NAME;

-- 18. What is the distribution of delivery partners in the Delivery_Partner table?
SELECT PARTNER_NAME, COUNT(*) AS PARTNER_COUNT 
FROM delivery_partner 
GROUP BY PARTNER_NAME 
ORDER BY PARTNER_COUNT DESC;
