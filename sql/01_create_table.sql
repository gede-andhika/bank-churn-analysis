-- =============================================
-- 01_create_table.sql
-- Proyek  : Bank Customer Churn Analysis
-- Tujuan  : Membuat tabel customers
-- Database: PostgreSQL (bank_churn)
-- =============================================

CREATE TABLE customers (
    row_number        INT,
    customer_id       BIGINT PRIMARY KEY,
    surname           VARCHAR(50),
    credit_score      INT,
    geography         VARCHAR(20),
    gender            VARCHAR(10),
    age               INT,
    tenure            INT,
    balance           NUMERIC(12,2),
    num_of_products   INT,
    has_cr_card       SMALLINT,
    is_active_member  SMALLINT,
    estimated_salary  NUMERIC(12,2),
    exited            SMALLINT
);