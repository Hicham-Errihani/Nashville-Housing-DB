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














