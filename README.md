# 🏡 Nashville Housing Data Cleaning (SQL Server)

## 📌 Project Overview
This project demonstrates a **professional end-to-end SQL data cleaning and data quality pipeline** applied to a real-world real estate dataset (Nashville Housing).

The main objective is to transform **raw, inconsistent housing data** into a **clean, reliable, analytics-ready dataset** suitable for **Business Intelligence (BI), Data Science, and institutional reporting**.

The project follows **enterprise-level best practices** in data preparation, validation, and governance.

---

## 🎯 Objectives
- Clean and standardize raw real estate data
- Improve data quality and consistency
- Enforce business rules and validation checks
- Prepare structured datasets for BI and Data Science
- Create a final **GOLD analytical table**

---

## 🛠️ Technologies & Tools
- **SQL Server**
- **T-SQL**
- SQL Server Management Studio (SSMS)
- Git & GitHub (version control)

---

## 📂 Dataset
- **Nashville Housing Dataset**
- Real estate transaction data including:
  - Sale dates and prices
  - Property and owner addresses
  - Parcel identifiers
  - Vacancy status

---

## 🔄 Data Cleaning & Processing Steps

### **Step 1 – Data Exploration**
- Initial inspection of raw data
- Identification of missing values, inconsistencies, and duplicates

---

### **Step 2 – Date Standardization**
- Conversion of raw sale dates into a standardized `DATE` format
- Creation of `SaleDateConverted` for time-based analysis

---

### **Step 3 – Address Completion**
- Filling missing property addresses using self-joins on `ParcelID`
- Data-driven enrichment without external data sources

---

### **Step 4 – Address Structuring (Feature Engineering)**
- Splitting property addresses into:
  - Street address
  - City
- Splitting owner addresses into:
  - Address
  - City
  - State

---

### **Step 5 – Categorical Normalization**
- Standardization of `SoldAsVacant` values (`Y/N` → `Yes/No`)
- Ensures consistency for reporting and analytics

---

### **Step 6 – Duplicate Detection**
- Identification of duplicate transactions using `ROW_NUMBER()`
- Validation of unique real estate transactions

---

### **Step 7 – Schema Optimization**
- Removal of unused and redundant columns
- Clean, analytics-focused table structure

---

### **Step 8 – Data Quality Checks (Governance Layer)**
- Validation of business rules:
  - Sale price > 0
  - Valid sale dates
  - Non-null critical fields
- Detection of remaining anomalies
- Introduction of a **QualityFlag** to qualify each record

---

### **Step 9 – GOLD Layer Creation**
- Creation of the final clean table: `NashvilleHousing_Clean`
- Inclusion of **only high-quality records (`QualityFlag = 1`)**
- Optimized schema for BI and Data Science use cases
- Performance indexes added for analytics

---

## ✅ Final Output
- Fully cleaned and validated dataset
- No remaining duplicates
- Business rules enforced
- Analytics-ready **GOLD table**

---

## 📊 Use Cases
- Business Intelligence dashboards (Power BI, Tableau)
- Real estate market analysis
- Price trend and historical analysis
- City-level and geospatial analysis
- Data Science modeling (price prediction)

---

## 🧠 Key Skills Demonstrated
- Advanced SQL (CTEs, window functions, joins)
- Data cleaning & transformation
- Data quality & data governance
- Feature engineering
- Analytical thinking
- BI & Data Science readiness

---

## 🚀 Next Steps (Future Work)
- Step 10: KPI calculation and analytical SQL queries
- Step 11: Power BI dashboard development
- Step 12: Predictive modeling (Data Science)

---

## 👤 Author
**Hicham Errihani**  
Data Analyst & Data Scientist  
Specialized in industrial, technological, and institutional data environments

---

## ⭐ Why This Project Matters
This project reflects **real-world enterprise data workflows**, emphasizing **data reliability, governance, and analytics readiness**, going beyond simple academic SQL exercises.


## 🧱 Project Structure
```
Nashville-Housing-DB/
├── data/                        # Raw data (optional / placeholder)
├── Nashville-Housing-DB.sql     # Main SQL cleaning & data quality pipeline
└── README.md                    # Project documentation
```
