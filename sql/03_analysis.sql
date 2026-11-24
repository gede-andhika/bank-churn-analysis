-- =============================================
-- 03_analysis.sql
-- Proyek  : Bank Customer Churn Analysis
-- Tujuan  : Analisis churn nasabah & skor risiko
-- Database: PostgreSQL (bank_churn)
-- =============================================

-- 1. Gambaran umum: berapa nasabah yang pergi dan berapa dana yang hilang?
SELECT
    COUNT(*)                                          AS total_nasabah,
    SUM(exited)                                       AS nasabah_churn,
    ROUND(AVG(exited) * 100, 2)                       AS churn_rate_persen,
    SUM(CASE WHEN exited = 1 THEN balance ELSE 0 END) AS total_saldo_hilang
FROM customers;

-- 2. Churn berdasarkan negara
SELECT
    geography,
    COUNT(*)                                          AS total_nasabah,
    SUM(exited)                                       AS nasabah_churn,
    ROUND(AVG(exited) * 100, 2)                       AS churn_rate_persen,
    SUM(CASE WHEN exited = 1 THEN balance ELSE 0 END) AS saldo_hilang,
    ROUND(
        100.0 * SUM(CASE WHEN exited = 1 THEN balance ELSE 0 END)
        / SUM(SUM(CASE WHEN exited = 1 THEN balance ELSE 0 END)) OVER (),
    2)                                                AS persen_dari_total_saldo_hilang
FROM customers
GROUP BY geography
ORDER BY churn_rate_persen DESC;

-- 3. Churn berdasarkan kelompok umur
SELECT
    CASE
        WHEN age < 30 THEN '18-29'
        WHEN age < 40 THEN '30-39'
        WHEN age < 50 THEN '40-49'
        WHEN age < 60 THEN '50-59'
        ELSE '60+'
    END                                AS kelompok_umur,
    COUNT(*)                           AS total_nasabah,
    SUM(exited)                        AS nasabah_churn,
    ROUND(AVG(exited) * 100, 2)        AS churn_rate_persen,
    ROUND(AVG(balance), 2)             AS rata_rata_saldo
FROM customers
GROUP BY kelompok_umur
ORDER BY kelompok_umur ASC;

-- 4. Churn berdasarkan jumlah produk yang dipakai
SELECT
    num_of_products,
    COUNT(*)                           AS total_nasabah,
    SUM(exited)                        AS nasabah_churn,
    ROUND(AVG(exited) * 100, 2)        AS churn_rate_persen
FROM customers
GROUP BY num_of_products
ORDER BY num_of_products;

-- 5. Churn berdasarkan status keaktifan nasabah
SELECT
    CASE WHEN is_active_member = 1 THEN 'Aktif' ELSE 'Tidak Aktif' END AS status_keaktifan,
    COUNT(*)                                          AS total_nasabah,
    SUM(exited)                                       AS nasabah_churn,
    ROUND(AVG(exited) * 100, 2)                       AS churn_rate_persen,
    SUM(CASE WHEN exited = 0 THEN balance ELSE 0 END) AS saldo_nasabah_bertahan
FROM customers
GROUP BY status_keaktifan
ORDER BY churn_rate_persen DESC;

-- 6. Nasabah bersaldo nol vs ada saldo, per negara
SELECT
    geography,
    CASE WHEN balance = 0 THEN 'Saldo Nol' ELSE 'Ada Saldo' END AS kategori_saldo,
    COUNT(*)                           AS total_nasabah,
    SUM(exited)                        AS nasabah_churn,
    ROUND(AVG(exited) * 100, 2)        AS churn_rate_persen
FROM customers
GROUP BY geography, kategori_saldo
ORDER BY geography, kategori_saldo;

-- 7. Skor risiko churn & saldo yang terancam
--    Skor 0-4: +1 poin untuk setiap faktor (Jerman, umur 40-59, produk selain 2, tidak aktif)
WITH skor AS (
    SELECT
        *,
        (CASE WHEN geography = 'Germany'  THEN 1 ELSE 0 END
       + CASE WHEN age BETWEEN 40 AND 59  THEN 1 ELSE 0 END
       + CASE WHEN num_of_products <> 2   THEN 1 ELSE 0 END
       + CASE WHEN is_active_member = 0   THEN 1 ELSE 0 END) AS skor_risiko
    FROM customers
)
SELECT
    skor_risiko,
    COUNT(*)                                          AS total_nasabah,
    ROUND(AVG(exited) * 100, 2)                       AS churn_rate_persen,
    SUM(CASE WHEN exited = 0 THEN 1 ELSE 0 END)       AS nasabah_masih_bertahan,
    SUM(CASE WHEN exited = 0 THEN balance ELSE 0 END) AS saldo_terancam
FROM skor
GROUP BY skor_risiko
ORDER BY skor_risiko DESC;