-- =============================================
-- 02_data_quality.sql
-- Proyek  : Bank Customer Churn Analysis
-- Tujuan  : Mengecek kualitas data sebelum analisis
-- Database: PostgreSQL (bank_churn)
-- =============================================

-- A. Validasi jumlah baris (harus 10000, sama dengan file sumber)
SELECT COUNT(*) AS total_baris FROM customers;

-- B. Cek data kosong (NULL) di setiap kolom
SELECT
    COUNT(*) - COUNT(customer_id)      AS null_customer_id,
    COUNT(*) - COUNT(credit_score)     AS null_credit_score,
    COUNT(*) - COUNT(geography)        AS null_geography,
    COUNT(*) - COUNT(gender)           AS null_gender,
    COUNT(*) - COUNT(age)              AS null_age,
    COUNT(*) - COUNT(tenure)           AS null_tenure,
    COUNT(*) - COUNT(balance)          AS null_balance,
    COUNT(*) - COUNT(num_of_products)  AS null_num_of_products,
    COUNT(*) - COUNT(is_active_member) AS null_is_active_member,
    COUNT(*) - COUNT(exited)           AS null_exited
FROM customers;

-- C. Cek data duplikat (hasil kosong = aman)
SELECT customer_id, COUNT(*) AS jumlah
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- D. Cek rentang nilai (cari nilai yang tidak masuk akal)
SELECT
    MIN(age) AS min_age,                    MAX(age) AS max_age,
    MIN(credit_score) AS min_score,         MAX(credit_score) AS max_score,
    MIN(tenure) AS min_tenure,              MAX(tenure) AS max_tenure,
    MIN(balance) AS min_balance,            MAX(balance) AS max_balance,
    MIN(num_of_products) AS min_products,   MAX(num_of_products) AS max_products
FROM customers;

-- E. Cek isi kolom kategori (harus konsisten, tidak ada variasi penulisan)
SELECT geography, COUNT(*) AS jumlah
FROM customers
GROUP BY geography;