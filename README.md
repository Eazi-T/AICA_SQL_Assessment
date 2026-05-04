# 📊 SQL E-Commerce Analytics Assessment (PostgreSQL)

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-blue?style=for-the-badge&logo=postgresql)
![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)
![Level](https://img.shields.io/badge/Level-Advanced-red?style=for-the-badge)
![Focus](https://img.shields.io/badge/Focus-Data%20Analytics-purple?style=for-the-badge)

---

## 📌 Overview

This project is an end-to-end **SQL analytics case study** on a Nigerian e-commerce dataset. It demonstrates advanced PostgreSQL techniques to solve real-world business problems across:

- Customer analytics  
- Sales performance  
- Inventory risk  
- Revenue concentration  
- Fraud/anomaly detection  

The goal is to translate raw transactional data into **actionable business insights**.

---

## 🗂️ Dataset Structure

The dataset consists of five relational tables:

| Table | Records | Description |
|------|--------|-------------|
| customers | 150 | Customer information |
| products | 40 | Product catalog |
| employees | 20 | Staff details |
| orders | 293 | Order headers |
| order_items | 651 | Transaction line items |

---

## 🧠 Entity Relationship (ER Diagram)

customers ───< orders ───< order_items >─── products
│
└── employees


---

## 📊 Key Business Problems Solved

### 1. 📍 Customer Concentration
Identified the dominant state driving customer acquisition.

### 2. 💤 Silent Customers
Detected customers with zero purchase activity.

### 3. 📦 Inventory Risk Analysis
Flagged products at risk of stock depletion using demand-based logic.

### 4. 🏆 Best Customer Identification
Ranked customers based on lifetime revenue contribution.

### 5. 🔁 Customer Segmentation
- One-and-done buyers  
- Repeat customers  

### 6. 💎 VIP Churn Detection
Identified high-value customers with long inactivity periods.

### 7. 📈 Pareto (80/20) Analysis
Measured revenue concentration across top-performing products.

### 8. 🛒 Market Basket Analysis
Discovered product pairs frequently bought together.

### 9. 👨‍💼 Sales Performance Scorecard
Evaluated employee performance using revenue and order metrics.

### 10. 🚨 Fraud / Anomaly Detection
Flagged unusually large transactions compared to customer behavior baseline.

---

## 🛠️ Tools & SQL Techniques

- PostgreSQL
- CTEs (Common Table Expressions)
- Window Functions
- Self Joins
- Aggregations
- CASE WHEN logic
- Business metric engineering
- Anomaly detection logic

---

## 📈 Key Insights

- Revenue follows a **strong Pareto distribution** (small % of products generate most revenue).
- A small customer base drives a disproportionate share of revenue.
- Several high-value customers show **early churn signals**.
- Clear product pairings exist for **bundling and recommendation systems**.
- Outlier orders suggest potential **fraud or unusual buying behavior**.

---

## 📁 Project Structure

SQL_Assessment/
│
├── Aiyegbeni_Israel_SQL_Assessment.sql # Full solutions + explanations
├── README.md # Project documentation
└── Data # Contains the CSV files

---

## 🚀 How to Run

1. Create PostgreSQL database
2. Create the tables (also contained in the SQL file)
3. Import dataset tables:
   - customers
   - products
   - employees
   - orders
   - order_items
3. Run the SQL file sequentially

---

## 🎯 Learning Outcomes

- Translating business problems into SQL logic
- Designing revenue models from transactional data
- Applying analytical thinking using SQL
- Building scalable query structures using CTEs & window functions
- Performing real-world data segmentation and anomaly detection

---

## 👤 Author

**Eazi T**  
Data & AI Enthusiast | Agricultural & Environmental Engineering Background  
Focused on Data Engineering, Machine Learning & Analytics
