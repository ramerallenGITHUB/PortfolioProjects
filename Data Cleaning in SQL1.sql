-- Cleaning Data in SQL Queries

Select *
From PortfolioProject..NashvilleHousing

----------------------------------------------------------------------------------

-- Standardize Date Format

Select SaleDateConverted, Convert(Date, SaleDate)
From PortfolioProject..NashvilleHousing

Update Nashvillehousing
Set SaleDate = Convert(Date, SaleDate)

-- or using Alter Table

Alter Table NashvilleHousing
Add SaleDateConverted Date;

Update Nashvillehousing
Set SaleDateConverted = Convert(Date, SaleDate)

-- then we can probably remove SaleDate or not in the table

----------------------------------------------------------------------------------

-- Populate Property Address Data

Select *
From PortfolioProject..NashvilleHousing
Where PropertyAddress is null
order by ParcelID

-- So there will be datas that are null but there are reference datas that are the same and corresponding to the missing data, 
-- we just have to use the reference data to fill in the void
-- ParcelID is always not null, and through observations, it can be observed that ParcelID is corresponding to PropertyAddress
-- Basically there are rows with the same ParcelID wherein their PropertyAddress are the same as well but there are some where PropertyAddress are seen as Null
-- So we join the same table on ParcelID

Select *
From PortfolioProject..NashvilleHousing a
Join PortfolioProject..NashvilleHousing b
	 on a.ParcelID = b.ParcelID
	 and a.[UniqueID ] <> b.[UniqueID ] -- Here, through observations on the database, we can see that even if ParcelID has pairs, their UniqueID still differs

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
From PortfolioProject..NashvilleHousing a
Join PortfolioProject..NashvilleHousing b
	 on a.ParcelID = b.ParcelID
	 and a.[UniqueID ] <> b.[UniqueID ] 
Where a.PropertyAddress is null -- we only made it so that we can only see the Null for a, but not for b so we can see its corresponding pair that is not null

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) -- ISNULL(will be replaced if NULL, what will be replaced with)
From PortfolioProject..NashvilleHousing a
Join PortfolioProject..NashvilleHousing b
	 on a.ParcelID = b.ParcelID
	 and a.[UniqueID ] <> b.[UniqueID ] 
Where a.PropertyAddress is null 

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
Join PortfolioProject..NashvilleHousing b
	 on a.ParcelID = b.ParcelID
	 and a.[UniqueID ] <> b.[UniqueID ] 
Where a.PropertyAddress is null 

----------------------------------------------------------------------------------

-- Breaking out Address into Individual (Address, City, State)

Select PropertyAddress
From PortfolioProject..NashvilleHousing

-- ex data: 207 3RD AVE N, NASHVILLE
-- our goal this time is to separate through Address, City and State

Select 
	 Substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address						-- CHARINDEX('separator', variable) while Substring(Variable, 1, untilwhere?) ALSO CHARINDEX() searches for a specific substring in a string and gives out its index position, we then subtract it by 1 to remove the comma
	,Substring(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, Len(PropertyAddress)) as City		
From PortfolioProject..NashvilleHousing

-- Create two new columns that will represent the Address and City 
Alter Table PortfolioProject..NashvilleHousing
Add PropertySplitAddress nvarchar(255);

Update PortfolioProject..NashvilleHousing
Set PropertySplitAddress = Substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

Alter Table PortfolioProject..NashvilleHousing
Add PropertySplitCity nvarchar(255);

Update PortfolioProject..NashvilleHousing
Set PropertySplitCity = Substring(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, Len(PropertyAddress))

Select PropertySplitAddress, PropertySplitCity
From PortfolioProject..NashvilleHousing

-- Now for Owner Address (address, city and state)

Select OwnerAddress
From PortfolioProject..NashvilleHousing

-- Substring is actually very hassle so we'll use something else
-- Parsename(Variable, 1) Parsename only looks for periods so we replace all the commas with periods

Select
parsename(replace(OwnerAddress,',','.'), 3) as Address
,parsename(replace(OwnerAddress,',','.'), 2) as City
,parsename(replace(OwnerAddress,',','.'), 1) as State
From PortfolioProject..NashvilleHousing

-- parsename function takes things backwards, from right to left 

-- Now adding them in the DataBase

Alter Table PortfolioProject..NashvilleHousing
Add OwnerSplitAddress nvarchar(255)

Update PortfolioProject..NashvilleHousing
set OwnerSplitAddress = parsename(replace(OwnerAddress,',','.'), 3) 

Alter Table PortfolioProject..NashvilleHousing
Add OwnerSplitCity nvarchar(255)

Update PortfolioProject..NashvilleHousing
set OwnerSplitCity = parsename(replace(OwnerAddress,',','.'), 2) 

Alter Table PortfolioProject..NashvilleHousing
Add OwnerSplitState nvarchar(255)

Update PortfolioProject..NashvilleHousing
set OwnerSplitState = parsename(replace(OwnerAddress,',','.'), 1) 

Select OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
From PortfolioProject..NashvilleHousing

----------------------------------------------------------------------------------

--Change Y and N to Yes and No in "Sold as Vacant" Field

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From PortfolioProject..NashvilleHousing
group by SoldAsVacant
order by 2

Select SoldAsVacant, 
Case
	When SoldAsVacant = 'Y' Then 'Yes'
	When SoldAsVacant = 'N' Then 'No'
	Else SoldAsVacant
End As FixedSoldAsVacant
From PortfolioProject..NashvilleHousing

Update PortfolioProject..NashvilleHousing
Set SoldAsVacant = 
Case
	When SoldAsVacant = 'Y' Then 'Yes'
	When SoldAsVacant = 'N' Then 'No'
	Else SoldAsVacant
End

----------------------------------------------------------------------------------

-- Remove Duplicates Through CTE

-- make a query first then put it in the CTE

Select *,
	ROW_NUMBER() over (
	Partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
						  UniqueID
					   ) as row_num
From PortfolioProject..NashvilleHousing

-- so having this, we now put it inside a CTE

With RowNumCTE As  (
Select *,
	ROW_NUMBER() over (
	Partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
						  UniqueID
					   ) as row_num
From PortfolioProject..NashvilleHousing
)
Select *
From RowNumCTE
where row_num > 1

-- So now using the CTE, we can delete the ones with row_num > 1

With RowNumCTE As  (
Select *,
	ROW_NUMBER() over (
	Partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
						  UniqueID
					   ) as row_num
From PortfolioProject..NashvilleHousing
)
Delete From RowNumCTE
where row_num > 1

----------------------------------------------------------------------------------

-- Delete Unused Columns
-- We made splitcolumns, so all we have to do now is remove the once where we split them from
-- Also, we'll remove parts that we may not deem useful?

Alter Table PortfolioProject..NashvilleHousing
Drop Column OwnerAddress, PropertyAddress, TaxDistrict

Select *
From PortfolioProject..NashvilleHousing

-- remove saledate too

Alter Table PortfolioProject..NashvilleHousing
Drop Column SaleDate
