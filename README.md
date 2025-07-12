# 📦 E-commerce Sales Analysis — Data Ingestion & SQL Insights

## 📋 Project Overview
This project focuses on ingesting, normalizing, and analyzing raw e-commerce data using **MySQL**. The goal is to build a clean dimensional model and answer critical business questions through SQL queries.

---

## 🛠️ Tools & Skills
- **Database:** MySQL
- **Skills:** SQL, Dimensional Modeling, Data Normalization, Data Analysis
- **Techniques:** Fact & Dimension Tables, INFILE loading, Joins, Aggregation

---

## 📥 Data Ingestion
- `sales.csv` loaded via `LOAD DATA INFILE`
- `return_table.csv` imported using Table Data Import Wizard

---

## 🧱 Data Modeling
- **Fact Table:** `fact_transaction`
- **Dimensions:** `dim_product`, `dim_sub_category`, `dim_category`, `dim_location`, `dim_date`
- Relationships built using Foreign Keys for better querying performance and clarity.

---

## 🔍 Business Questions Answered
- What is the total gross/net revenue and total profit?
- Which are the top 5 best-selling products?
- What are the return rates by product category and continent?
- Which shipping mode yields the most profit?
- How do discount rates affect order volume?

---

## 📊 Key Outcomes
✔️ Revenue and profit trends  
✔️ Customer segmentation analysis  
✔️ Return behavior insights  
✔️ Regional and shipping performance  

---

## ✅ How to Use
1. Clone this repo
2. Import the schema & sample data into MySQL
3. Run the SQL commands included in `analysis_queries.sql`

