-- Cleaning Data in SQL Queries
SELECT * 
FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]

-- Standardize Data Format
SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]


ALTER TABLE portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
ADD SaleDateConverted Date;

update portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
SET SaleDateConverted = CONVERT(Date, SaleDate)

-- Popular Null Property Address data 
SELECT *
FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
order by ParcelID

SELECT a.ParcelID, a.PropertyAddress, c.ParcelID, c.PropertyAddress, ISNULL(a.PropertyAddress, c.PropertyAddress)
FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning] as a
join portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning] as c
    on a.ParcelID = c.ParcelID 
    AND a.[UniqueID] <> c.[UniqueID]
where a.PropertyAddress is null

UPDATE a 
SET PropertyAddress = ISNULL(a.PropertyAddress, c.PropertyAddress)
FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning] as a
join portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning] as c
    on a.ParcelID = c.ParcelID 
    AND a.[UniqueID] <> c.[UniqueID]
where a.PropertyAddress is null


-- Breaking out the PropertAddress into (Address, City, State)
SELECT PropertyAddress
FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+ 1, LEN(PropertyAddress)) as Address
FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]

ALTER TABLE portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
ADD PropertySplitAddress Nvarchar(500);

update portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
ADD PropertySplitCity Nvarchar(500);

update portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+ 1, LEN(PropertyAddress)) 

-- Breaking out OwnerAddress into (Address, City, State)
SELECT OwnerAddress
FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
---
SELECT 
-- Address (First part)
SUBSTRING(OwnerAddress, 1, CHARINDEX(',', OwnerAddress) -1) as Address,

-- City (Middle part - extremely difficult with Substring!)
SUBSTRING(OwnerAddress, 
          CHARINDEX(',', OwnerAddress) + 1, 
          CHARINDEX(',', OwnerAddress, CHARINDEX(',', OwnerAddress) + 1) - CHARINDEX(',', OwnerAddress) - 1
          ) as City,

-- State (Last Part)
SUBSTRING(OwnerAddress, CHARINDEX(',', OwnerAddress, CHARINDEX(',', OwnerAddress) + 1) + 1, LEN(OwnerAddress)) as State

FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]


-- Another way to Break out OwnerAddress into (Address, City, State) using parse
SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]

ALTER TABLE portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
ADD OwnerSplitAddress Nvarchar(500);

update portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)


ALTER TABLE portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
ADD OwnerSplitCity Nvarchar(500);

update portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
SET OwnerSplitCity= PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)


ALTER TABLE portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
ADD OwnerSplitState Nvarchar(500);

update portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Change Y and N in "SoldAsVacant" field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
GROUP BY SoldAsVacant
ORDER BY 2



SELECT SoldAsVacant
, CASE when SoldAsVacant = 'Y'THEN 'Yes'
       when SoldAsVacant = 'N' THEN 'No'
       ELSE SoldAsVacant
       END
FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]

UPDATE portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
SET SoldAsVacant = CASE when SoldAsVacant = 'Y'THEN 'Yes'
       when SoldAsVacant = 'N' THEN 'No'
       ELSE SoldAsVacant
       END

-- Remove Duplicates
WITH RowNumCTE AS (
SELECT*,
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
                 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
    ORDER BY
    UniqueID
    ) row_num
FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
)
DELETE 
FROM RowNumCTE
WHERE row_num > 1

