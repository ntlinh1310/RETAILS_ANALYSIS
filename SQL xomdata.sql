--Q1: TỔNG DOANH THU THEO TỪNG NĂM và cộng dồn
with yearly_revenue as(
SELECT 
	YEAR(order_date) as Year,
	SUM(quantity*unit_price_usd) as total_revenue
FROM retails.sales as s
LEFT JOIN retails.products AS P
ON S.product_key = p.product_key
GROUP BY YEAR(order_date)
)
SELECT year,
	total_revenue,
	SUM(total_revenue) OVER(ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
FROM yearly_revenue
ORDER BY year

--Q2: LỢI NHUẬN từng năm và cộng dồn
with yearly_profit as(
SELECT 
	YEAR(order_date) as Year,
	SUM(quantity*(unit_price_usd -unit_cost_usd)) as total_profit
FROM retails.sales as s
LEFT JOIN retails.products AS P
ON S.product_key = p.product_key
GROUP BY YEAR(order_date)
)
SELECT 
	Year,
	total_profit,
	SUM(total_profit) OVER(ORDER BY Year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM yearly_profit
ORDER BY total_profit DESC
--Q3: MỨC TĂNG TRƯỞNG DOANH THU
WITH yearly_revenue AS (

    SELECT
        YEAR(s.order_date) AS order_year,

        SUM(
            s.quantity * p.unit_price_usd
        ) AS total_revenue

    FROM retails.sales s

    JOIN retails.products p
        ON s.product_key = p.product_key

    GROUP BY YEAR(s.order_date)
)

SELECT
    order_year,

    total_revenue,

    LAG(total_revenue) OVER (
        ORDER BY order_year
    ) AS previous_year_revenue,

    ROUND(
        100.0 *
        (
            total_revenue
            - LAG(total_revenue) OVER (
                ORDER BY order_year
            )
        )

        /

        LAG(total_revenue) OVER (
            ORDER BY order_year
        ),
        2
    ) AS revenue_growth_pct

FROM yearly_revenue

ORDER BY order_year;

--Q4: SỐ LƯỢNG ĐƠN ĐẶT HÀNG THEO TỪNG QUÝ CỦA MỖI NĂM
with quarterly_order as(
SELECT
    YEAR(order_date) AS order_year,

    DATEPART(QUARTER, order_date) AS quarter_num,

    COUNT(DISTINCT order_number) AS total_orders

FROM retails.sales

GROUP BY
    YEAR(order_date),
    DATEPART(QUARTER, order_date)
)
SELECT
    order_year,

    CONCAT('Q', quarter_num) AS quarter_name,

    total_orders,

    SUM(total_orders) OVER (
        ORDER BY
            order_year,
            quarter_num

        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS cumulative_orders

FROM quarterly_order

ORDER BY
    order_year,
    quarter_num;

--Q5: doanh thu theo quý
SELECT
    YEAR(s.order_date) AS order_year,

    DATEPART(QUARTER, s.order_date) AS quarter_num,

    SUM(
        s.quantity * p.unit_price_usd
    ) AS total_revenue

FROM retails.sales s

JOIN retails.products p
    ON s.product_key = p.product_key

GROUP BY
    YEAR(s.order_date),
    DATEPART(QUARTER, s.order_date)

ORDER BY
    order_year,
    quarter_num;
--Q6: DOANH THU CỦA CÁC THÁNG TRONG 2020 (GIẢM ĐỘT NGỘT)
SELECT 
    MONTH(order_date) as month_num,
	SUM(quantity*unit_price_usd) as total_revenue
FROM retails.sales as s
LEFT JOIN retails.products AS P
ON S.product_key = p.product_key
WHERE  YEAR(order_date) =2020
GROUP BY  MONTH(order_date)
ORDER BY month_num
--Q7: ĐƠN ĐẶT HÀNG CỦA TỪNG THÁNG 2020
SELECT 
    MONTH(order_date) as month_num,
	COUNT(DISTINCT(order_number)) as total_orders
FROM retails.sales as s
LEFT JOIN retails.products AS P
ON S.product_key = p.product_key
WHERE  YEAR(order_date) =2019
GROUP BY  MONTH(order_date)
ORDER BY month_num

--Q8: KHÁCH HÀNG MỚI VÀ CŨ 

WITH customer_orders AS (

    SELECT
        YEAR(order_date) AS order_year,

        customer_key,

        COUNT(DISTINCT order_number) AS total_orders

    FROM retails.sales

    GROUP BY
        YEAR(order_date),
        customer_key
)

SELECT
    order_year,

    customer_key,

    total_orders,

    CASE

        WHEN total_orders = 1
            THEN 'New Customer'

        ELSE 'Returning Customer'

    END AS customer_type

FROM customer_orders

--Q9: ĐƠN HÀNG CỦA KHÁCH HÀNG MỚI VÀ CŨ
WITH customer_year_orders AS (

    SELECT
        YEAR(order_date) AS order_year,

        customer_key,

        COUNT(DISTINCT order_number) AS total_orders

    FROM retails.sales

    GROUP BY
        YEAR(order_date),
        customer_key
),

customer_segment AS (

    SELECT
        order_year,

        customer_key,

        total_orders,

        CASE

            WHEN total_orders = 1
            THEN 'New Customer'

            ELSE 'Returning Customer'

        END AS customer_type

    FROM customer_year_orders
)

SELECT
    order_year,

    customer_type,

    SUM(total_orders) AS total_order_count

FROM customer_segment

GROUP BY
    order_year,
    customer_type

ORDER BY
    order_year,
    customer_type;

--q10: doanh thu theo thị trường các nước

--- tổng doanh thu của các nước
SELECT
    c.country,

    SUM(
        s.quantity * p.unit_price_usd
    ) AS total_revenue

FROM retails.sales s

JOIN retails.products p
    ON s.product_key = p.product_key

JOIN retails.customers c
    ON s.customer_key = c.customer_key

GROUP BY c.country

ORDER BY total_revenue DESC;
--- doanh thu theo từng năm của từng nước, tăng trưởng theo từng năm của mỗi nước

WITH market_revenue AS (

    SELECT
        YEAR(s.order_date) AS order_year,

        c.country,

        SUM(
            s.quantity * p.unit_price_usd
        ) AS total_revenue

    FROM retails.sales s

    JOIN retails.products p
        ON s.product_key = p.product_key

    JOIN retails.customers c
        ON s.customer_key = c.customer_key

    GROUP BY
        YEAR(s.order_date),
        c.country
)

SELECT
    order_year,

    country,

    total_revenue,

    LAG(total_revenue) OVER (
        PARTITION BY country
        ORDER BY order_year
    ) AS previous_year_revenue,

    ROUND(
        100.0 *

        (
            total_revenue
            - LAG(total_revenue) OVER (
                PARTITION BY country
                ORDER BY order_year
            )
        )

        /

        LAG(total_revenue) OVER (
            PARTITION BY country
            ORDER BY order_year
        ),
        2
    ) AS revenue_growth_pct

FROM market_revenue

ORDER BY
    country,
    order_year;

--Q11: phân loại khách hàng theo từng thị trường từng năm
WITH first_purchase AS (

    SELECT
        customer_key,

        MIN(YEAR(order_date)) AS first_purchase_year

    FROM retails.sales

    GROUP BY customer_key
),

customer_market AS (

    SELECT DISTINCT
        YEAR(s.order_date) AS order_year,

        c.country,

        s.customer_key,

        CASE
            WHEN YEAR(s.order_date)
                 = fp.first_purchase_year
            THEN 'New Customer'

            ELSE 'Returning Customer'
        END AS customer_type

    FROM retails.sales s

    JOIN retails.customers c
        ON s.customer_key = c.customer_key

    JOIN first_purchase fp
        ON s.customer_key = fp.customer_key
),

customer_summary AS (

    SELECT
        order_year,

        country,

        customer_type,

        COUNT(DISTINCT customer_key) AS total_customers

    FROM customer_market

    GROUP BY
        order_year,
        country,
        customer_type
)

SELECT
    order_year,

    country,

    customer_type,

    total_customers,

    LAG(total_customers) OVER (
        PARTITION BY
            country,
            customer_type

        ORDER BY order_year
    ) AS previous_year_customers,

    ROUND(
        100.0 *

        (
            total_customers
            - LAG(total_customers) OVER (
                PARTITION BY
                    country,
                    customer_type

                ORDER BY order_year
            )
        )

        /

        LAG(total_customers) OVER (
            PARTITION BY
                country,
                customer_type

            ORDER BY order_year
        ),
        2
    ) AS customer_growth_pct

FROM customer_summary

ORDER BY
    country,
    customer_type,
    order_year;

--Q13: SỐ LƯỢNG ĐƠN ĐẶT HÀNG VÀ DOANH THU TỪNG MẶT HÀNG THEO TỪNG NĂM
WITH category_summary AS (

    SELECT
        YEAR(s.order_date) AS order_year,

        p.category,

        COUNT(DISTINCT s.order_number) AS total_orders,

        SUM(
            s.quantity * p.unit_price_usd
        ) AS total_revenue

    FROM retails.sales s

    JOIN retails.products p
        ON s.product_key = p.product_key

    GROUP BY
        YEAR(s.order_date),
        p.category
)

SELECT
    order_year,

    category,

    total_orders,

    total_revenue,

    LAG(total_revenue) OVER (
        PARTITION BY category
        ORDER BY order_year
    ) AS previous_year_revenue,

    ROUND(
        100.0 *

        (
            total_revenue
            - LAG(total_revenue) OVER (
                PARTITION BY category
                ORDER BY order_year
            )
        )

        /

        LAG(total_revenue) OVER (
            PARTITION BY category
            ORDER BY order_year
        ),
        2
    ) AS revenue_growth_pct

FROM category_summary

ORDER BY
    category,
    order_year;

--Q14: phân loại các loại hình cửa hàng theo square_meters:
SELECT
    store_key,
    state,
    square_meters,

    CASE

        WHEN square_meters < 500
            THEN 'Compact'

        WHEN square_meters >= 500
             AND square_meters < 1000
            THEN 'Standard'

        WHEN square_meters >= 1000
             AND square_meters < 1500
             THEN 'Mall Center'
        WHEN square_meters >= 1500 
     THEN 'Flagship'

        ELSE 'Online'

    END AS store_type

FROM retails.stores

--KH MỚI VÀ CŨ
WITH first_purchase AS (

    SELECT
        customer_key,

        MIN(YEAR(order_date)) AS first_purchase_year

    FROM retails.sales

    GROUP BY customer_key
),

customer_year_orders AS (

    SELECT
        YEAR(order_date) AS order_year,

        customer_key,

        COUNT(DISTINCT order_number) AS total_orders

    FROM retails.sales

    GROUP BY
        YEAR(order_date),
        customer_key
)

SELECT
    cyo.order_year,

    CASE

        WHEN cyo.order_year = fp.first_purchase_year
            THEN 'New Customer'

        ELSE 'Returning Customer'

    END AS customer_type,

    COUNT(DISTINCT cyo.customer_key) AS total_customers,

    SUM(cyo.total_orders) AS total_orders

FROM customer_year_orders cyo

JOIN first_purchase fp
    ON cyo.customer_key = fp.customer_key

GROUP BY
    cyo.order_year,

    CASE

        WHEN cyo.order_year = fp.first_purchase_year
            THEN 'New Customer'

        ELSE 'Returning Customer'

    END

ORDER BY
    cyo.order_year


--Q1: tổng hợp nhanh giúp anh: năm 2021 mình bán được bao nhiêu đơn hàng trên toàn chain? 
SELECT COUNT(DISTINCT order_number)
FROM retails.sales
WHERE YEAR(order_date) = 2019;
SELECT * FROM retails.stores
--Q2: liệt kê các category và đếm số lượng theo sku
SELECT
    category,
    COUNT(DISTINCT product_key) AS sku_count
FROM retails.products
GROUP BY category
ORDER BY category ASC;

--Q3:TOP 10 thành phố có nhiều khách hành nhất (tên city, state, country, và số lượng customer)
SELECT *
FROM retails.products

SELECT TOP 10 city, state_code, country, COUNT(DISTINCT(customer_key)) AS count_customer
FROM retails.customers
GROUP BY city, state_code, country
ORDER BY count_customer DESC

--Q4:  tổng doanh thu tháng 12/2022(ko có data thánh 12 nên tính đến 2/2021) trên toàn bộ stores — là số tiền khách đã trả (giá bán × số lượng), không phải lợi nhuận
SELECT order_date
FROM retails.sales
where YEAR(order_date) = 2020

SELECT 
    SUM(unit_price_usd * quantity) as Total_Revenue
FROM retails.products as RP
LEFT JOIN retails.sales as RS
ON RP .product_key = RS .product_key
WHERE YEAR(order_date) = 2021
AND MONTH(order_date) = 2

--Q5: có bao nhiêu store ở từng quốc gia vậy em? Cho anh 1 bảng đơn giản: country + số store. Sắp theo số store giảm dần 
SELECT country, COUNT(store_key) as count_store
FROM retails.stores
GROUP BY country
ORDER BY count_store DESC

--Q6: TOP 5 SẢN PHẨM CỦA MỖI CATEGORY CÓ SỐ LƯỢNG BÁN NHIỀU NHẤT
with product_sales AS (
SELECT 
    category,
    product_name,
    SUM(quantity) as total_quantity_sold
    
FROM retails.products as RP
LEFT JOIN retails.sales as RS
ON RP . product_key = RS.product_key
GROUP BY
    category,
    product_name
),
RANK_PRODCUTS AS(
SELECT
   category,
   product_name,
   total_quantity_sold,
   RANK() OVER (
            PARTITION BY category
            ORDER BY total_quantity_sold DESC
        ) AS product_rank
FROM product_sales
)

SELECT
    category,
    product_name,
    total_quantity_sold,
    product_rank
FROM RANK_PRODCUTS
WHERE product_rank <=5
ORDER BY
    category ASC,
    total_quantity_sold ASC

--Q7: margin gross trung bình của subcategory 
SELECT
   subcategory_key,
    
    AVG(
        (unit_price_usd - unit_cost_usd)
        / unit_price_usd
    ) * 100 AS avg_margin_pct,
    
    COUNT(DISTINCT product_key) AS product_count

FROM retails.products

GROUP BY  subcategory_key

HAVING COUNT(DISTINCT product_key) >= 10

ORDER BY avg_margin_pct DESC;

--Q8: THỜI GIAN GIAO HÀNG TRUNG BÌNH THEO QUỐC GIA
select * from retails.sales
SELECT
    country,
    
    COUNT(*) AS delivered_order,
    
    AVG(
        DATEDIFF(
            DAY,
            RS.order_date,
            RS.delivery_date
        )
    ) AS avg_delivery_days

FROM retails.sales AS RS

JOIN retails.customers AS RC
    ON RS.customer_key = RC.customer_key

WHERE RS.delivery_date IS NOT NULL

GROUP BY RC.country

ORDER BY avg_delivery_days DESC;

--Q9: Khách hành VIP của mỗi Quốc gia (người có chi tiêu nhiều nhất cho của mỗi quốc gia)
select * from retails.products

with customer_spending AS(
SELECT 
    country,
    name,
    SUM(unit_price_usd *  quantity) AS total_spend_2020
FROM retails.products AS RP
LEFT JOIN retails.sales AS RS
ON RP . product_key = RS . product_key
LEFT JOIN retails.customers AS RC
ON RS . customer_key = RC . customer_key
WHERE YEAR(order_date) = 2020
GROUP BY 
    country,
    name
),
RANK_CUSTOMERS AS(
SELECT 
    country,
    name,
    total_spend_2020,
    RANK() OVER (
            PARTITION BY country
            ORDER BY total_spend_2020 DESC
        ) AS customer_rank
FROM customer_spending 
)
SELECT
    country,
    name,
    total_spend_2020
FROM RANK_CUSTOMERS
WHERE customer_rank = 1

ORDER BY total_spend_2020 DESC;

--Q10: Sản phẩm zombie (chưa từng được bán) có trong bảng product nhưng ko có trong bảng sale

SELECT
    RP.product_key,
    product_name,
    brand,
    category,
    unit_price_usd

FROM retails.products as RP

LEFT JOIN retails.sales as RS
    ON RP.product_key = RS.product_key

WHERE RS.product_key IS NULL;
select * from retails.sales

--Q11:DOANH THU THÁNG + DOANH THU TÍCH LŨY 24 THÁNG
DECLARE @max_orderdate DATE
SELECT @max_orderdate = MAX(order_date) FROM retails.sales;
with monthly_revenue AS (
    SELECT
        DATEFROMPARTS(
            YEAR(order_date),
            MONTH(order_date),
            1
        ) AS month_start,

        SUM(
            quantity * unit_price_usd
        ) AS monthly_revenue

    FROM retails.sales s

    JOIN retails.products p
        ON s.product_key = p.product_key

    WHERE order_date >= DATEADD(MONTH, -24, @max_orderdate)

    GROUP BY
        DATEFROMPARTS(
            YEAR(order_date),
            MONTH(order_date),
            1
        )
)

SELECT
    FORMAT(month_start, 'yyyy-MM') AS year_month,

    monthly_revenue,

    SUM(monthly_revenue) OVER (
        ORDER BY month_start
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS cumulative_revenue

FROM monthly_revenue

ORDER BY month_start;
