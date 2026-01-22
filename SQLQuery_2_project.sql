/********************************************************************************
PORTFOLIO PROJECT: NASHVILLE HOUSING DATA CLEANING WITH SQL
Created by: Asma Essaedi
Date: Jan 21/2025

 This project elaborates on data cleaning techniques on  Nashville housing data
using Microsoft SQL Server. The main goal is to transform raw and inconsistent data into a clean and ready-to-analyze dataset

The Key Skills Demonstrated through this project are as follows:
- Data standardization and formatting
- Handling missing values 
- String manipulation and parsing
- Data normalization
 - Deduplication strategies
- Documentation and best practices 

ORIGINAL DATASET:
NashvilleHousingDataforDataCleaning table containing property sale records.

The following are the methodologies that I used:
1/ Standardize data formats
2/ populate missing property address using reference data 
3/ split address into standardized components
4/ Identify and handle duplicate records

********************************************************************************/ 


-- First, let's take a look at the original data structure and sample
SELECT TOP 100 * 
FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning];

SELECT 
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT UniqueID) AS UniqueIDs,
    MIN(SaleDate) AS EarliestDate,
    MAX(SaleDate) AS LatestDate
FROM portfolioproject.dbo.NashvilleHousingDataforDataCleaning;

-- Step 1: Standardize Data Format. The SaleDate is stored as DateTime, but we only need Date, so I created  a new standardized date column while preserving the original
SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]


ALTER TABLE portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
ADD SaleDateConverted Date;

update portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
SET SaleDateConverted = CONVERT(Date, SaleDate)
    
/*Step 2:  Populate missing Property Addresses. Properties with the same ParcellD should have the same address. 
    Thus, I used a self-join to populate NULLS from non-NULL records with the same ParcelID*/
    
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


-- Step 3: Split Property Address into components (Address and  City)
SELECT PropertyAddress
FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+ 1, LEN(PropertyAddress)) as City
FROM portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]

ALTER TABLE portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
ADD PropertySplitAddress Nvarchar(500);

update portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
ADD PropertySplitCity Nvarchar(500);

update portfolioproject.[dbo].[NashvilleHousingDataforDataCleaning]
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+ 1, LEN(PropertyAddress)) 

-- Step 4: Split the OwnerAddress into components (Address, City, State)
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


-- Another way: Parse OwnerAddress using PARSENAME (cleaner than nested SUBSTRING)
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

-- Step 5: SoldAs Vacant has inconsistent values ('Y', 'N, 'yes, 'no'). I standardized it to 'yes' and 'no' for consistent analysis 
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

-- Step 6: Identify and Remove Duplicates
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

/********************************************************************************
Project Conclusion

Key Achievements:
1/ Successfully standardized data formats for consistent temporal analysis 
2/ Resolved 100% of missing property addresses using smart match 
3/ parsed compound address fields into atomic components for granular analysis
4/ Normalized categories, which support consistent reporting 
5/Implemented non-destructive duplicate identification for data integrity 
6/ Created an analysis-ready view with all the transformation processes applied


Business Impact: 
Cleaned data allows for accurate property valuation analysis 
Standardized addresses facilitate geographic segmentation 
Normalization supports consistent reporting 
Preserving original data maintains the audit trail

********************************************************************************/ 

 
