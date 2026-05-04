-- =========================================
-- Queries to create the tables
-- =========================================

-- 1. Customers Table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    city VARCHAR(50),
    state VARCHAR(50),
    signup_date DATE,
    customer_segment VARCHAR(50)
);

-- 2. Products Table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255),
    category VARCHAR(100),
    subcategory VARCHAR(100),
    unit_price NUMERIC(15, 2),
    stock_quantity INT,
    supplier VARCHAR(150)
);

-- 3. Employees Table (with Self-Reference)
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    hire_date DATE,
    salary NUMERIC(15, 2),
    manager_id INT REFERENCES employees(employee_id),
    city VARCHAR(50)
);

-- 4. Orders Table (Depends on Customers and Employees)
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    employee_id INT REFERENCES employees(employee_id),
    order_date DATE,
    status VARCHAR(50),
    payment_method VARCHAR(50),
    shipping_state VARCHAR(50)
);

-- 5. Order Items Table (Depends on Orders and Products)
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT,
    unit_price NUMERIC(15, 2),
    discount NUMERIC(15, 2) DEFAULT 0
);


-- =========================================
-- Q1. Where is the business concentrated?
-- =========================================
-- Management suspects the business depends too heavily on a single state...

SELECT 
    state,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_total
FROM customers
GROUP BY state
ORDER BY customer_count DESC
LIMIT 1;

-- Approach: Aggregated customers by state and used a window SUM to compute total customers.
-- Percentage represents each state's share of the total base.


-- =========================================
-- Q2. The silent customers
-- =========================================
-- Find every customer who has never placed a single order...

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    c.signup_date,
    c.customer_segment
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.signup_date ASC;

-- Approach: Used LEFT JOIN with IS NULL to identify customers with no matching orders.
-- Chosen for readability over NOT EXISTS given dataset size.


-- =========================================
-- Q3. Stock health check — with a twist
-- =========================================
-- List products that are in danger of running out...

WITH product_sales AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        p.stock_quantity,
        p.supplier,
        COALESCE(SUM(oi.quantity), 0) AS total_sold
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.product_name, p.category, p.stock_quantity, p.supplier
)
SELECT 
    product_name,
    category,
    stock_quantity,
    supplier
FROM product_sales
WHERE stock_quantity < total_sold * 0.5
ORDER BY stock_quantity ASC;

-- Approach: Defined “at risk” as stock less than 50% of total historical demand, using sales as a proxy for velocity.
-- Avoided arbitrary thresholds like stock < 20 since they ignore demand patterns.


-- =========================================
-- Q4. Defining your "best" customer
-- =========================================

WITH order_values AS (
    SELECT 
        o.order_id,
        o.customer_id,
        o.employee_id,
        o.order_date,
        SUM(
            GREATEST((oi.quantity * oi.unit_price) - oi.discount, 0)
        ) AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id, o.employee_id, o.order_date
),
customer_spend AS (
    SELECT 
        customer_id,
        SUM(order_value) AS total_spend
    FROM order_values
    GROUP BY customer_id
)
SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    c.state,
    c.customer_segment,
    cs.total_spend
FROM customer_spend cs
JOIN customers c ON cs.customer_id = c.customer_id
ORDER BY cs.total_spend DESC
LIMIT 1;

-- Approach: Defined “best customer” as highest lifetime spend since it directly reflects total revenue contribution.
-- Metrics like order count or recency were rejected as they fail to capture monetary value and overall business impact.


-- =========================================
-- Q5. One-and-done vs repeat buyers
-- =========================================

WITH order_values AS (
    SELECT 
        o.order_id,
        o.customer_id,
        SUM(GREATEST((oi.quantity * oi.unit_price) - oi.discount, 0)) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id
),
customer_summary AS (
    SELECT 
        customer_id,
        COUNT(*) AS order_count,
        SUM(revenue) AS total_spend
    FROM order_values
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'one-and-done'
        ELSE 'repeat'
    END AS customer_type,
    COUNT(*) AS num_customers,
    SUM(total_spend) AS total_revenue,
    AVG(total_spend) AS avg_spend_per_customer
FROM customer_summary
GROUP BY customer_type;

-- Approach: Classified customers using CASE based on order count and aggregated spend metrics per group.
-- Used a single grouped query instead of UNION for efficiency.

-- =========================================
-- Q6. The dormant VIPs
-- =========================================

WITH order_values AS (
    SELECT 
        o.order_id,
        o.customer_id,
        o.order_date,
        SUM(GREATEST((oi.quantity * oi.unit_price) - oi.discount, 0)) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id, o.order_date
),
customer_stats AS (
    SELECT 
        customer_id,
        SUM(revenue) AS lifetime_spend,
        MAX(order_date) AS last_order_date
    FROM order_values
    GROUP BY customer_id
),
today AS (
    SELECT MAX(order_date) AS max_date FROM orders
)
SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    cs.lifetime_spend,
    cs.last_order_date,
    (t.max_date - cs.last_order_date) AS days_since_last_order
FROM customer_stats cs
JOIN customers c ON cs.customer_id = c.customer_id
CROSS JOIN today t
WHERE cs.lifetime_spend >= 500000
  AND (t.max_date - cs.last_order_date) > 180
ORDER BY cs.lifetime_spend DESC;

-- Approach: Calculated lifetime spend and last order date per customer, using dataset max date as “today”.
-- Filtered for high-value but inactive customers to identify churn risk.


-- =========================================
-- Q7. The 80/20 rule in action
-- =========================================

WITH product_revenue AS (
    SELECT 
        p.product_name,
        SUM(GREATEST((oi.quantity * oi.unit_price) - oi.discount, 0)) AS revenue
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_name
),
ranked AS (
    SELECT 
        product_name,
        revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC) AS cumulative_revenue,
        SUM(revenue) OVER () AS total_revenue
    FROM product_revenue
)
SELECT 
    product_name,
    revenue,
    cumulative_revenue,
    ROUND(100.0 * cumulative_revenue / total_revenue, 2) AS cumulative_pct,
    (cumulative_revenue <= 0.8 * total_revenue) AS is_top_80
FROM ranked;

-- Approach: Ranked products by revenue and computed cumulative contribution using window functions.
-- 9 products (~22.5% of the catalog) were required to reach 80% of total revenue, indicating the Pareto principle largely holds for this business.


-- =========================================
-- Q8. What gets bought together?
-- =========================================

SELECT 
    p1.product_name AS product_a,
    p2.product_name AS product_b,
    COUNT(DISTINCT oi1.order_id) AS order_count
FROM order_items oi1
JOIN order_items oi2 
    ON oi1.order_id = oi2.order_id
    AND oi1.product_id < oi2.product_id
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
GROUP BY p1.product_name, p2.product_name
ORDER BY order_count DESC
LIMIT 3;

-- Approach: Self-joined order_items on order_id and enforced product_id < condition to avoid duplicates.
-- Counted distinct orders to measure co-purchase frequency.


-- =========================================
-- Q9. Sales rep scorecard
-- =========================================

WITH order_values AS (
    SELECT 
        o.order_id,
        o.employee_id,
        SUM(GREATEST((oi.quantity * oi.unit_price) - oi.discount, 0)) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.employee_id
)
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    COUNT(ov.order_id) AS num_orders,
    COALESCE(SUM(ov.revenue), 0) AS total_revenue,
    COALESCE(AVG(ov.revenue), 0) AS avg_order_value,
    COALESCE(
        SUM(ov.revenue) / NULLIF(SUM(SUM(ov.revenue)) OVER (), 0),
        0
    ) AS revenue_pct
FROM employees e
LEFT JOIN order_values ov ON e.employee_id = ov.employee_id
WHERE e.department = 'Sales'
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_revenue DESC;

-- Approach: Used LEFT JOIN to retain employees with zero orders and COALESCE to replace NULLs.
-- Window function computes each rep’s contribution to total team revenue.


-- =========================================
-- Q10. Suspicious orders
-- =========================================

WITH order_values AS (
    SELECT 
        o.order_id,
        o.customer_id,
        o.order_date,
        SUM(GREATEST((oi.quantity * oi.unit_price) - oi.discount, 0)) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id, o.order_date
),
customer_avg AS (
    SELECT 
        customer_id,
        AVG(revenue) AS avg_order_value,
        COUNT(*) AS order_count
    FROM order_values
    GROUP BY customer_id
) 
SELECT 
    ov.order_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    ov.order_date,
    ov.revenue AS this_order_value,
    ca.avg_order_value,
    (ov.revenue / ca.avg_order_value) AS multiplier
FROM order_values ov
JOIN customer_avg ca ON ov.customer_id = ca.customer_id
JOIN customers c ON ov.customer_id = c.customer_id
WHERE ca.order_count >= 3
  AND ov.revenue >= 5 * ca.avg_order_value
ORDER BY multiplier DESC;

-- Approach: Computed per-customer average order value and compared each order against it.
-- Filtered to customers with sufficient history to ensure meaningful anomaly detection.