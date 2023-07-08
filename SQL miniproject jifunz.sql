-- QUESTION 1:Provide the top 10 customers (full name) by revenue, the country they shipped to, the cities and 
-- their revenue (orderqty * unitprice).
By identifying the top revenue-generating customers, the marketing team can gain insights into the most valuable customers in terms of their purchasing power. 
This information allows them to prioritize their efforts and allocate resources towards retaining and nurturing these high-revenue customers. 
The team can design personalized loyalty programs, tailored offers, exclusive rewards, or targeted marketing campaigns to strengthen customer loyalty, 
enhance the customer experience, and potentially increase customer lifetime value. Additionally, 
understanding the shipping country and city of these top customers can provide valuable geographic insights,
enabling the marketing team to focus on specific regions or tailor marketing efforts to reach similar customer segments in other areas.


SELECT TOP 10
    CONCAT(c.FirstName, ' ', c.MiddleName, ' ', c.LastName) AS FullName,
    a.CountryRegion AS Country, 
	a.City AS City,
    SUM(sod.OrderQty * sod.UnitPrice) AS Revenue
FROM SalesLT.Customer c
JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN SalesLT.CustomerAddress ca ON c.CustomerID = ca.CustomerID
JOIN SalesLT.[Address] a ON ca.AddressID = a.AddressID
JOIN SalesLT.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY c.FirstName, c.MiddleName, c.LastName, a.CountryRegion, a.City
ORDER BY Revenue DESC;



-- QUESTION 2: Create 4 distinct Customer segments using the total Revenue (orderqty * unitprice) by customer. 
-- List the customer details (ID, Company Name), Revenue and the segment the customer belongs to. 
-- This analysis can use to create a loyalty program, market customers with discount or leave customers as-is.
SELECT c.CustomerID, c.CompanyName, SUM(sod.OrderQty * sod.UnitPrice) AS 'Total Revenue',
    CASE 
        WHEN SUM(sod.OrderQty * sod.UnitPrice) >= 50000 THEN 'High Patronage'
        WHEN SUM(sod.OrderQty * sod.UnitPrice) >= 25000 THEN 'Averagely high Patronage'
        WHEN SUM(sod.OrderQty * sod.UnitPrice) >= 10000 THEN 'Averagely Low Patronage'
        WHEN SUM(sod.OrderQty * sod.UnitPrice) < 10000 THEN 'Low Patronage'
		
    END AS CustomerSegment
FROM SalesLT.Customer c
JOIN SalesLT.SalesOrderHeader soh ON soh.CustomerID = c.CustomerID
JOIN SalesLT.SalesOrderDetail sod ON sod.SalesOrderID = soh.SalesOrderID
GROUP BY c.CustomerID, c.CompanyName
ORDER BY 'Total Revenue' DESC;



--QUESTION 3: What products with their respective categories did our customers buy on our last day of business?
-- List the CustomerID, Product ID, Product Name, Category Name and Order Date.
-- This insight will help understand the latest products and categories that your customers bought from. This will help
-- you do near-real-time marketing and stockpiling for these products.



SELECT soh.CustomerID, p.ProductID, p.[Name] AS ProductName, pc.[Name] AS CategoryName, soh.OrderDate
FROM SalesLT.SalesOrderHeader soh
join SalesLT.SalesOrderDetail sod 
on sod.SalesOrderID = soh.SalesOrderID
join SalesLT.Product p
on sod.ProductID = p.productID
join SalesLT.ProductCategory pc
on pc.ProductCategoryID = p.ProductCategoryID
where soh.OrderDate = (select MAX(OrderDate) FROM SalesLT.SalesOrderHeader)


-- Question 4: Create a View called customersegment that stores the details (id, name, revenue) for customers
-- and their segment? i.e. build a view for Question 2.
-- You can connect this view to Tableau and get insights without needing to write the same query every time.

CREATE VIEW CustomerSegment AS
SELECT c.CustomerID, c.CompanyName, SUM(sod.OrderQty * sod.UnitPrice) AS Revenue,
    CASE 
        WHEN SUM(sod.OrderQty * sod.UnitPrice) >= 50000 THEN 'High Patronage'
        WHEN SUM(sod.OrderQty * sod.UnitPrice) >= 25000 THEN 'Averagely high Patronage'
        WHEN SUM(sod.OrderQty * sod.UnitPrice) >= 10000 THEN 'Averagely Low Patronage'
        WHEN SUM(sod.OrderQty * sod.UnitPrice) < 10000 THEN 'Low Patronage'
    END AS CustomerSegment
FROM SalesLT.Customer c
JOIN SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN SalesLT.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY c.CustomerID, c.CompanyName;


-- Question 5: What are the top 3 selling product (include productname) in each category (include categoryname)
-- by revenue? Tip: Use ranknum
-- This analysis will ensure you can keep track of your top selling products in each category. The output is very
-- powerful because you don't have to write multiple queries to be able to see your top selling products in each category.
-- This analysis will inform your marketing, your supply chain, your partnerships, position of products on your website, etc.
-- NB: This question is asked a lot in interviews!

SELECT CategoryName, ProductName, Revenue
FROM (
    SELECT pc.Name AS CategoryName, p.Name AS ProductName, 
           SUM(sod.OrderQty * sod.UnitPrice) AS Revenue,
           RANK() OVER (PARTITION BY pc.Name ORDER BY SUM(sod.OrderQty * sod.UnitPrice) DESC) AS RankNum
    FROM SalesLT.SalesOrderDetail sod
    JOIN SalesLT.Product p ON sod.ProductID = p.ProductID
    JOIN SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
    GROUP BY pc.Name, p.Name
) ranked
WHERE RankNum <= 3;
