-- Lets clean some data !

SELECT *
FROM `coursera-work-351201.NashvilleHousingData.NashvilleHousing`





-- Standardize Date Format

SELECT SaleDate, PARSE_DATE('%B %d, %Y', SaleDate) AS SaleDate1
FROM `coursera-work-351201.NashvilleHousingData.NashvilleHousing`






-- Now I have to replace the column in the table with the updated date column, but unfortunately I have to pay for DML statements. Below is the function I'd use to update the table. In the job position, I'd actually use a temp table to do all this. 

UPDATE `coursera-work-351201.NashvilleHousingData.NashvilleHousing`
SET SaleDate = PARSE_DATE('%B %d, %Y', SaleDate)








-- Lets fill in blank spaces in the column "PropertyAddress." 

SELECT *
FROM `coursera-work-351201.NashvilleHousingData.NashvilleHousing`
WHERE PropertyAddress IS NULL
ORDER BY ParcelID








-- When observing the data organized by ParcelID, we can see that there are repeating ParcelID where the address are same and that UniqueID can be primary key. So, lets join the same table on itself with UniqueID being the primary key.

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM `coursera-work-351201.NashvilleHousingData.NashvilleHousing` a
JOIN `coursera-work-351201.NashvilleHousingData.NashvilleHousing` b
ON a.ParcelID = b.ParcelID
AND a.UniqueID_ != b.UniqueID_
WHERE a.PropertyAddress IS NULL







-- Now to update the original table, however we still won't pay for DML statements, so this is the query I'd run to update it

UPDATE a
SET PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM `coursera-work-351201.NashvilleHousingData.NashvilleHousing` a
JOIN `coursera-work-351201.NashvilleHousingData.NashvilleHousing` b
ON a.ParcelID = b.ParcelID
AND a.UniqueID_ != b.UniqueID_
WHERE a.PropertyAddress IS NULL







-- Now let's split the PropertyAddress into city Address, city and state. It's simple in BigQuery.


SELECT
SPLIT(PropertyAddress, ',')[SAFE_OFFSET(0)] AS PropertySplitAddress,
TRIM(SPLIT(PropertyAddress, ',')[SAFE_OFFSET(1)]) AS PropertySplitCity
FROM `coursera-work-351201.NashvilleHousingData.NashvilleHousing`

ALTER TABLE `coursera-work-351201.NashvilleHousingData.NashvilleHousing`
ADD COLUMN PropertySplitAddress STRING,
ADD COLUMN PropertySplitCity STRING;

UPDATE `coursera-work-351201.NashvilleHousingData.NashvilleHousing`
SET
PropertySplitAddress = SPLIT(PropertyAddress, ',')[SAFE_OFFSET(0)],
PropertySplitCity = TRIM(SPLIT(PropertyAddress, ',')[SAFE_OFFSET(1)]);









-- We also have the OwnerAddress column that needs to split, however this column has a second delimiter which includes a state.

SELECT
TRIM(SPLIT(OwnerAddress, ',')[SAFE_OFFSET(0)]) AS OwnerAddressSplit,
TRIM(SPLIT(OwnerAddress, ',')[SAFE_OFFSET(1)]) AS OwnerAddressCity,
TRIM(SPLIT(OwnerAddress, ',')[SAFE_OFFSET(2)]) AS OwnerAddressState
FROM `coursera-work-351201.NashvilleHousingData.NashvilleHousing`








-- Lets check for and remove duplicates! If we use SaleDate and PropertyAddress to check, theres no way that a home can be sold more than once on the same date.

SELECT SaleDate, PropertyAddress, LegalReference, COUNT(*) AS duplicate_count
FROM `coursera-work-351201.NashvilleHousingData.NashvilleHousing`
GROUP BY SaleDate, PropertyAddress, LegalReference
HAVING COUNT(*) > 1;


-- We can see that there are multiple duplicate values thorughout. In Google's BigQuery, if you want to create a temp table you'll need to run it as a script. So I simply wrote the following (the second part is just to check to see if the duplicates have been removed from temp_table):

CREATE TEMPORARY TABLE temp_table AS (
SELECT DISTINCT SaleDate, PropertyAddress, LegalReference
FROM `coursera-work-351201.NashvilleHousingData.NashvilleHousing`
);

SELECT SaleDate, PropertyAddress, LegalReference, COUNT(*) AS duplicate_count
FROM temp_table
GROUP BY SaleDate, PropertyAddress, LegalReference
HAVING COUNT(*) > 1;

