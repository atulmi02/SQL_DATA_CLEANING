# LAYOFF_DATA_CLEANING & EDA (SQL PROJECT)
This project focuses on how to clean raw layoff data and perform EDA using MYSQL.
The workflow follows the systematic approach:-
1. Creating Staging table
2. Cleaning duplicates
3. Standardizing data
4. Analyzing layoff trends
---

# PROJECT STEPS
## 1. Create Stage Tables
Backed up raw data into staging table `layoff_staging`.
```SQL
CREATE TABLE layoff_staging LIKE layoffs;
INSERT INTO layoff_staging SELECT * FROM layoffs;
```

 ## 2. Identify & Remove Duplicates
 Used `Row_Number()` with `Partition By` to identify duplicates.
 Created `layoff_staging2` to remove duplicates by keeping `row_num=1`.
```SQL
WITH duplicate_cte AS (
  SELECT *, 
         ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
                        `date`, stage, country, funds_raised_millions
         ) AS row_num
  FROM layoff_staging
)
SELECT * FROM duplicate_cte WHERE row_num > 1;
```

## 3. Standardize & Clean Data
- Company names - Trimmed white spaces
- Industry - Normalized variances (Crypto,Crypto Currency - Crypto)
- Country - Fixed Inconsistencies (United States. - United States)
- Date Column - Converted text to proper `DATE` format with `str_to_date()`
- Dropped helper column after cleaning i.e `row_num`.

## 4. Exploratory Data Analysis
- Maximum Layoff
- Yearly Total Layoff
- Rolling Monthly Layoff
- Company Layoff by Year (Ranked)

---

## KEY CONCEPT USED
- Window Functions: `Row_Number()`, `Dense_Rank()`,`Sum()Over`
- `CTE` for modular queries.
- String function: Trim(), SubString()
- Date Conversion: STR_TO_DATE()
- Data CLeaning with UPDATE and DELETE.

---
## INSIGHTS FROM EDA 
- **2022-2023** has highest number of layoff.
- **Tech and Crypto** hit the hardest.
- **Top Companies** like *Google,Meta and Amazon* frequently appear in top 5.

 
