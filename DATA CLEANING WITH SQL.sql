
SELECT * FROM LAYOFFs;

-- DATA CLEANING
/* Step 1
Make a copy of RAW Data so as to always have a backup.
*/
		-- creating structure for layoff table with columns
        DROP TABLE layoff_staging;
		CREATE TABLE layoff_staging
		LIKE Layoffs;

		SELECT * 
		FROM layoff_staging;

		-- LOADING DATA to NEW TABLE
		INSERT INTO layoff_staging
		SELECT * FROM layoffs;

		SELECT * FROM layoff_staging;
        
/* STEP 2 - IDENTIFY THE DUPLICATES

		-- use ROW_NUMBER() function to search duplicates
*/
        SELECT *,
			ROW_NUMBER() OVER(
            PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
        FROM layoff_staging;
        
       -- USING CTE TO IDENTIFY DUPLICATES WHERE ROW_NUMBER IS > 1
       WITH duplicate_cte AS
       (
		SELECT *,
			ROW_NUMBER() OVER(
            PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
        FROM layoff_staging
       )
       SELECT * 
       FROM duplicate_cte
       WHERE row_num >1;
       
/* STEP 3 - INSERTING DATA to NEW TABLE */
       -- SELECT a row and verfiy its duplicacy
       SELECT * 
       FROM layoff_staging
       WHERE company = 'Casper';

-- DELETE is not possible with CTE hence we move to Stage 2 and copy all data where row_num =1 to a new Table layoff_staging2     
CREATE TABLE `layoff_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM layoff_staging2;

-- INSERTING OF DATA
INSERT INTO layoff_staging2
SELECT *,
		ROW_NUMBER() OVER(
		PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoff_staging;

-- CHECK FOR DUPLICATE RECORDS
SELECT * FROM layoff_staging2
WHERE row_num > 1;

-- DELETE DUPLICATE RECORDS
DELETE FROM layoff_staging2
WHERE row_num > 1;


/*------------STAGING 2 with STANDARDIZE the DATA------------*/

SELECT *
 FROM layoff_staging2;
 
 -- TRIMMING the white spaces
 UPDATE layoff_staging2 
 SET company = TRIM(company);
 
 -- moving on to 2nd column Industry for cleaning
 
 SELECT distinct industry 
 FROM layoff_staging2
 ORDER BY 1;
 
 -- FROM above query we identify that "CRYPTO" is being used by different names so we will change all of them to one.
 SELECT * 
 FROM layoff_staging2
 WHERE industry LIKE '%crypto%'
 ORDER BY industry;
 
 -- UPDATE this to all same name
 UPDATE layoff_staging2
 SET industry = 'Crypto'
 WHERE industry LIKE 'crypto%';
 
 -- check country 
 SELECT DISTINCT country,TRIM(Trailing '.' FROM country) From layoff_staging2
 ORDER BY 1;
 
 -- we find that united states has been repeated
 UPDATE layoff_staging2 
 SET country = TRIM(Trailing '.' FROM country)
 WHERE country LIKE 'United States%';
 
 -- Playing with DATE 
 SELECT `date`
 FROM layoff_staging2;
 
 -- update the date column
 UPDATE layoff_staging2 
 SET `date` = str_to_date(`date`, '%m/%d/%Y');
 
 -- CLEANING total_Laid_off and percentage_laid_off
 SELECT * 
 FROM layoff_staging2
 WHERE  total_laid_off IS NULL
 AND percentage_laid_off IS NULL;
 
 /* While going through industry we find that there were some industry with NULL and BLANK vlaue
 SO we get there and check and update the values 
 https://youtu.be/4UltKCnnnTA?si=3C12_SsY5kbEmZrO&t=2659
 */
 
 SELECT *
 FROM layoff_staging2
 order by industry;  -- gives output with some of industry as null and blank
 
 -- to fix this we go with self join and find relevant industry


SELECT *
FROM layoff_staging2
WHERE industry IS NULL; -- HERE we see that 'airbnb' is from travel

 SELECT *
 FROM layoff_staging2 t1
 JOIN layoff_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS NULL
OR t1.industry = '';

UPDATE layoff_staging2
SET industry = null
WHERE industry = '';

UPDATE layoff_staging2 t1
JOIN layoff_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM layoff_staging2
WHERE industry IS NULL
order by 2;

-- NOW MOVING TO FURTHER column total_laid_off and percentage_laid_off we filter on NULL
SELECT *
FROM layoff_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

DELETE 
FROM layoff_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

-- NOW REMOVING COLUMN
ALTER TABLE layoff_staging2
DROP COLUMN row_num;

SELECT * FROM layoff_staging2;

/* NEXT PROJECT IS EDA of the same database*/

SELECT max(total_laid_off),max(percentage_laid_off)
FROM layoff_staging2;

-- TOTAL LAID OFF YEAR WISE
SELECT YEAR(`date`),sum(total_laid_off)
FROM layoff_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- Rolling total of layoff based on YEAR-months

-- FIRST FIND TOTAL LAID OFF ON YEAR MONTH basis
SELECT substring(`date`,1,7) As `month`,
sum(total_laid_off)
FROM layoff_staging2
WHERE substring(`date`,1,7) IS NOT NULL
group by `month`
ORDER BY 1 asc;

-- FOR ROOLING TOTAL WE USE CTE AND WINDOW FUNCTION 
WITH Rolling_Total AS 
(
SELECT substring(`date`,1,7) As `month`,
sum(total_laid_off) AS TOTAL_OFF
FROM layoff_staging2
WHERE substring(`date`,1,7) IS NOT NULL
group by `month`
ORDER BY 1 asc
)
 SELECT `MONTH`,Total_off, SUM(TOTAL_OFF) OVER ( ORDER BY `MONTH`) AS Rolling_Total
 FROM Rolling_Total;
 
 -- TOTAL LAID OFF BY COMPANY ON YEAR BREAK_UP
  SELECT COMPANY,YEAR(`date`),SUM(total_laid_off)
  FROM layoff_staging2
  GROUP BY company, YEAR(`date`)
  ORDER BY 3 DESC;
  
  -- NOW we need to rank the company on this data 
  -- GEETING COMPANY DATA YEAR WISE
  WITH company_year(company,years,total_laid_off) AS 
  (
  SELECT COMPANY,YEAR(`date`),SUM(total_laid_off)
  FROM layoff_staging2
  GROUP BY company, YEAR(`date`)
  ORDER BY 3 DESC
  ),
  -- GETTING RANK FOR COMPANY USING WINDOW FUNCTION
  Company_Year_Rank AS
  (
  SELECT *, DENSE_RANK() OVER (partition by years order by total_laid_off DESC) as Rnk
  FROM company_year
  WHERE years IS NOT NULL
  ) 
  -- FETCHING TOP 5 COMPANY ON YEAR WISE
  SELECT * 
  FROM Company_year_rank
  WHERE Rnk <= 5;
