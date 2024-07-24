-- Standardize Date Format
-- The dataset has been loaded using LOAD DATA INFILE with the date format YYYY/MM/DD, which is standard for MySQL.
-- If you need to convert the date format to YYYY-MM-DD, you can use the following queries:

-- View the conversion
-- SELECT SaleDate, STR_TO_DATE(SaleDate, '%Y/%m/%d') AS ConvertedDate
-- FROM NashvilleHousing;

-- Update the date format
-- UPDATE NashvilleHousing
-- SET SaleDate = STR_TO_DATE(SaleDate, '%Y/%m/%d');

-- Alternatively, create a new column for the converted date
-- SET SQL_SAFE_UPDATES = 0;

-- Replace blank fields with NULL
-- MySQL does not automatically convert blank fields to NULL, so we need to handle this manually.
UPDATE NashvilleHousing
SET 
    UniqueID = CASE WHEN TRIM(UniqueID) = '' THEN NULL ELSE UniqueID END,
    ParcelID = CASE WHEN TRIM(ParcelID) = '' THEN NULL ELSE ParcelID END,
    LandUse = CASE WHEN TRIM(LandUse) = '' THEN NULL ELSE LandUse END,
    PropertyAddress = CASE WHEN TRIM(PropertyAddress) = '' THEN NULL ELSE PropertyAddress END,
    SaleDate = CASE WHEN TRIM(SaleDate) = '' THEN NULL ELSE SaleDate END,
    SalePrice = CASE WHEN TRIM(SalePrice) = '' THEN NULL ELSE SalePrice END,
    LegalReference = CASE WHEN TRIM(LegalReference) = '' THEN NULL ELSE LegalReference END,
    SoldAsVacant = CASE WHEN TRIM(SoldAsVacant) = '' THEN NULL ELSE SoldAsVacant END,
    OwnerName = CASE WHEN TRIM(OwnerName) = '' THEN NULL ELSE OwnerName END,
    OwnerAddress = CASE WHEN TRIM(OwnerAddress) = '' THEN NULL ELSE OwnerAddress END,
    Acreage = CASE WHEN TRIM(Acreage) = '' THEN NULL ELSE Acreage END,
    TaxDistrict = CASE WHEN TRIM(TaxDistrict) = '' THEN NULL ELSE TaxDistrict END,
    LandValue = CASE WHEN TRIM(LandValue) = '' THEN NULL ELSE LandValue END,
    BuildingValue = CASE WHEN TRIM(BuildingValue) = '' THEN NULL ELSE BuildingValue END,
    TotalValue = CASE WHEN TRIM(TotalValue) = '' THEN NULL ELSE TotalValue END,
    YearBuilt = CASE WHEN TRIM(YearBuilt) = '' THEN NULL ELSE YearBuilt END,
    Bedrooms = CASE WHEN TRIM(Bedrooms) = '' THEN NULL ELSE Bedrooms END,
    FullBath = CASE WHEN TRIM(FullBath) = '' THEN NULL ELSE FullBath END,
    HalfBath = CASE WHEN TRIM(HalfBath) = '' THEN NULL ELSE HalfBath END;

-- Populate Missing Property Address Data
-- Identify and update missing PropertyAddress values using duplicates with non-null addresses.
SELECT *
FROM NashvilleHousing
-- WHERE PropertyAddress IS NULL;
ORDER BY ParcelID;

-- Find duplicates with missing addresses
-- Join the table with itself to find records with the same ParcelID but different UniqueID.
-- Use COALESCE to select the non-null PropertyAddress.
SELECT tableA.ParcelID, tableA.PropertyAddress, tableB.ParcelID, tableB.PropertyAddress, COALESCE(tableA.PropertyAddress, tableB.PropertyAddress) AS CorrectPropertyAddress
FROM NashvilleHousing AS TableA
JOIN NashvilleHousing AS TableB
    ON TableA.ParcelID = TableB.ParcelID
    AND TableA.UniqueID <> TableB.UniqueID
WHERE TableA.PropertyAddress IS NULL;

-- Update PropertyAddress with correct values
-- Update null PropertyAddress fields with values from duplicates.
UPDATE NashvilleHousing AS TableA
JOIN NashvilleHousing AS TableB
    ON TableA.ParcelID = TableB.ParcelID
    AND TableA.UniqueID <> TableB.UniqueID
SET TableA.PropertyAddress = COALESCE(TableA.PropertyAddress, TableB.PropertyAddress)
WHERE TableA.PropertyAddress IS NULL;

-- Split PropertyAddress into Address and City
-- Break down PropertyAddress into individual components.
SELECT 
    SUBSTRING_INDEX(PropertyAddress, ',', 1) AS Address,
    TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1)) AS City
FROM NashvilleHousing;

-- Add new columns and update with split data
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress VARCHAR(255),
ADD PropertySplitCity VARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1),
    PropertySplitCity = TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1));

-- Repeat for OwnerAddress
-- Break down OwnerAddress into Street, City, and State components.
SELECT 
    TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1)) AS OwnerAddressSplitStreet,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1)) AS OwnerAddressSplitCity,
    TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1)) AS OwnerAddressSplitState
FROM NashvilleHousing;

-- Add new columns and update with split data
ALTER TABLE NashvilleHousing
ADD OwnerAddressSplitStreet VARCHAR(255),
ADD OwnerAddressSplitCity VARCHAR(255),
ADD OwnerAddressSplitState VARCHAR(255);

UPDATE NashvilleHousing
SET OwnerAddressSplitStreet = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1)),
    OwnerAddressSplitCity = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1)),
    OwnerAddressSplitState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));

-- Standardize SoldAsVacant Values
-- Convert 'Y'/'N' to 'Yes'/'No'.
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

-- Apply the conversion
UPDATE NashvilleHousing
SET SoldAsVacant = CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;

-- Remove Duplicate Records
-- Use a Common Table Expression (CTE) to identify duplicates and remove them.
WITH RowNumCTE AS (
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
        ORDER BY UniqueID
    ) AS row_num
FROM NashvilleHousing
)

-- Check for duplicates
SELECT *
FROM RowNumCTE
WHERE row_num > 1;

-- Delete duplicate records
DELETE
FROM NashvilleHousing
WHERE UniqueID IN (
    SELECT UniqueID
    FROM (
        SELECT UniqueID
        FROM RowNumCTE
        WHERE row_num > 1
    ) AS Subquery
);

-- Drop Unused Columns
-- Remove columns that are no longer needed.
ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress;
