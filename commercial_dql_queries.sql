-- ============================================================
-- Commercial Database: Data Query Language (DQL) Project
-- SQL Server (T-SQL). Column names match the commercial database.
-- ============================================================
USE commercial;

-- Q1. Male employees with net salary (salary + commission) >= 8000,
--     in descending order of seniority
--     (male = title 'Mr.' or 'Dr.': the only 'Dr.' is Andrew Fuller)
SELECT EMPLOYEE_int AS Employee_Number,
       FIRST_NAME   AS First_Name,
       LAST_NAME    AS Last_Name,
       DATEDIFF(YEAR, BIRTH_DATE, GETDATE()) AS Age,
       DATEDIFF(YEAR, HIRE_DATE,  GETDATE()) AS Seniority
FROM EMPLOYEES
WHERE TITLE IN ('Mr.', 'Dr.')
  AND SALARY + ISNULL(COMMISSION, 0) >= 8000
ORDER BY Seniority DESC;

-- Q2. Products: bottles, 3rd letter t/T, suppliers 1-3,
--     unit price 70 to 200, units on order not null
SELECT PRODUCT_REF     AS Product_Number,
       PRODUCT_NAME    AS Product_Name,
       SUPPLIER_int    AS Supplier_Number,
       UNITS_ON_ORDER  AS Units_On_Order,
       UNIT_PRICE      AS Unit_Price
FROM PRODUCTS
WHERE QUANTITY LIKE '%bottle%'
  AND SUBSTRING(PRODUCT_NAME, 3, 1) IN ('t', 'T')
  AND SUPPLIER_int IN (1, 2, 3)
  AND UNIT_PRICE BETWEEN 70 AND 200
  AND UNITS_ON_ORDER IS NOT NULL;

-- Q3. Customers in the same region as supplier 1
--     (same country, same city, same last 3 characters of postal code)
SELECT c.*
FROM CUSTOMERS c
WHERE EXISTS (SELECT 1
              FROM SUPPLIERS s
              WHERE s.SUPPLIER_int = 1
                AND s.COUNTRY = c.COUNTRY
                AND s.CITY = c.CITY
                AND RIGHT(RTRIM(s.POSTAL_CODE), 3) = RIGHT(RTRIM(c.POSTAL_CODE), 3));

-- Q4. New discount rate and application note for orders 10998 to 11003
SELECT od.ORDER_int AS Order_Number,
       CASE
           WHEN SUM(od.UNIT_PRICE * od.QUANTITY) <= 2000  THEN '0%'
           WHEN SUM(od.UNIT_PRICE * od.QUANTITY) <= 10000 THEN '5%'
           WHEN SUM(od.UNIT_PRICE * od.QUANTITY) <= 40000 THEN '10%'
           WHEN SUM(od.UNIT_PRICE * od.QUANTITY) <= 80000 THEN '15%'
           ELSE '20%'
       END AS New_Discount_Rate,
       CASE
           WHEN od.ORDER_int BETWEEN 10000 AND 10999
               THEN 'apply old discount rate'
           ELSE 'apply new discount rate'
       END AS Discount_Rate_Application_Note
FROM ORDER_DETAILS od
WHERE od.ORDER_int BETWEEN 10998 AND 11003
GROUP BY od.ORDER_int
ORDER BY od.ORDER_int;

-- Q5. Suppliers of beverage products
SELECT s.SUPPLIER_int AS Supplier_Number,
       s.COMPANY      AS Company,
       s.ADDRESS      AS Address,
       s.PHONE        AS Phone_Number
FROM SUPPLIERS s
WHERE s.SUPPLIER_int IN (
    SELECT p.SUPPLIER_int
    FROM PRODUCTS p
    JOIN CATEGORIES ca ON p.CATEGORY_CODE = ca.CATEGORY_CODE
    WHERE ca.CATEGORY_NAME = 'Beverages');

-- Q6. Berlin customers who ordered at most 1 dessert product (0 or 1)
SELECT c.CUSTOMER_CODE AS Customer_Code
FROM CUSTOMERS c
WHERE c.CITY = 'Berlin'
  AND (SELECT COUNT(DISTINCT od.PRODUCT_REF)
       FROM ORDERS o
       JOIN ORDER_DETAILS od ON o.ORDER_int = od.ORDER_int
       JOIN PRODUCTS p       ON od.PRODUCT_REF = p.PRODUCT_REF
       JOIN CATEGORIES ca    ON p.CATEGORY_CODE = ca.CATEGORY_CODE
       WHERE o.CUSTOMER_CODE = c.CUSTOMER_CODE
         AND ca.CATEGORY_NAME = 'Desserts') <= 1;

-- Q7. French customers and the total amount of orders placed on
--     Mondays in April 1998 (customers with no such orders show 0)
--     1900-01-01 was a Monday, so a date is a Monday when the
--     number of days since then is divisible by 7
SELECT c.CUSTOMER_CODE AS Customer_Number,
       c.COMPANY       AS Company_Name,
       c.PHONE         AS Phone_Number,
       ISNULL(SUM(od.UNIT_PRICE * od.QUANTITY), 0) AS Total_Amount,
       c.COUNTRY       AS Country
FROM CUSTOMERS c
LEFT JOIN ORDERS o
       ON o.CUSTOMER_CODE = c.CUSTOMER_CODE
      AND YEAR(o.ORDER_DATE) = 1998
      AND MONTH(o.ORDER_DATE) = 4
      AND DATEDIFF(DAY, '19000101', o.ORDER_DATE) % 7 = 0
LEFT JOIN ORDER_DETAILS od ON od.ORDER_int = o.ORDER_int
WHERE c.COUNTRY = 'France'
GROUP BY c.CUSTOMER_CODE, c.COMPANY, c.PHONE, c.COUNTRY;

-- Q8. Customers who have ordered all products
SELECT c.CUSTOMER_CODE AS Customer_Code,
       c.COMPANY       AS Company_Name,
       c.PHONE         AS Telephone
FROM CUSTOMERS c
JOIN ORDERS o ON o.CUSTOMER_CODE = c.CUSTOMER_CODE
JOIN ORDER_DETAILS od ON od.ORDER_int = o.ORDER_int
GROUP BY c.CUSTOMER_CODE, c.COMPANY, c.PHONE
HAVING COUNT(DISTINCT od.PRODUCT_REF) = (SELECT COUNT(*) FROM PRODUCTS);

-- Q9. Number of orders per French customer (0 if none)
SELECT c.CUSTOMER_CODE AS Customer_Code,
       COUNT(o.ORDER_int) AS Number_Of_Orders
FROM CUSTOMERS c
LEFT JOIN ORDERS o ON o.CUSTOMER_CODE = c.CUSTOMER_CODE
WHERE c.COUNTRY = 'France'
GROUP BY c.CUSTOMER_CODE;

-- Q10. Orders in 1996, orders in 1997, and the difference
SELECT SUM(CASE WHEN YEAR(ORDER_DATE) = 1996 THEN 1 ELSE 0 END) AS Orders_1996,
       SUM(CASE WHEN YEAR(ORDER_DATE) = 1997 THEN 1 ELSE 0 END) AS Orders_1997,
       SUM(CASE WHEN YEAR(ORDER_DATE) = 1997 THEN 1 ELSE 0 END)
     - SUM(CASE WHEN YEAR(ORDER_DATE) = 1996 THEN 1 ELSE 0 END) AS Difference
FROM ORDERS;