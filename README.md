# Nashville Housing Data Cleaning (SQL Server)

## 📌 Project Overview
This project focuses on cleaning, transforming, and preparing the **Nashville Housing dataset** using **SQL Server (T-SQL)**.  
The objective is to convert raw real estate data into a **clean, structured, and analysis-ready dataset** suitable for business intelligence and data analytics use cases.

The project follows real-world **data cleaning best practices**, similar to what is expected in professional Data Analyst / BI roles.

---

## 🗂 Dataset
- **Dataset**: Nashville Housing
- **Domain**: Real Estate / Housing Market
- **Records**: ~56,000 rows
- **Source**: Public dataset (commonly used for SQL data cleaning practice)

---

## 🛠 Tools & Technologies
- **SQL Server**
- **T-SQL**
- **SQL Server Management Studio (SSMS)**
- **GitHub** (version control & documentation)

---

## 🔄 Data Cleaning Steps

### 1️⃣ Standardizing Date Formats
- Converted datetime values into a standardized `DATE` format.
- Created a clean column `SaleDateConverted`.

### 2️⃣ Handling Missing Values
- Filled missing `PropertyAddress` values using self-joins based on `ParcelID`.

### 3️⃣ Splitting Address Fields
- Split `PropertyAddress` into:
  - `PropertySplitAddress`
  - `PropertySplitCity`
- Split `OwnerAddress` into:
  - `OwnerSplitAddress`
  - `OwnerSplitCity`
  - `OwnerSplitState`

### 4️⃣ Normalizing Categorical Values
- Standardized `SoldAsVacant` values:
  - `Y` → `Yes`
  - `N` → `No`

### 5️⃣ Removing Duplicates
- Identified duplicates using `ROW_NUMBER()` with a CTE.
- Removed duplicate records based on:
  - ParcelID
  - PropertyAddress
  - SalePrice
  - SaleDate
  - LegalReference

### 6️⃣ Dropping Unused Columns
- Removed redundant and unused columns after normalization:
  - `OwnerAddress`
  - `PropertyAddress`
  - `TaxDistrict`
  - `SaleDate`

---

## 🧱 Final Output
- Cleaned and normalized dataset ready for:
  - Data analysis
  - BI dashboards
  - Reporting
- Final table structure optimized for analytical queries.

---

## 📂 Repository Structure

---

## 🎯 Key SQL Concepts Used
- `CASE WHEN`
- `TRY_CONVERT`
- `ISNULL`
- `SUBSTRING`, `CHARINDEX`
- `PARSENAME`
- `CTE (WITH)`
- `ROW_NUMBER()`
- `ALTER TABLE`
- `UPDATE`, `DELETE`

---

## 👤 Author
**Hicham Errihani**  
Data Analyst / BI & SQL Enthusiast  

---

## 📈 Use Cases
- Portfolio project for Data Analyst / BI roles
- SQL data cleaning demonstration
- Interview discussion project

