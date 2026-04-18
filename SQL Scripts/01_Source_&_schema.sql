
DROP TABLE IF EXISTS automobile_sales;

--Create Table--------------------------------------------
CREATE TABLE automobile_sales (
    Date                        DATE,
    Dealer                      VARCHAR(100),
    Region                      VARCHAR(50),
    Vehicle_Model               VARCHAR(100),
    Fuel_Type                   VARCHAR(50),
    Category                    VARCHAR(50),
    Units_Sold                  INT,
    Unit_Price                  BIGINT,
    Customer_Satisfaction_Score NUMERIC(4,2),
    Revenue                     BIGINT,
    Year 						INT,
	Image_URL                   VARCHAR(500),
    Month                       INT,
    Quarter                     INT
);
--Load Data----------------------------------------------
COPY automobile_sales
FROM 'copy file path'
DELIMITER ','
CSV HEADER;

--View Table-----------------------------------------
SELECT * FROM automobile_sales;
