

-- 1 General Sales Insights
-- What is the total revenue generated over the entire period?
select ( sum((p.Price)*od.Quantity)) as TOtal_Revenue from products p
join  orderdetails od on od.ProductID=p.ProductID;

-- Revenue Excluding Returned Orders
select ( sum((p.Price)*od.Quantity)) as TOtal_Revenue_Excluding_Return from products p
join  orderdetails od on od.ProductID=p.ProductID 
join orders o on o.OrderID= od.OrderID
where o.IsReturned in('0',false)   ;

-- Total Revenue per Year / Month
select year(o.OrderDate) as Year,month(o.OrderDate) as Month, sum(p.Price*od.Quantity) as Year_Montly_revenue
from products p
join  orderdetails od on od.ProductID=p.ProductID 
join orders o on o.OrderID= od.OrderID
group by Year,Month
order by Year,Month ;

-- Revenue by Product / Category
select p.ProductName as Product_name,p.Category as Category  ,( sum((p.Price)*od.Quantity)) as Product_Revenue from products p
join  orderdetails od on od.ProductID=p.ProductID 
join orders o on o.OrderID= od.OrderID
group by Category,Product_name
order by Category, Product_Revenue desc;

-- Average Order Value (AOV)? AOV = Total Revenue / Total Number of Orders

select ( (sum((p.Price)*od.Quantity)/count(distinct o.OrderID))) as Avg_order_value from products p
join  orderdetails od on od.ProductID=p.ProductID 
join orders o on o.OrderID= od.OrderID;

-- AOV per Year / Month
select Year ,Month,avg(TotalRevenue) as AOV from (select year(o.OrderDate) as Year,
month(o.OrderDate) as Month,
 (sum((p.Price)*od.Quantity)) as TotalRevenue,o.OrderID as id from products p
join  orderdetails od on od.ProductID=p.ProductID 
join orders o on o.OrderID= od.OrderID
group by id,Year,Month
 ) t
group by Year,Month
order by Year,Month ,AOV desc;

-- What is the average order size by region? Average Order Size = Average quantity (units) per order
select r.RegionName as RegionName  ,avg(quantity) as Average_Order_Size from (select
sum(od.Quantity) as quantity,o.OrderID as orderid,c.RegionID as custregID from orderdetails od
join orders o on o.OrderID=od.OrderID
join  customers c on c.CustomerID=o.CustomerID
group by orderid,custregID
) as ordersize
join regions r on r.RegionID=ordersize.custregID
group by RegionName
order by Average_Order_Size desc;


-- 2 Customer Insights
-- Who are the top 10 customers by total revenue spent?
select *from customers;
select c.CustomerID as Customer_id,c.CustomerName as Customer_Name,sum(Quantity*Price) as Total_Revenue from customers c
join orders o on o.CustomerID=c.CustomerID
join orderdetails od on od.OrderID= o.OrderID
join products p on p.ProductID=od.ProductID
group by c.Customer_id,c.Customer_Name order by Total_Revenue desc limit 10;

-- What is the repeat customer rate?
-- Repeat customer rate =(Customers with ≥2 orders/Total customers)*100
SELECT 
    ((COUNT(CASE WHEN Count_order > 1 THEN CustomerID END))/ COUNT(DISTINCT CustomerID)) * 100 AS Repeat_customer_rate
FROM (
    SELECT CustomerID, COUNT(OrderID) AS Count_order FROM orders
    GROUP BY CustomerID
) t;

-- What is the average time between two consecutive orders for the same customer Region-wise?
WITH lag_dates AS (
    SELECT
        c.CustomerID as id,
        r.RegionName AS region,
        o.OrderDate as dates,
        LAG(o.OrderDate) OVER (
            PARTITION BY c.CustomerID, r.RegionName
            ORDER BY o.OrderDate
        ) AS prev_date  FROM orders o
    JOIN customers c ON o.CustomerID = c.CustomerID
    JOIN regions r ON r.RegionID = c.RegionID
)
SELECT id as Customer_ID ,region as Regions,avg(datediff(dates,prev_date)) as Avg_consecutivetime_btw_orders
FROM lag_dates
where prev_date is not null
group by Customer_ID ,Regions;


-- Customer Segment (based on total spend)
-- Platinum: Total Spend > 1500
-- Gold: 1000–1500
-- Silver: 500–999
-- Bronze: < 500
select Customer_id, Customer_Name,Total_Revenue ,case
when Total_Revenue >1500 then 'Platinum'
when  Total_Revenue between 1000 and 1500 then 'Gold'
when Total_Revenue between 500 and 999 then 'Silver'
when Total_Revenue <500 then 'Bronze'
end as   'Customer Segment'
 from( select c.CustomerID as Customer_id,c.CustomerName as Customer_Name,sum(Quantity*Price) as Total_Revenue from customers c
join orders o on o.CustomerID=c.CustomerID
join orderdetails od on od.OrderID= o.OrderID
join products p on p.ProductID=od.ProductID
group by Customer_id,Customer_Name ) t
order by Total_Revenue desc ;

-- What is the customer lifetime value (CLV)?
select c.CustomerID as Customer_id,c.CustomerName as Customer_Name,sum(Quantity*Price) as Total_Revenue from customers c
join orders o on o.CustomerID=c.CustomerID
join orderdetails od on od.OrderID= o.OrderID
join products p on p.ProductID=od.ProductID
group by Customer_id,Customer_Name order by Total_Revenue ;


-- 3 Product & Order Insights
-- What are the top 10 most sold products (by quantity)?
select p.ProductName as Product_name ,count(od.Quantity) as Quantity from orderdetails od
join products p on p.ProductID=od.ProductID
group by  Product_name
order by Quantity desc limit 10;

-- What are the top 10 most sold products (by revenue)?
select p.ProductName as Product_name ,sum(p.Price) as Revenue from orderdetails od
join products p on p.ProductID=od.ProductID
group by  Product_name
order by Revenue desc limit 10;

-- Which products have the highest return rate?  return rate=returned quantity of that product /total quantity of that product
select p.ProductName as Product_Name,round( SUM(CASE WHEN o.IsReturned = 1 THEN od.Quantity ELSE 0 END)
/ SUM(od.Quantity)
 ,2) as Return_Rate from  orderdetails od
join products p on p.ProductID=od.ProductID
join orders o on o.OrderID=od.OrderID
group by  Product_Name order by Return_Rate desc;

-- Return Rate by Category
select p.Category as 
Category,round( SUM(CASE WHEN o.IsReturned = 1 THEN od.Quantity ELSE 0 END)
/ SUM(od.Quantity)
 ,2) as Return_Rate from  orderdetails od
join products p on p.ProductID=od.ProductID
join orders o on o.OrderID=od.OrderID
group by  Category order by Return_Rate desc;

-- What is the average price of products per region?
select  r.RegionName as Region_Name ,round( sum(p.Price * od.Quantity)/ sum(od.Quantity),2) as AVG_Price_perRegion from customers c
join regions r on r.RegionID=c.RegionID
join orders o on o.CustomerID=c.CustomerID
join orderdetails od on od.OrderID=o.OrderID 
join products p on p.ProductID=od.ProductID
group by Region_Name
 order by  AVG_Price_perRegion  desc;

-- What is the sales trend for each product category?
SELECT 
    DATE_FORMAT(OrderDate, "%Y-%m") AS Period,
    Category,
    SUM(OD.Quantity * P.Price) AS Revenue
FROM Orders O
JOIN Orderdetails OD ON OD.OrderId = O.OrderId
JOIN Products P ON P.ProductId = OD.ProductId
GROUP BY Period, Category
ORDER BY Period, Category, Revenue DESC;


-- 4 Temporal Trends
-- What are the monthly sales trends over the past year?
 select p.Category as Category,year(o.OrderDate) as `Year`,month(o.OrderDate) as `month` 
 , sum(p.Price*od.Quantity)  as Total_revenue from orders o
 join orderdetails od on od.OrderID=o.OrderID
 join products p on p.ProductID=od.ProductID 
 where  o.OrderDate>= current_date() - interval 12 month 
 group by Category, `Year`,`month` order by  `Year`,`month`,Total_revenue ;

-- How does the average order value (AOV) change by month or week
SELECT 
    DATE_FORMAT(OrderDate, "%Y-%m") AS Period,
    ROUND(SUM(OD.Quantity * P.Price) / COUNT(DISTINCT O.OrderId), 2) AS AOV
FROM Orders O
JOIN OrderDetails OD ON OD.OrderId = O.OrderId
JOIN Products P ON P.ProductId = OD.ProductId
GROUP BY Period
ORDER BY Period;


-- 5 Regional Insights
-- Which regions have the highest order volume and which have the lowest?
DELIMITER $
CREATE PROCEDURE GetRegionOrderVolume()
BEGIN
    SELECT r.RegionName,COUNT(DISTINCT o.OrderID) AS Order_Volume
    FROM customers c
    JOIN regions r ON r.RegionID = c.RegionID
    JOIN orders o ON o.CustomerID = c.CustomerID
    GROUP BY r.RegionName
    ORDER BY Order_Volume DESC;
END $
DELIMITER ;
call  GetRegionOrderVolume();

-- What is the revenue per region and how does it compare across different regions?
SELECT 
    r.RegionName AS Region,
    ROUND(SUM(p.Price * od.Quantity), 2) AS Total_Revenue
FROM customers c
JOIN regions r ON r.RegionID = c.RegionID
JOIN orders o ON o.CustomerID = c.CustomerID
JOIN orderdetails od ON od.OrderID = o.OrderID
JOIN products p ON p.ProductID = od.ProductID
GROUP BY r.RegionName
ORDER BY Total_Revenue DESC;


-- 6 Return & Refund Insights
-- What is the overall return rate by product category?
SELECT 
    Category,
    ROUND(SUM(CASE WHEN IsReturned = 1 THEN 1 ELSE 0 END) / COUNT(distinct o.OrderId),2) AS ReturnRate
FROM orders o
JOIN orderdetails od ON od.OrderId = o.OrderId
JOIN products p ON p.ProductId = od.ProductId
GROUP BY Category
ORDER BY ReturnRate DESC;

-- What is the overall return rate by region?
SELECT RegionName,
ROUND(SUM(CASE WHEN IsReturned = 1 THEN 1 ELSE 0 END) / COUNT(O.OrderId), 2) AS ReturnRate
FROM orders o
JOIN Customers C ON C.CustomerId = O.CustomerId
JOIN Regions R ON R.RegionId = C.RegionId
GROUP BY RegionName
ORDER BY ReturnRate DESC;

-- Which customers are making frequent returns?
SELECT C.CustomerID, CustomerName, COUNT(O.OrderID) AS ReturnCount
FROM Orders o
JOIN Customers C ON C.CustomerId = O.CustomerId
WHERE IsReturned = 1
GROUP BY C.CustomerID, CustomerName
ORDER BY ReturnCount DESC
LIMIT 10;






