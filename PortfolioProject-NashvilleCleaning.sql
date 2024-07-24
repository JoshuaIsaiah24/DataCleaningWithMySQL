-- Standardize Date Format
-- I have uploaded the dataset via LOAD DATA INFILE. So I have already fixed the date format to YYYY/MM/DD which is standard to MySQL
-- In case you want to change the date format you can run the following query below:

-- SELECT SaleDate, STR_TO_DATE(SaleDate, '%Y-%M-%D') as ConvertedDate
-- FROM NashvilleHousing;

-- UPDATE NashvilleHousing
-- SET SaleDate = STR_TO_DATE(SaleDate, '%Y-%M-%D');

-- or you can also create a new column to add a the converted date from text to the correct data type


SET SQL_SAFE_UPDATES = 0;


-- MySQL doesn't turn blank datas into NULL
-- So I need to make sure that the workbench will show NULL for blank when we execute the query

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

-- Populate Property Address Data

SELECT *
FROM nashvillehousing
-- WHERE PropertyAddress is NULL;
ORDER BY ParcelID;

-- In this query, we have duplicate parcel ids but different unique ids that has the null values on property address
-- We want to make sure that we get the correct address and update it to the null value

-- this query we're performing self join to check the duplicate IDs with null values.
-- we are using the COALESCE function to show the PropertyAddress on a new column.
SELECT tableA.ParcelID, tableA.PropertyAddress, tableB.ParcelID, tableB.PropertyAddress, COALESCE(tableA.PropertyAddress, tableB.PropertyAddress) as CorrectPropertyAddress
FROM NashvilleHousing TableA
JOIN NashvilleHousing TableB
	on tableA.ParcelID = tableB.ParcelID
    and tableA.UniqueID <> tableB.UniqueID;
WHERE TableA.PropertyAddress is NULL;

-- updating the null values with the correct address
-- after performing the query below, if you run the select statement above, it should no longer show any output.
-- Thus, removing all the null values in Property address with duplicate parcels but different unique IDs.
UPDATE NashvilleHousing TableA
JOIN NashvilleHousing TableB
    ON TableA.ParcelID = TableB.ParcelID
    AND TableA.UniqueID <> TableB.UniqueID
SET TableA.PropertyAddress = COALESCE(TableA.PropertyAddress, TableB.PropertyAddress)
WHERE TableA.PropertyAddress IS NULL;

-- breaking out Address into individual columns (address, city, state) for PropertyAddress:

SELECT 
    SUBSTRING_INDEX(PropertyAddress, ',', 1) AS Address,
    TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1)) AS City
FROM NashvilleHousing;

-- Updating the table with the split stress address and city

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress VARCHAR (255);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity VARCHAR (255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1);

UPDATE NashvilleHousing
SET PropertySplitCity = TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1));


-- doing the same for the OwnerAddress:

SELECT 
TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1)) AS OwnerAddressSplitStreet,
TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1)) AS OwnerAddressSplitCity,
TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1)) AS OwnerAddressSplitState
FROM nashvillehousing;

-- updating the table

ALTER TABLE NashvilleHousing
ADD OwnerAddressSplitStreet VARCHAR (255);

ALTER TABLE NashvilleHousing
ADD OwnerAddressSplitCity VARCHAR (255);

ALTER TABLE NashvilleHousing
ADD OwnerAddressSplitState VARCHAR (255);

UPDATE NashvilleHousing
SET OwnerAddressSplitStreet = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1));

UPDATE NashvilleHousing
SET OwnerAddressSplitCity = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1));

UPDATE NashvilleHousing
SET OwnerAddressSplitState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));


-- Change Y and N to Yes and No in "Sold as Vacant" field:

-- checking the distinct values in the column
SELECT Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM NashvilleHousing
Group by SoldAsVacant
Order by 2;

-- Making a case statement that will allow us to change the Y to Yes and N and to No
SELECT SoldAsVacant,
CASE
	When SoldAsVacant = 'Y' then 'Yes'
    When SoldAsVacant = 'N' then 'No'
    Else SoldAsVacant
END as Adjusted
FROM NashvilleHousing;

-- Updating the table
UPDATE nashvillehousing
SET SoldAsVacant = CASE
	When SoldAsVacant = 'Y' then 'Yes'
    When SoldAsVacant = 'N' then 'No'
    Else SoldAsVacant
END;

-- Remove Duplicates:

WITH RowNumCTE AS (
SELECT *,
	row_number() OVER(
    partition by ParcelID,
				PropertyAddress,
                SalePrice,
                SaleDate,
                LegalReference
                Order by
					UniqueID) as row_num
FROM nashvillehousing
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1;

-- In MySQL, you cannot delete directly from the CTE created (in this case RowNumCTE)
-- What you can do is to run a subquery to identify the rows based on the row numbers assigned in the CTE
-- In this case, UniqueID will be used to get the rows out from RowNumCTE
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


-- Delete unused columns
-- Since we no longer need the OwnerAddress and PropertyAddress, we can delete those together with the TaxDistrict

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress;
