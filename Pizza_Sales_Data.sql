DROP TABLE IF EXISTS Pizza_Sales_Data;
CREATE TABLE IF NOT EXISTS Pizza_Sales_Data(
	order_details_id INT PRIMARY KEY,
	order_id INT,
	pizza_id VARCHAR(100),
	quantity INT,
	order_date DATE,
	order_time TIME,
	unit_price NUMERIC(10,2),
	total_price NUMERIC(10,2),
	pizza_size VARCHAR(20),
	pizza_category VARCHAR(50),
	pizza_ingredients TEXT,
	pizza_name TEXT,
	ORDER_DATE_MONTH TEXT,
	WEEK_NUM_OF_ORDER_DATE INT,
	ORDER_DATE_DAY TEXT,
	ORDER_TIME_HOUR INT
);

SELECT * FROM Pizza_Sales_Data ORDER BY order_details_id;

COPY Pizza_Sales_Data
FROM 'C:\Users\hp\Desktop\BUSINESS ANALYST PROJECTS\Data Model - Pizza Sales.xlsx - pizza_sales.csv'
DELIMITER ','
CSV HEADER;

SELECT DISTINCT pizza_size
FROM Pizza_Sales_Data;

--Data cleaning in PostgreSQL
--1. Trim spaces / normalize case:
UPDATE Pizza_Sales_Data
SET pizza_name = INITCAP(TRIM(pizza_name)),
    pizza_category = INITCAP(TRIM(pizza_category)),
    pizza_size = UPPER(TRIM(pizza_size));

--2. Map abbreviated sizes to full names (safe: create a new column or update in place):
 UPDATE Pizza_Sales_Data
 SET pizza_size = CASE
  WHEN pizza_size IN ('L','LG') THEN 'Large'
  WHEN pizza_size IN ('M') THEN 'Medium'
  WHEN pizza_size IN ('S') THEN 'Small'
  WHEN pizza_size IN ('XL') THEN 'Upper_Large'
  WHEN pizza_size IN ('XXL') THEN 'Very_Large'
  ELSE pizza_size
END;

--3. Find NULLs / suspicious rows:
SELECT
  COUNT(*) AS total_rows,
  COUNT(*) FILTER (WHERE total_price IS NULL) AS null_total_price,
  COUNT(*) FILTER (WHERE quantity IS NULL) AS null_quantity,
  COUNT(*) FILTER (WHERE order_date IS NULL OR order_time IS NULL) AS null_dates
FROM Pizza_Sales_Data;

--4. Find negative or zero price/quantity:
SELECT * FROM Pizza_Sales_Data
WHERE quantity <= 0 OR total_price <= 0
LIMIT 50;

SELECT * FROM Pizza_Sales_Data ORDER BY order_details_id;

--5. Add indices for performance:
CREATE INDEX idx_order_date ON Pizza_Sales_Data (order_date);
CREATE INDEX idx_order_time ON Pizza_Sales_Data  (order_time);
CREATE INDEX idx_pizza_name ON Pizza_Sales_Data  (pizza_name);

--A. KPI's:
--1. Total Revenue:
SELECT ROUND(SUM(total_price),2)AS Total_Revenue
FROM Pizza_Sales_Data;

--2. Average Order Value:
SELECT  ROUND(SUM(total_price)/COUNT(DISTINCT order_id),2)AS Avg_Order_Value
FROM Pizza_Sales_Data;

--3. Total Pizza Sold:
SELECT SUM(quantity)AS Total_Pizza_Sold
FROM Pizza_Sales_Data;

--4. Total Orders:
SELECT COUNT(DISTINCT order_id)AS Total_Orders
FROM Pizza_Sales_Data;

--5. Average Pizzas Per Order:
SELECT ROUND(CAST(SUM(quantity)AS DECIMAL(10,2))/CAST(COUNT(DISTINCT order_id)
AS DECIMAL(10,2)),2)AS Average_Pizzas_Per_Order
FROM Pizza_Sales_Data;

--B. Daily Trend for Total Orders(stacked by category)
SELECT TO_CHAR(order_date,'DAY')AS Order_Day, pizza_category,
COUNT(DISTINCT order_id)AS Total_Orders
FROM Pizza_Sales_Data
GROUP BY Order_Day, pizza_category ORDER BY Order_Day,pizza_category;

--C. Hourly Trend for Total Pizzas Sold(stacked by category)
SELECT EXTRACT(HOUR FROM order_time) AS order_time_hours,pizza_category,
    SUM(quantity) AS total_quantity
FROM Pizza_Sales_Data
GROUP BY EXTRACT(HOUR FROM order_time), pizza_category
ORDER BY order_time_hours,pizza_category;
         --or..
SELECT order_time_hour,pizza_category,SUM(quantity) AS total_quantity_sold
FROM Pizza_Sales_Data
GROUP BY order_time_hour, pizza_category
ORDER BY order_time_hour,pizza_category;

SELECT * FROM Pizza_Sales_Data ORDER BY order_details_id;

--D. Monthly and Weekly Trend for Orders(stacked by category)
SELECT EXTRACT(YEAR FROM order_date)AS Year_Extracted,
DATE_PART('MONTH',order_date)AS Month_Extracted,
week_num_of_order_date,pizza_category, COUNT(DISTINCT order_id)AS Orders_Placed
FROM Pizza_Sales_Data
GROUP BY EXTRACT(YEAR FROM order_date), DATE_PART('MONTH',order_date),
week_num_of_order_date, pizza_category;
     --Or...
SELECT DATE_PART('YEAR',order_date)AS Year_Extracted,
	DATE_PART('MONTH',order_date)AS Month_Extracted,
	DATE_TRUNC('WEEK',order_date)AS Start_of_Week, 
	pizza_category,
	COUNT(DISTINCT order_id)AS Orders_Placed
FROM Pizza_Sales_Data
GROUP BY Year_Extracted, Month_Extracted, Start_of_Week, pizza_category
ORDER BY Month_Extracted,Start_of_Week, Orders_Placed DESC;

--D. Monthly Trend for Orders
SELECT TO_CHAR(order_date,'Month')AS Month_Extracted,
	COUNT(DISTINCT order_id)AS Total_Orders
FROM Pizza_Sales_Data
GROUP BY Month_Extracted ORDER BY Total_Orders DESC;

--D. Weekly Trend for Orders
SELECT DATE_TRUNC('WEEK',order_date)AS Start_Of_Week,
	COUNT(DISTINCT order_id)AS Total_Orders
FROM Pizza_Sales_Data
GROUP BY Start_Of_Week ORDER BY Start_Of_Week;

--E.  % of Sales by Pizza Category
SELECT pizza_category, SUM(total_price)AS Total_Revenue, 
	ROUND(SUM(total_price)*100/(SELECT SUM(total_price) FROM Pizza_Sales_Data),2)
	AS Perc_of_Total_Sales
FROM Pizza_Sales_Data
GROUP BY pizza_category ORDER BY Perc_of_Total_Sales DESC;

--E.  % of Sales by Pizza Category(for Janauary month only)
SELECT pizza_category, SUM(total_price)AS Total_Sales, 
	ROUND(SUM(total_price)*100/(SELECT SUM(total_price) FROM Pizza_Sales_Data 
	WHERE DATE_PART('MONTH',order_date)=1),2) AS Perc_of_Total_Sales
FROM Pizza_Sales_Data
WHERE DATE_PART('MONTH',order_date)=1
GROUP BY pizza_category ORDER BY Perc_of_Total_Sales DESC;

--F. % of Sales by Pizza Size
SELECT pizza_size, SUM(total_price)AS Total_Revenue, 
ROUND(SUM(total_price)/(SELECT SUM(total_price) FROM Pizza_Sales_Data)*100,2) 
AS Perc_of_Total_Sales FROM Pizza_Sales_Data
GROUP BY pizza_size ORDER BY Perc_of_Total_Sales DESC;

--F. % of Sales by Pizza Size(for 1st quarter only)
SELECT pizza_size, ROUND(SUM(total_price),2)AS Total_Revenue, 
	ROUND(SUM(total_price)/(SELECT SUM(total_price) FROM Pizza_Sales_Data
	WHERE DATE_PART('QUARTER',order_date)=1)*100,2) AS Perc_of_Total_Sales 
FROM Pizza_Sales_Data WHERE DATE_PART('QUARTER',order_date)=1
GROUP BY pizza_size ORDER BY Perc_of_Total_Sales DESC;

SELECT * FROM Pizza_Sales_Data ORDER BY order_details_id;

--G.  Total Pizzas Sold by Pizza Category
SELECT pizza_category, SUM(quantity)AS Pizzas_Sold
FROM Pizza_Sales_Data
GROUP BY pizza_category ORDER BY Pizzas_Sold DESC;

--H. Top 5 Pizzas by Revenue
SELECT pizza_name, SUM(total_price)AS Total_Revenue
FROM Pizza_Sales_Data
GROUP BY pizza_name ORDER BY Total_Revenue DESC
LIMIT 5;

--I. Bottom 5 Pizzas by Revenue
SELECT pizza_name, SUM(total_price)AS Total_Revenue
FROM Pizza_Sales_Data
GROUP BY pizza_name ORDER BY Total_Revenue ASC
LIMIT 5;

--J. Top 5 Pizzas by Quantity
SELECT pizza_name, SUM(quantity)AS quantity_sold
FROM Pizza_Sales_Data
GROUP BY pizza_name ORDER BY quantity_sold DESC
LIMIT 5;

--K. Bottom 5 Pizzas by Quantity
SELECT pizza_name, SUM(quantity)AS quantity_sold
FROM Pizza_Sales_Data
GROUP BY pizza_name ORDER BY quantity_sold ASC
LIMIT 5;

SELECT * FROM Pizza_Sales_Data ORDER BY order_details_id;

--L. Top 5 Pizzas by Total Orders
SELECT pizza_name, COUNT(DISTINCT order_id)AS Total_Orders
FROM Pizza_Sales_Data
GROUP BY pizza_name ORDER BY Total_Orders DESC
LIMIT 5;

--M. Bottom 5 Pizzas by Total Orders
SELECT pizza_name, COUNT(DISTINCT order_id)AS Total_Orders
FROM Pizza_Sales_Data
GROUP BY pizza_name ORDER BY Total_Orders ASC
LIMIT 5;






