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

