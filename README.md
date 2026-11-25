# Bank Customer Churn Analysis: Retensi Nasabah dan Saldo yang Terancam

> **Proyek analitik end-to-end** menggunakan PostgreSQL, Python (Jupyter), dan Data Studio untuk mengidentifikasi di mana nasabah bank paling banyak pergi, lalu memprioritaskan nasabah yang masih bertahan tetapi berisiko pergi berikutnya.

**Hasil utama:**
- Bank kehilangan **20,37%** nasabahnya (2.037 dari 10.000), dengan saldo **185,6 juta** ikut keluar.
- Kebocoran terkonsentrasi di **Jerman** (churn 32,4%) dan **usia 40–59 tahun** (35% nasabah, tetapi 63% dari seluruh churn).
- Nasabah dengan **2 produk** paling setia (churn 7,6%); nasabah **tidak aktif** pergi hampir **2x** lebih sering.
- Skor risiko dari 4 faktor memisahkan nasabah dengan jelas: churn naik dari **2,8%** (skor 0) ke **74,7%** (skor 4).
- **917 nasabah berisiko tinggi masih bertahan** dengan saldo **101,6 juta**: daftar prioritas untuk program retensi.

---

## Daftar Isi

1. [Business Understanding](#1-business-understanding)
2. [Data Source](#2-data-source)
3. [Tech Stack dan Alur Kerja](#3-tech-stack-dan-alur-kerja)
4. [Data Cleaning](#4-data-cleaning)
5. [Feature Engineering](#5-feature-engineering)
6. [Key Findings](#6-key-findings)
7. [Dashboard](#7-dashboard)
8. [Insight dan Rekomendasi Strategis](#8-insight-dan-rekomendasi-strategis)
9. [Limitations dan Catatan Metodologi](#limitations-dan-catatan-metodologi)

---

## 1. Business Understanding

### 1.1 Latar Belakang Bisnis

Bank memperoleh dana murah dari tabungan dan giro nasabah, lalu menyalurkannya sebagai kredit. Setiap nasabah yang pergi membawa saldonya, sehingga dana yang bisa disalurkan ikut berkurang. Mempertahankan nasabah lama umumnya juga lebih murah daripada mencari nasabah baru.

Dataset berisi 10.000 nasabah sebuah bank di tiga negara Eropa (Prancis, Spanyol, Jerman). Setiap nasabah memiliki dua status utama:

- **Churn** (`Exited = 1`): nasabah sudah meninggalkan bank.
- **Bertahan** (`Exited = 0`): nasabah masih menjadi nasabah bank.

Nasabah juga dibedakan menjadi **aktif** dan **tidak aktif** (`IsActiveMember`), yaitu apakah nasabah aktif bertransaksi atau hanya memiliki rekening.

### 1.2 Masalah Bisnis

Manajemen menghadapi dua masalah yang saling terkait:

- **Masalah 1: Kebocoran nasabah dan dana.** Sekitar 1 dari 5 nasabah meninggalkan bank dan membawa saldo 185,6 juta. Belum diketahui di mana kebocoran itu terkonsentrasi.
- **Masalah 2: Dana yang masih bisa diselamatkan.** Dari 7.963 nasabah yang masih bertahan (total saldo 579,3 juta), belum jelas siapa yang paling berisiko pergi berikutnya. Tanpa prioritas, program retensi harus disebar ke semua nasabah.

### 1.3 Tujuan Proyek

| # | Tujuan | Fokus Analisis |
|---|---|---|
| 1 | Mengidentifikasi lokasi dan besaran kebocoran nasabah | Segmentasi churn: negara, umur, jumlah produk, keaktifan |
| 2 | Mengidentifikasi nasabah bertahan yang berisiko tinggi beserta nilai saldonya | Skor risiko dan saldo terancam |

### 1.4 Pertanyaan Bisnis (Key Business Questions)

**Tujuan 1: Kebocoran nasabah**

- Seberapa besar churn keseluruhan, dan berapa saldo yang hilang?
- Di negara dan kelompok umur mana nasabah paling sering pergi?
- Apakah jumlah produk yang dipakai dan status keaktifan berkaitan dengan churn?
- Apakah perbedaan antarnegara tetap ada jika dibandingkan secara adil (misalnya hanya nasabah bersaldo)?

**Tujuan 2: Prioritas retensi**

- Faktor mana yang bisa digabung menjadi skor risiko, dan apakah skor itu benar-benar memisahkan nasabah yang pergi dan yang bertahan?
- Berapa banyak nasabah berisiko tinggi yang masih bertahan, dan berapa saldo yang terancam?

---

## 2. Data Source

**Platform:** Kaggle
**Dataset:** [Predicting Churn for Bank Customers](https://www.kaggle.com/datasets/adammaus/predicting-churn-for-bank-customers) (`Churn_Modelling.csv`)
**Ukuran:** 10.000 baris, 14 kolom, 1 tabel (`customers`)

| Kolom | Keterangan | Tipe di PostgreSQL | Dipakai di analisis |
|---|---|---|---|
| `row_number` | Nomor baris | INT | Tidak |
| `customer_id` | ID nasabah (PRIMARY KEY) | BIGINT | Ya (identitas) |
| `surname` | Nama belakang nasabah | VARCHAR(50) | Tidak |
| `credit_score` | Skor kredit | INT | Tidak |
| `geography` | Negara (Prancis, Spanyol, Jerman) | VARCHAR(20) | Ya |
| `gender` | Jenis kelamin | VARCHAR(10) | Hanya diekspor |
| `age` | Umur | INT | Ya |
| `tenure` | Lama menjadi nasabah (tahun) | INT | Hanya diekspor |
| `balance` | Saldo rekening | NUMERIC(12,2) | Ya |
| `num_of_products` | Jumlah produk bank yang dipakai (1–4) | INT | Ya |
| `has_cr_card` | Punya kartu kredit (1/0) | SMALLINT | Tidak |
| `is_active_member` | Nasabah aktif bertransaksi (1/0) | SMALLINT | Ya |
| `estimated_salary` | Perkiraan gaji | NUMERIC(12,2) | Tidak |
| `exited` | Status churn (target) | SMALLINT | Ya |

**Rentang waktu:** dataset tidak punya kolom tanggal; data adalah potret satu titik waktu.
**Mata uang:** tidak disebutkan di dataset, sehingga saldo ditulis dalam satuan aslinya.
**Privasi:** dataset publik dan sudah dianonimkan. Kolom `surname` tidak ikut diekspor ke dashboard.

---

## 3. Tech Stack dan Alur Kerja

**Alur:** Kaggle (CSV) → PostgreSQL → Python (Jupyter) → CSV hasil olahan → Data Studio

| Tahap | Tools | Output |
|---|---|---|
| Penyimpanan dan validasi data | PostgreSQL (pgAdmin 4) | Tabel `customers`, cek kualitas data |
| Analisis | SQL (CTE, window function, CASE WHEN) | 7 query di `sql/03_analysis.sql` |
| Visualisasi dan rekonsiliasi | Python (pandas, matplotlib, seaborn) di Jupyter | 5 grafik di `images/` |
| Dashboard | Data Studio | Dashboard interaktif publik |

**Koneksi:** Python terhubung langsung ke PostgreSQL lewat SQLAlchemy. Password database dimasukkan saat dijalankan dengan `getpass()`, sehingga tidak tersimpan di kode. Dashboard membaca file `data/churn_dashboard.csv` hasil olahan Python (tanpa kolom nama nasabah).

---

## 4. Data Cleaning

Semua pengecekan dilakukan di PostgreSQL dan tersimpan di [`sql/02_data_quality.sql`](sql/02_data_quality.sql). Hasilnya: data bersih, dan tidak ada baris yang dihapus atau diubah.

### 4.1 Strategi Validasi

| Pengecekan | Cara | Hasil |
|---|---|---|
| Jumlah baris setelah import | `COUNT(*)` dibandingkan dengan file sumber | 10.000 baris, sama dengan sumber |
| Nilai kosong (NULL) | `COUNT(*) - COUNT(kolom)` untuk setiap kolom | Tidak ada NULL |
| Duplikat `customer_id` | `GROUP BY` + `HAVING COUNT(*) > 1`, dijaga juga oleh PRIMARY KEY | Tidak ada duplikat |
| Rentang nilai | `MIN` dan `MAX` untuk umur, skor kredit, lama menjadi nasabah, saldo, jumlah produk | Wajar; saldo minimum 0 |
| Konsistensi kategori | `GROUP BY geography` | 3 negara, penulisan konsisten |

### 4.2 Keputusan Desain Data

- **Uang disimpan sebagai `NUMERIC(12,2)`, bukan `FLOAT`.** `FLOAT` menyimpan angka secara perkiraan dan bisa menimbulkan selisih pembulatan; untuk data uang, selisih sekecil apa pun tidak bisa diterima.
- **`customer_id` sebagai PRIMARY KEY.** Database otomatis menolak data ganda.
- **Saldo nol dipertahankan.** Nasabah bersaldo nol bukan error data, dan justru menjelaskan perbedaan antarnegara (lihat Temuan 1).
- **Prinsip data minimization.** Nama nasabah tidak diekspor ke dashboard karena tidak dibutuhkan untuk analisis.

### 4.3 Insiden Kualitas Data dan Pelajarannya

1. **CSV rusak karena dibuka di Excel.** File sempat tersimpan ulang oleh Excel dengan pengaturan bahasa Indonesia: pemisah kolom berubah menjadi titik koma dan titik desimal hilang (gaji 101348.88 menjadi 10134888, 100 kali lipat). PostgreSQL menolak import karena tipe data yang ketat, sehingga kesalahan ketahuan sebelum analisis. File diganti dengan versi asli. **Pelajaran:** data mentah tidak boleh dibuka dan disimpan ulang di Excel.
2. **Kesalahan kondisi di query saldo terancam.** Kondisi `exited = 1` seharusnya `exited = 0`. Kesalahan ketahuan karena total kolom itu (185,59 juta) sama persis dengan total saldo yang hilang di query lain. Setelah diperbaiki, total saldo nasabah bertahan menjadi 579.270.798,25 dan cocok dengan query berbeda. **Pelajaran:** selalu rekonsiliasi angka antar-query.
3. **Rekonsiliasi lintas tools.** Angka utama (jumlah nasabah, churn, churn rate, saldo risiko tinggi) dicocokkan antara SQL, Python, dan dashboard.
