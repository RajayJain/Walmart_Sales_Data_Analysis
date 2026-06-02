-- Walmart Project Queries
SELECT * FROM walmart;


SELECT COUNT(*) FROM walmart;


SELECT 
	 payment_method,
	 COUNT(*)
FROM walmart
GROUP BY payment_method


SELECT 
	COUNT(DISTINCT branch) 
FROM walmart;


SELECT MIN(quantity) FROM walmart;


-- 1. Analyze Payment Methods and Sales
-- ● Question: What are the different payment methods, and how many transactions and items were sold with each method?
-- ● Purpose: This helps understand customer preferences for payment methods, aiding in payment optimization strategies.
SELECT 
	 payment_method,
	 COUNT(*) as no_payments,
	 SUM(quantity) as no_qty_sold
FROM walmart
GROUP BY payment_method


-- 2. Identify the Highest-Rated Category in Each Branch
-- ● Question: Which category received the highest average rating in each branch?
-- ● Purpose: This allows Walmart to recognize and promote popular categories in specific branches, enhancing customer satisfaction and branch-specific marketing.
SELECT * 
FROM
(	SELECT 
		branch,
		category,
		AVG(rating) as avg_rating,
		RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) as rank
	FROM walmart
	GROUP BY 1, 2
)
WHERE rank = 1


-- 3. Determine the Busiest Day for Each Branch
-- ● Question: What is the busiest day of the week for each branch based on transaction volume?
-- ● Purpose: This insight helps in optimizing staffing and inventory management to accommodate peak days.
SELECT * 
FROM
	(SELECT 
		branch,
		TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'Day') as day_name,
		COUNT(*) as no_transactions,
		RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) as rank
	FROM walmart
	GROUP BY 1, 2
	)
WHERE rank = 1


-- 4. Calculate Total Quantity Sold by Payment Method
-- ● Question: How many items were sold through each payment method?
-- ● Purpose: This helps Walmart track sales volume by payment type, providing insights into customer purchasing habits.
SELECT 
	 payment_method,
	 -- COUNT(*) as no_payments,
	 SUM(quantity) as no_qty_sold
FROM walmart
GROUP BY payment_method


-- 5. Analyze Category Ratings by City
-- ● Question: What are the average, minimum, and maximum ratings for each category in each city?
-- ● Purpose: This data can guide city-level promotions, allowing Walmart to address regional preferences and improve customer experiences.
SELECT 
	city,
	category,
	MIN(rating) as min_rating,
	MAX(rating) as max_rating,
	AVG(rating) as avg_rating
FROM walmart
GROUP BY 1, 2


-- 6. Calculate Total Profit by Category
-- ● Question: What is the total profit for each category, ranked from highest to lowest?
-- ● Purpose: Identifying high-profit categories helps focus efforts on expanding these products or managing pricing strategies effectively.
SELECT 
	category,
	SUM(total) as total_revenue,
	SUM(total * profit_margin) as profit
FROM walmart
GROUP BY 1


-- 7. Determine the Most Common Payment Method per Branch
-- ● Question: What is the most frequently used payment method in each branch?
-- ● Purpose: This information aids in understanding branch-specific payment preferences, potentially allowing branches to streamline their payment processing systems.
WITH cte 
AS
(SELECT 
	branch,
	payment_method,
	COUNT(*) as total_trans,
	RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) as rank
FROM walmart
GROUP BY 1, 2
)
SELECT *
FROM cte
WHERE rank = 1


-- 8. Analyze Sales Shifts Throughout the Day
-- ● Question: How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
-- ● Purpose: This insight helps in managing staff shifts and stock replenishment schedules, especially during high-sales periods.
SELECT
	branch,
CASE 
		WHEN EXTRACT(HOUR FROM(time::time)) < 12 THEN 'Morning'
		WHEN EXTRACT(HOUR FROM(time::time)) BETWEEN 12 AND 17 THEN 'Afternoon'
		ELSE 'Evening'
	END day_time,
	COUNT(*)
FROM walmart
GROUP BY 1, 2
ORDER BY 1, 3 DESC


-- 9. Identify Branches with Highest Revenue Decline Year-Over-Year
-- ● Question: Which branches experienced the largest decrease in revenue compared to the previous year?
-- ● Purpose: Detecting branches with declining revenue is crucial for understanding possible local issues and creating strategies to boost sales or mitigate losses
WITH revenue_2022
AS
(
	SELECT 
		branch,
		SUM(total) as revenue
	FROM walmart
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2022 -- psql
	-- WHERE YEAR(TO_DATE(date, 'DD/MM/YY')) = 2022 -- mysql
	GROUP BY 1
),

revenue_2023
AS
(

	SELECT 
		branch,
		SUM(total) as revenue
	FROM walmart
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2023
	GROUP BY 1
)

SELECT 
	ls.branch,
	ls.revenue as last_year_revenue,
	cs.revenue as current_year_revenue,
	ROUND(
		(ls.revenue - cs.revenue)::numeric/
		ls.revenue::numeric * 100, 
		2) as Revenue_Decrease_Ratio
FROM revenue_2022 as ls
JOIN
revenue_2023 as cs
ON ls.branch = cs.branch
WHERE 
	ls.revenue > cs.revenue
ORDER BY 4 DESC
LIMIT 5
