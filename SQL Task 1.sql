create database `Ecommerce Sales Analysis`;
use `Ecommerce Sales Analysis`;

-- sales table
CREATE TABLE sales (
  row_id INT not null primary key,
  order_id VARCHAR(100),
  order_date DATE,
  ship_date DATE,
  ship_mode VARCHAR(50),
  customer_segment VARCHAR(100),
  city VARCHAR(100),
  state VARCHAR(100),
  country VARCHAR(100),
  continent VARCHAR(100),
  product_id VARCHAR(100),
  category VARCHAR(100),
  sub_category VARCHAR(100),
  product_name VARCHAR(255),
  quantity INT,
  unit_price DECIMAL(5,2),
  `discount %` DECIMAL(5,2),
  unit_manufacturing_cost DECIMAL(10,2),
  unit_shipping_cost DECIMAL(10,2),
  order_priority VARCHAR(100)
);

-- finding data location
SHOW VARIABLES LIKE 'secure_file_priv';

-- Data loaded from Storage
load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sales.csv'
into table sales
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Repairing column
ALTER TABLE sales
MODIFY COLUMN unit_price DECIMAL(15,4); 

-- Shoeing tables data
SELECT * FROM `ecommerce sales analysis`.sales;
SELECT * FROM `ecommerce sales analysis`.return_table;

-- Location Dimension
CREATE TABLE dim_location (
  location_id INT AUTO_INCREMENT PRIMARY KEY,
  city VARCHAR(100),
  state VARCHAR(100),
  country VARCHAR(100),
  continent VARCHAR(100),
  UNIQUE(city, state, country, continent)
);

-- Category Dimension
CREATE TABLE dim_category (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  category_name VARCHAR(100) UNIQUE
);

-- Sub-category Dimension
CREATE TABLE dim_sub_category (
  sub_category_id INT AUTO_INCREMENT PRIMARY KEY,
  sub_category_name VARCHAR(100),
  category_id INT,
  FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
  UNIQUE(sub_category_name)
);

-- Product Dimension
CREATE TABLE dim_product (
  product_id VARCHAR(100) PRIMARY KEY,
  product_name VARCHAR(255),
  sub_category_id INT,
  FOREIGN KEY (sub_category_id) REFERENCES dim_sub_category(sub_category_id)
);


CREATE TABLE fact_transaction (
  transaction_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id VARCHAR(100),
  order_date DATE,
  ship_date DATE,
  ship_mode VARCHAR(50),
  customer_segment VARCHAR(100),
  product_id VARCHAR(100),
  location_id INT,
  quantity INT,
  unit_price DECIMAL(15,4),
  discount_percent DECIMAL(5,2),
  unit_manufacturing_cost DECIMAL(10,2),
  unit_shipping_cost DECIMAL(10,2),
  order_priority VARCHAR(100),
  
  FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
  FOREIGN KEY (location_id) REFERENCES dim_location(location_id)
);


-- dim_location
INSERT IGNORE INTO dim_location (city, state, country, continent)
SELECT DISTINCT city, state, country, continent FROM sales;

-- dim_category
INSERT IGNORE INTO dim_category (category_name)
SELECT DISTINCT category FROM sales;

-- dim_sub_category
INSERT IGNORE INTO dim_sub_category (sub_category_name, category_id)
SELECT DISTINCT s.sub_category, dc.category_id
FROM sales s
JOIN dim_category dc ON s.category = dc.category_name;

-- dim_product
INSERT IGNORE INTO dim_product (product_id, product_name, sub_category_id)
SELECT DISTINCT s.product_id, s.product_name, dsc.sub_category_id
FROM sales s
JOIN dim_sub_category dsc ON s.sub_category = dsc.sub_category_name;


INSERT INTO fact_transaction (
  order_id, order_date, ship_date, ship_mode,
  customer_segment, product_id, location_id,
  quantity, unit_price, discount_percent,
  unit_manufacturing_cost, unit_shipping_cost, order_priority
)
SELECT
  s.order_id, s.order_date, s.ship_date, s.ship_mode,
  s.customer_segment, s.product_id, dl.location_id,
  s.quantity, s.unit_price, s.`discount %`,
  s.unit_manufacturing_cost, s.unit_shipping_cost, s.order_priority
FROM sales s
JOIN dim_location dl 
  ON s.city = dl.city AND s.state = dl.state AND s.country = dl.country AND s.continent = dl.continent;





