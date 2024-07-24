# Nashville Housing Data Cleaning

## Overview

This repository contains scripts and procedures for cleaning and standardizing the Nashville Housing dataset using MySQL. The goal is to address data inconsistencies, missing values, and formatting issues to prepare the dataset for analysis.

## Features

1. **Date Format Standardization**
   - Converts `SaleDate` to a standard `YYYY-MM-DD` format.

2. **Handling Blank Values**
   - Replaces blank fields with `NULL` across various columns.

3. **Address Correction**
   - Updates missing `PropertyAddress` values using duplicate records.
   - Splits `PropertyAddress` and `OwnerAddress` into individual columns (street, city, state).

4. **Data Normalization**
   - Converts 'Y'/'N' values in `SoldAsVacant` to 'Yes'/'No'.

5. **Duplicate Removal**
   - Identifies and removes duplicate records based on key fields.

6. **Column Management**
   - Deletes obsolete columns such as `OwnerAddress` and `TaxDistrict`.

# Usage

1. **Load Data**
   - Load your data into MySQL using LOAD DATA INFILE.

2. **Run Scripts**
   - Execute SQL scripts sequentially to clean and prepare the data.

# Dependencies
  - MySQL 8.0 or higher.

# Contact

For questions or contributions, please contact me at [Joshuaisaiah.caballero@gmail.com]
