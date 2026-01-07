USE [Nashville-Housing-DB];
GO

SELECT *
FROM dbo.NashvilleHousing;

-- Standardize Date Format
SELECT
    SaleDate,
    CONVERT(DATE, SaleDate) AS SaleDate_Converted
FROM dbo.NashvilleHousing;

ALTER TABLE dbo.NashvilleHousing
ADD SaleDateConverted DATE;


UPDATE dbo.NashvilleHousing
SET SaleDateConverted = TRY_CONVERT(DATE, SaleDate);


SELECT SaleDate, SaleDateConverted
FROM dbo.NashvilleHousing;


---Populate Property Address data
USE [Nashville-Housing-DB];
GO

SELECT *
FROM dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

USE [Nashville-Housing-DB];
GO

SELECT
    a.ParcelID,
    a.PropertyAddress,
    b.ParcelID AS ParcelID_b,
    b.PropertyAddress AS PropertyAddress_b,
    ISNULL(a.PropertyAddress, b.PropertyAddress) AS PropertyAddress_Filled
FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
   AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

USE [Nashville-Housing-DB];
GO

UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
   AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

--------------------------------------------------------------
USE [Nashville-Housing-DB];
GO

-- Breaking out Address into Individual Columns (Address, City, State)
SELECT
    PropertyAddress
FROM dbo.NashvilleHousing
-- WHERE PropertyAddress IS NULL
-- ORDER BY ParcelID;

USE [Nashville-Housing-DB];
GO

SELECT
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS PropertySplitAddress,
    LTRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))) AS PropertySplitCity
FROM dbo.NashvilleHousing;


USE [Nashville-Housing-DB];
GO
ALTER TABLE dbo.NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255),
    PropertySplitCity NVARCHAR(255);

UPDATE dbo.NashvilleHousing
SET PropertySplitAddress =
    CASE
        WHEN CHARINDEX(',', PropertyAddress) > 0
        THEN SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)
        ELSE PropertyAddress
    END;

UPDATE dbo.NashvilleHousing
SET PropertySplitCity =
    CASE
        WHEN CHARINDEX(',', PropertyAddress) > 0
        THEN LTRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)))
        ELSE NULL
    END;


USE [Nashville-Housing-DB];
GO

SELECT *
FROM dbo.NashvilleHousing;

USE [Nashville-Housing-DB];
GO

SELECT
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerSplitAddress,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerSplitCity,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerSplitState
FROM dbo.NashvilleHousing;

USE [Nashville-Housing-DB];
GO
ALTER TABLE dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255),
    OwnerSplitCity NVARCHAR(255),
    OwnerSplitState NVARCHAR(50);

UPDATE dbo.NashvilleHousing
SET OwnerSplitAddress =
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);
UPDATE dbo.NashvilleHousing
SET OwnerSplitCity =
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);
UPDATE dbo.NashvilleHousing
SET OwnerSplitState =
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

USE [Nashville-Housing-DB];
GO

SELECT *
FROM dbo.NashvilleHousing;
---------------------------------
USE [Nashville-Housing-DB];
GO

-- Change Y and N to Yes and No in "SoldAsVacant" field
SELECT
    SoldAsVacant,
    COUNT(*) AS CountSoldAsVacant
FROM dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY CountSoldAsVacant;

SELECT
    SoldAsVacant,
    CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END AS SoldAsVacant_Clean
FROM dbo.NashvilleHousing;

UPDATE dbo.NashvilleHousing
SET SoldAsVacant =
    CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END;
SELECT
    SoldAsVacant,
    COUNT(*) AS CountSoldAsVacant
FROM dbo.NashvilleHousing
GROUP BY SoldAsVacant;
-----Remove duplicats

USE [Nashville-Housing-DB];
GO

USE [Nashville-Housing-DB];
GO

WITH RowNumCTE AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                ParcelID,
                PropertyAddress,
                SalePrice,
                SaleDate,
                LegalReference
            ORDER BY
                [UniqueID ]
        ) AS row_num
    FROM dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

-- =====================================================
-- Delete / Identify Unused Columns
-- Step: Review data before removing unnecessary columns
-- =====================================================

SELECT *
FROM dbo.NashvilleHousing;

ALTER TABLE dbo.NashvilleHousing
DROP COLUMN
    OwnerAddress,
    TaxDistrict,
    PropertyAddress;

ALTER TABLE dbo.NashvilleHousing
DROP COLUMN SaleDate;

/* =========================================================
   STEP 8 – DATA QUALITY CHECKS
   Objectif :
   - Vérifier la qualité finale des données
   - Identifier les anomalies restantes
   - Garantir la fiabilité pour BI / Data Science
   ========================================================= */

USE [Nashville-Housing-DB];
GO

/* ---------------------------------------------------------
   8.1 PROFIL GLOBAL DE QUALITÉ DES DONNÉES
   - Nombre total de lignes
   - Valeurs NULL critiques
   - Valeurs métier invalides
   --------------------------------------------------------- */
SELECT
    COUNT(*) AS total_rows,

    -- Dates non converties
    SUM(CASE 
        WHEN SaleDateConverted IS NULL THEN 1 
        ELSE 0 
    END) AS null_sale_dates,

    -- Prix manquants ou invalides (règle métier : prix > 0)
    SUM(CASE 
        WHEN SalePrice IS NULL OR SalePrice <= 0 THEN 1 
        ELSE 0 
    END) AS invalid_sale_prices,

    -- Ville manquante après split d’adresse
    SUM(CASE 
        WHEN PropertySplitCity IS NULL THEN 1 
        ELSE 0 
    END) AS null_property_city,

    -- Valeurs catégorielles non conformes
    SUM(CASE 
        WHEN SoldAsVacant NOT IN ('Yes', 'No') OR SoldAsVacant IS NULL THEN 1 
        ELSE 0 
    END) AS invalid_sold_as_vacant
FROM dbo.NashvilleHousing;
GO

/* ---------------------------------------------------------
   8.2 CONTRÔLE DE COHÉRENCE DES DATES
   - Pas de dates trop anciennes
   - Pas de dates futures
   --------------------------------------------------------- */
SELECT
    COUNT(*) AS invalid_date_rows
FROM dbo.NashvilleHousing
WHERE SaleDateConverted < '1900-01-01'
   OR SaleDateConverted > GETDATE();
GO

/* ---------------------------------------------------------
   8.3 DÉTECTION DES VALEURS ABERRANTES (OUTLIERS)
   - Identification manuelle des prix extrêmes
   --------------------------------------------------------- */

-- Prix les plus élevés
SELECT TOP 20
    SalePrice
FROM dbo.NashvilleHousing
WHERE SalePrice IS NOT NULL
ORDER BY SalePrice DESC;
GO

-- Prix les plus faibles (hors NULL)
SELECT TOP 20
    SalePrice
FROM dbo.NashvilleHousing
WHERE SalePrice IS NOT NULL
ORDER BY SalePrice ASC;
GO

/* ---------------------------------------------------------
   8.4 VÉRIFICATION DES DOUBLONS RÉSIDUELS
   - Une ligne par transaction attendue
   --------------------------------------------------------- */
WITH DuplicateCheck AS (
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY
                ParcelID,
                PropertySplitAddress,
                SalePrice,
                SaleDateConverted,
                LegalReference
            ORDER BY [UniqueID ]
        ) AS row_num
    FROM dbo.NashvilleHousing
)
SELECT
    COUNT(*) AS remaining_duplicates
FROM DuplicateCheck
WHERE row_num > 1;
GO

/* ---------------------------------------------------------
   8.5 AJOUT D’UN INDICATEUR DE QUALITÉ (DATA GOVERNANCE)
   - 1 = donnée fiable
   - 0 = donnée à exclure des analyses
   --------------------------------------------------------- */

-- Ajout du flag qualité (si non existant)
IF COL_LENGTH('dbo.NashvilleHousing', 'QualityFlag') IS NULL
BEGIN
    ALTER TABLE dbo.NashvilleHousing
    ADD QualityFlag BIT;
END;
GO

-- Mise à jour du flag qualité selon règles métier
UPDATE dbo.NashvilleHousing
SET QualityFlag =
    CASE
        WHEN SaleDateConverted IS NULL THEN 0
        WHEN SalePrice IS NULL OR SalePrice <= 0 THEN 0
        WHEN PropertySplitCity IS NULL THEN 0
        ELSE 1
    END;
GO

/* ---------------------------------------------------------
   8.6 CONTRÔLE FINAL DU FLAG QUALITÉ
   --------------------------------------------------------- */
SELECT
    QualityFlag,
    COUNT(*) AS rows_count
FROM dbo.NashvilleHousing
GROUP BY QualityFlag;
GO

/* =========================================================
   STEP 9 – CREATE FINAL CLEAN TABLE (GOLD LAYER)
   Objectif :
   - Créer une table finale propre et stable : dbo.NashvilleHousing_Clean
   - Filtrer uniquement les lignes de qualité (QualityFlag = 1)
   - Conserver uniquement les colonnes utiles pour BI / DS
   - Ajouter des contrôles finaux (row count, nulls, duplicates)
   ========================================================= */

USE [Nashville-Housing-DB];
GO

/* ---------------------------------------------------------
   9.1 (OPTIONNEL) : Sauvegarde / Sécurisation
   -> Si tu veux garder un backup avant de créer la table clean
   --------------------------------------------------------- */
 SELECT * INTO dbo.NashvilleHousing_Backup_20260107
 FROM dbo.NashvilleHousing;
 GO


/* ---------------------------------------------------------
   9.2 Supprimer la table clean si elle existe déjà
   -> Rend le script ré-exécutable (idempotent)
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.NashvilleHousing_Clean', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.NashvilleHousing_Clean;
END;
GO


/* ---------------------------------------------------------
   9.3 Créer la table finale Clean (GOLD)
   -> On définit les types de colonnes explicitement
   -> On ne garde que les champs utiles
   --------------------------------------------------------- */
CREATE TABLE dbo.NashvilleHousing_Clean (
    UniqueID            BIGINT        NULL,     -- garder tel que dans la source si besoin
    ParcelID            NVARCHAR(50)   NULL,

    -- Dates
    SaleDateConverted   DATE          NULL,

    -- Prix / Références
    SalePrice           BIGINT        NULL,
    LegalReference      NVARCHAR(100) NULL,

    -- Adresses (propriété)
    PropertySplitAddress NVARCHAR(255) NULL,
    PropertySplitCity    NVARCHAR(255) NULL,

    -- Adresses (propriétaire)
    OwnerSplitAddress   NVARCHAR(255) NULL,
    OwnerSplitCity      NVARCHAR(255) NULL,
    OwnerSplitState     NVARCHAR(50)  NULL,

    -- Champ business normalisé
    SoldAsVacant        NVARCHAR(10)  NULL,

    -- Gouvernance
    QualityFlag         BIT           NOT NULL
);
GO


/* ---------------------------------------------------------
   9.4 Charger les données propres dans la table Clean
   -> On filtre QualityFlag = 1
   -> On peut aussi filtrer SalePrice > 0 pour renforcer
   --------------------------------------------------------- */
INSERT INTO dbo.NashvilleHousing_Clean (
    UniqueID,
    ParcelID,
    SaleDateConverted,
    SalePrice,
    LegalReference,
    PropertySplitAddress,
    PropertySplitCity,
    OwnerSplitAddress,
    OwnerSplitCity,
    OwnerSplitState,
    SoldAsVacant,
    QualityFlag
)
SELECT
    CAST([UniqueID ] AS BIGINT) AS UniqueID,
    ParcelID,
    SaleDateConverted,
    SalePrice,
    LegalReference,
    PropertySplitAddress,
    PropertySplitCity,
    OwnerSplitAddress,
    OwnerSplitCity,
    OwnerSplitState,
    LTRIM(RTRIM(SoldAsVacant)) AS SoldAsVacant,
    QualityFlag
FROM dbo.NashvilleHousing
WHERE QualityFlag = 1;
GO


/* ---------------------------------------------------------
   9.5 Contrôles finaux (validation)
   --------------------------------------------------------- */

-- 9.5.1 Vérifier le volume chargé
SELECT COUNT(*) AS clean_rows
FROM dbo.NashvilleHousing_Clean;
GO

-- 9.5.2 Vérifier les NULL critiques (devrait être faible / nul)
SELECT
    SUM(CASE WHEN SaleDateConverted IS NULL THEN 1 ELSE 0 END) AS null_dates,
    SUM(CASE WHEN SalePrice IS NULL OR SalePrice <= 0 THEN 1 ELSE 0 END) AS invalid_prices,
    SUM(CASE WHEN PropertySplitCity IS NULL OR LTRIM(RTRIM(PropertySplitCity)) = '' THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN SoldAsVacant NOT IN ('Yes','No') OR SoldAsVacant IS NULL THEN 1 ELSE 0 END) AS invalid_soldasvacant
FROM dbo.NashvilleHousing_Clean;
GO

-- 9.5.3 Vérifier les doublons résiduels dans la table clean
WITH DuplicateCheck AS (
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY
                ParcelID,
                PropertySplitAddress,
                SalePrice,
                SaleDateConverted,
                LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM dbo.NashvilleHousing_Clean
)
SELECT COUNT(*) AS remaining_duplicates_clean
FROM DuplicateCheck
WHERE row_num > 1;
GO


/* ---------------------------------------------------------
   9.6 (OPTIONNEL MAIS PRO) : Ajouter des index pour performance BI
   -> Accélère filtres (date, city, parcel)
   --------------------------------------------------------- */
CREATE INDEX IX_NashvilleHousingClean_SaleDate
ON dbo.NashvilleHousing_Clean (SaleDateConverted);
GO

CREATE INDEX IX_NashvilleHousingClean_City
ON dbo.NashvilleHousing_Clean (PropertySplitCity);
GO

CREATE INDEX IX_NashvilleHousingClean_Parcel
ON dbo.NashvilleHousing_Clean (ParcelID);
GO


/* ---------------------------------------------------------
   9.7 Aperçu final
   --------------------------------------------------------- */
SELECT TOP 50 *
FROM dbo.NashvilleHousing_Clean
ORDER BY SaleDateConverted DESC;
GO

/* =========================================================
   STEP 10 – KPI & ANALYTICS QUERIES (BUSINESS-READY)
   Dataset : dbo.NashvilleHousing_Clean (GOLD layer)
   Purpose :
   - Provide real, decision-oriented KPIs for reporting (BI)
   - Support market analysis (trend, geography, segments)
   - Ensure metrics are based on clean/validated records
   ========================================================= */

USE [Nashville-Housing-DB];
GO

/* ---------------------------------------------------------
   10.0 DATA SCOPE / CONTROL
   Why: Always confirm the analysis perimeter (rows, dates).
   --------------------------------------------------------- */
SELECT
    COUNT(*) AS total_rows,
    MIN(SaleDateConverted) AS min_sale_date,
    MAX(SaleDateConverted) AS max_sale_date,
    SUM(CASE WHEN QualityFlag = 1 THEN 1 ELSE 0 END) AS quality_rows
FROM dbo.NashvilleHousing_Clean;
GO


/* =========================================================
   SECTION A — CORE MARKET KPIs (Global)
   ========================================================= */

/* ---------------------------------------------------------
   KPI A1 — Sales volume & total market value (Turnover)
   Why: High-level market size indicator.
   --------------------------------------------------------- */
SELECT
    COUNT(*) AS transactions_count,
    SUM(CAST(SalePrice AS BIGINT)) AS total_sales_value,
    AVG(CAST(SalePrice AS BIGINT)) AS avg_sale_price
FROM dbo.NashvilleHousing_Clean
WHERE SalePrice IS NOT NULL AND SalePrice > 0;
GO

/* ---------------------------------------------------------
   KPI A2 — Median price (robust to outliers)
   Why: Median is more stable than average in real estate.
   --------------------------------------------------------- */
SELECT DISTINCT
    PERCENTILE_CONT(0.5) 
        WITHIN GROUP (ORDER BY SalePrice)
        OVER () AS median_sale_price
FROM dbo.NashvilleHousing_Clean
WHERE SalePrice IS NOT NULL AND SalePrice > 0;
GO


/* ---------------------------------------------------------
   KPI A3 — Price distribution (Quartiles)
   Why: Understand spread and segmentation of the market.
   --------------------------------------------------------- */
/* ---------------------------------------------------------
   KPI A3 – Price distribution (Quartiles)
   Why: Understand market spread and segmentation
   --------------------------------------------------------- */
SELECT DISTINCT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY SalePrice) OVER () AS Q1,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY SalePrice) OVER () AS Median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY SalePrice) OVER () AS Q3
FROM dbo.NashvilleHousing_Clean
WHERE SalePrice IS NOT NULL AND SalePrice > 0;
GO


/* ---------------------------------------------------------
   KPI A4 — Price dispersion (Standard deviation)
   Why: Risk/variability indicator for market stability.
   --------------------------------------------------------- */
SELECT
    AVG(CAST(SalePrice AS FLOAT)) AS avg_price,
    STDEV(CAST(SalePrice AS FLOAT)) AS stdev_price
FROM dbo.NashvilleHousing_Clean
WHERE SalePrice IS NOT NULL AND SalePrice > 0;
GO


/* =========================================================
   SECTION B — TIME SERIES KPIs (Trends)
   ========================================================= */

/* ---------------------------------------------------------
   KPI B1 — Monthly trend (transactions, avg price, total value)
   Why: Classic BI view for seasonality and growth.
   --------------------------------------------------------- */
SELECT
    DATEFROMPARTS(YEAR(SaleDateConverted), MONTH(SaleDateConverted), 1) AS month_start,
    COUNT(*) AS transactions_count,
    AVG(CAST(SalePrice AS BIGINT)) AS avg_price,
    SUM(CAST(SalePrice AS BIGINT)) AS total_sales_value
FROM dbo.NashvilleHousing_Clean
WHERE SaleDateConverted IS NOT NULL
  AND SalePrice IS NOT NULL AND SalePrice > 0
GROUP BY DATEFROMPARTS(YEAR(SaleDateConverted), MONTH(SaleDateConverted), 1)
ORDER BY month_start;
GO

/* ---------------------------------------------------------
   KPI B2 — YoY (Year-over-Year) average price change
   Why: Growth metric used in executive reporting.
   --------------------------------------------------------- */
WITH yearly AS (
    SELECT
        YEAR(SaleDateConverted) AS sale_year,
        AVG(CAST(SalePrice AS FLOAT)) AS avg_price
    FROM dbo.NashvilleHousing_Clean
    WHERE SaleDateConverted IS NOT NULL
      AND SalePrice IS NOT NULL AND SalePrice > 0
    GROUP BY YEAR(SaleDateConverted)
)
SELECT
    sale_year,
    avg_price,
    (avg_price - LAG(avg_price) OVER (ORDER BY sale_year))
        / NULLIF(LAG(avg_price) OVER (ORDER BY sale_year), 0) * 100.0 AS yoy_avg_price_pct
FROM yearly
ORDER BY sale_year;
GO

/* ---------------------------------------------------------
   KPI B3 — Rolling 3-month average price (smoothing)
   Why: Reduces noise for decision-making.
   --------------------------------------------------------- */
WITH monthly AS (
    SELECT
        DATEFROMPARTS(YEAR(SaleDateConverted), MONTH(SaleDateConverted), 1) AS month_start,
        AVG(CAST(SalePrice AS FLOAT)) AS avg_price
    FROM dbo.NashvilleHousing_Clean
    WHERE SaleDateConverted IS NOT NULL
      AND SalePrice IS NOT NULL AND SalePrice > 0
    GROUP BY DATEFROMPARTS(YEAR(SaleDateConverted), MONTH(SaleDateConverted), 1)
)
SELECT
    month_start,
    avg_price,
    AVG(avg_price) OVER (ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3m_avg_price
FROM monthly
ORDER BY month_start;
GO


/* =========================================================
   SECTION C — GEOGRAPHY KPIs (City-level)
   ========================================================= */

/* ---------------------------------------------------------
   KPI C1 — City leaderboard (volume + avg price)
   Why: Identify high-demand / high-value areas.
   --------------------------------------------------------- */
SELECT
    PropertySplitCity AS city,
    COUNT(*) AS transactions_count,
    AVG(CAST(SalePrice AS BIGINT)) AS avg_price,
    SUM(CAST(SalePrice AS BIGINT)) AS total_sales_value
FROM dbo.NashvilleHousing_Clean
WHERE PropertySplitCity IS NOT NULL
  AND SalePrice IS NOT NULL AND SalePrice > 0
GROUP BY PropertySplitCity
ORDER BY total_sales_value DESC;
GO

/* ---------------------------------------------------------
   KPI C2 — Top 10 cities by average price (minimum volume filter)
   Why: Avoid ranking cities with too few transactions.
   --------------------------------------------------------- */
SELECT TOP 10
    PropertySplitCity AS city,
    COUNT(*) AS transactions_count,
    AVG(CAST(SalePrice AS BIGINT)) AS avg_price
FROM dbo.NashvilleHousing_Clean
WHERE PropertySplitCity IS NOT NULL
  AND SalePrice IS NOT NULL AND SalePrice > 0
GROUP BY PropertySplitCity
HAVING COUNT(*) >= 100   -- adjust threshold depending on your dataset size
ORDER BY avg_price DESC;
GO

/* ---------------------------------------------------------
   KPI C3 — Price segmentation by city (median per city)
   Why: More robust city comparison (less sensitive to outliers).
   --------------------------------------------------------- */
SELECT DISTINCT
    PropertySplitCity AS city,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY SalePrice)
        OVER (PARTITION BY PropertySplitCity) AS median_price_city
FROM dbo.NashvilleHousing_Clean
WHERE PropertySplitCity IS NOT NULL
  AND SalePrice IS NOT NULL AND SalePrice > 0
ORDER BY median_price_city DESC;
GO


/* =========================================================
   SECTION D — SEGMENT KPIs (Vacant vs Non-Vacant)
   ========================================================= */

/* ---------------------------------------------------------
   KPI D1 — SoldAsVacant impact on price & volume
   Why: Segment analysis (vacant vs non-vacant)
   --------------------------------------------------------- */
WITH s AS (
    SELECT
        SoldAsVacant,
        SalePrice,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY SalePrice)
            OVER (PARTITION BY SoldAsVacant) AS median_price
    FROM dbo.NashvilleHousing_Clean
    WHERE SoldAsVacant IS NOT NULL
      AND SalePrice IS NOT NULL
      AND SalePrice > 0
)
SELECT
    SoldAsVacant,
    COUNT(*) AS transactions_count,
    AVG(CAST(SalePrice AS BIGINT)) AS avg_price,
    MAX(median_price) AS median_price   -- MAX pour ramener 1 valeur par groupe
FROM s
GROUP BY SoldAsVacant
ORDER BY transactions_count DESC;
GO

/* ---------------------------------------------------------
   KPI D2 — Vacant share by city (rate)
   Why: Identify cities with high vacant transaction rates.
   --------------------------------------------------------- */
SELECT
    PropertySplitCity AS city,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN SoldAsVacant = 'Yes' THEN 1 ELSE 0 END) AS vacant_transactions,
    CAST(SUM(CASE WHEN SoldAsVacant = 'Yes' THEN 1 ELSE 0 END) AS FLOAT)
        / NULLIF(COUNT(*), 0) * 100.0 AS vacant_rate_pct
FROM dbo.NashvilleHousing_Clean
WHERE PropertySplitCity IS NOT NULL
GROUP BY PropertySplitCity
HAVING COUNT(*) >= 100
ORDER BY vacant_rate_pct DESC;
GO


/* =========================================================
   SECTION E — DATA QUALITY KPIs (Governance Reporting)
   ========================================================= */

/* ---------------------------------------------------------
   KPI E1 — QualityFlag distribution (should be 100% = 1)
   Why: Governance proof for enterprise analytics.
   --------------------------------------------------------- */
SELECT
    QualityFlag,
    COUNT(*) AS rows_count
FROM dbo.NashvilleHousing_Clean
GROUP BY QualityFlag;
GO

/* ---------------------------------------------------------
   KPI E2 — Critical NULL checks in the GOLD table
   Why: Ensure no key fields are missing for BI.
   --------------------------------------------------------- */
SELECT
    SUM(CASE WHEN SaleDateConverted IS NULL THEN 1 ELSE 0 END) AS null_sale_date,
    SUM(CASE WHEN SalePrice IS NULL OR SalePrice <= 0 THEN 1 ELSE 0 END) AS invalid_sale_price,
    SUM(CASE WHEN PropertySplitCity IS NULL OR LTRIM(RTRIM(PropertySplitCity)) = '' THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN PropertySplitAddress IS NULL OR LTRIM(RTRIM(PropertySplitAddress)) = '' THEN 1 ELSE 0 END) AS null_address
FROM dbo.NashvilleHousing_Clean;
GO

/* ---------------------------------------------------------
   KPI E3 — Duplicate check (should be 0)
   Why: Ensure analytics aren’t inflated by duplicates.
   --------------------------------------------------------- */
WITH DuplicateCheck AS (
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY
                ParcelID,
                PropertySplitAddress,
                SalePrice,
                SaleDateConverted,
                LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM dbo.NashvilleHousing_Clean
)
SELECT
    COUNT(*) AS remaining_duplicates_clean
FROM DuplicateCheck
WHERE row_num > 1;
GO


/* =========================================================
   SECTION F — EXECUTIVE SUMMARY (One view)
   ========================================================= */

/* ---------------------------------------------------------
   KPI F1 — Executive summary snapshot
   Why: Single query for executive reporting (global view)
   --------------------------------------------------------- */
WITH base AS (
    SELECT
        SalePrice,
        SaleDateConverted
    FROM dbo.NashvilleHousing_Clean
    WHERE SalePrice IS NOT NULL AND SalePrice > 0
      AND SaleDateConverted IS NOT NULL
),
w AS (
    SELECT
        SalePrice,
        SaleDateConverted,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY SalePrice) OVER () AS median_price
    FROM base
)
SELECT
    COUNT(*) AS transactions_count,
    SUM(CAST(SalePrice AS BIGINT)) AS total_sales_value,
    AVG(CAST(SalePrice AS BIGINT)) AS avg_price,
    MAX(median_price) AS median_price,         -- 1 valeur globale
    MIN(SaleDateConverted) AS period_start,
    MAX(SaleDateConverted) AS period_end
FROM w;
GO
















