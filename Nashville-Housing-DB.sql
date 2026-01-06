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












