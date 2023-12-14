-- Create a forestation view query that joins all three tables on the columns indicated, and creates a new column by performing a calculation that compares two columns.
CREATE VIEW forestation AS
SELECT fa.country_code, fa.country_name, fa.year, fa.forest_area_sqkm,
       -- sqmi to sqkm conversion
       la.total_area_sq_mi*2.59 total_area_sqkm,
       -- forest area percentage
       (fa.forest_area_sqkm/(la.total_area_sq_mi*2.59))*100 forest_percentage,
        rg.region, rg.income_group
  FROM forest_area fa
INNER JOIN land_area la
    ON fa.country_code=la.country_code
   AND fa.year=la.year
INNER JOIN regions rg
    ON fa.country_code=rg.country_code;
  -- Select all columns
SELECT *
  FROM forestation;


-- 1) GLOBAL SITUATION
  -- a. What was the total forest area (in sq km) of the world in 1990? Please keep in mind that you can use the country record denoted as “World" in the region table.
  -- b. What was the total forest area (in sq km) of the world in 2016? Please keep in mind that you can use the country record in the table is denoted as “World.”
SELECT year,forest_area_sqkm
  FROM forestation
 WHERE (year=1990 or year=2016) AND country_name='World';

  -- c. What was the change (in sq km) in the forest area of the world from 1990 to 2016?
SELECT (pres.forest_area_sqkm - past.forest_area_sqkm) diff
  FROM forestation pres, forestation past
 WHERE pres.year=2016 AND past.year=1990
   AND pres.country_name='World' AND past.country_name='World';

  -- d. What was the percent change in forest area of the world between 1990 and 2016?
SELECT (pres.forest_area_sqkm-past.forest_area_sqkm)/ past.forest_area_sqkm*100 percent_change
  FROM forestation pres, forestation past
 WHERE pres.year=2016 AND past.year=1990
   AND pres.country_name='World' AND past.country_name='World';

  -- e. If you compare the amount of forest area lost between 1990 and 2016, to which country's total area in 2016 is it closest to?
SELECT country_name, total_area_sqkm
  FROM forestation
 WHERE year=2016 AND total_area_sqkm<1324449
ORDER BY total_area_sqkm DESC
 LIMIT 1;


-- 2) REGIONAL OUTLOOK
  --  Create a table that shows the Regions and their percent forest area (sum of forest area divided by the sum of land area) in 1990 and 2016. (Note that 1 sq mi = 2.59 sq km).
CREATE VIEW regional_forestation AS
SELECT f.region, f.year,
       SUM(f.forest_area_sqkm)/SUM(f.total_area_sqkm)*100 percent_forest_area
  FROM forestation f
  GROUP BY 1,2
  ORDER BY 1,2;
  -- Select all columns
  SELECT *
  FROM regional_forestation;

  -- a. What was the percent forest of the entire world in 2016? Which region had the HIGHEST percent forest in 2016, and which had the LOWEST, to 2 decimal places?
  -- b. What was the percent forest of the entire world in 1990? Which region had the HIGHEST percent forest in 1990, and which had the LOWEST, to 2 decimal places?
  -- c. Based on the table you created, which regions of the world DECREASED in forest area from 1990 to 2016?
SELECT pres.region,
       ROUND(CAST(pres.percent_forest_area AS numeric),2) percent_fa_2016,
       ROUND(CAST(past.percent_forest_area AS numeric),2) percent_fa_1990
  FROM regional_forestation pres, regional_forestation past
 WHERE pres.year=2016 AND past.year=1990
       AND pres.region=past.region
ORDER BY percent_fa_2016 DESC;


-- 3) COUNTRY-LEVEL DETAIL
  -- a. Which 5 countries saw the largest amount decrease in forest area from 1990 to 2016? What was the difference in forest area for each?
SELECT pres.country_name,
       pres.forest_area_sqkm-past.forest_area_sqkm difference
  FROM forestation pres
INNER JOIN forestation past
    ON (pres.year=2016 AND past.year=1990)
       AND pres.country_name=past.country_name
       AND pres.forest_area_sqkm-past.forest_area_sqkm>0
ORDER BY difference DESC
 LIMIT 5;

  -- b. Which 5 countries saw the largest percent decrease in forest area from 1990 to 2016? What was the percent change to 2 decimal places for each?
SELECT pres.country_name,pres.region,
	   ROUND(CAST(pres.forest_area_sqkm/past.forest_area_sqkm*100 AS numeric),2) percent_increase
  FROM forestation pres
INNER JOIN forestation past
    ON (pres.year=2016 AND past.year=1990)
       AND pres.country_name!='World'
       AND pres.country_name=past.country_name
       AND pres.forest_area_sqkm/past.forest_area_sqkm>0
ORDER BY percent_increase DESC
 LIMIT 5;
 -- Table 3.1: Top 5 Amount Decrease in Forest Area by Country, 1990 & 2016:
SELECT pres.country_name,pres.region,
	   ROUND(CAST(pres.forest_area_sqkm-past.forest_area_sqkm AS numeric),2) difference
  FROM forestation pres
INNER JOIN forestation past
    ON (pres.year=2016 AND past.year=1990)
       AND pres.country_name!='World'
       AND pres.country_name=past.country_name
ORDER BY difference
 LIMIT 5;
 -- Table 3.2: Top 5 Percent Decrease in Forest Area by Country, 1990 & 2016:
 SELECT pres.country_name,pres.region,
	   ROUND(CAST((pres.forest_area_sqkm/past.forest_area_sqkm-1)*100 AS numeric),2) percent_decrease
  FROM forestation pres
INNER JOIN forestation past
    ON (pres.year=2016 AND past.year=1990)
       AND pres.country_name!='World'
       AND pres.country_name=past.country_name
ORDER BY percent_decrease
 LIMIT 5;

  -- c. If countries were grouped by percent forestation in quartiles, which group had the most countries in it in 2016?
SELECT distinct(quartile_group), COUNT(country_name) OVER (PARTITION BY quartile_group) AS county_count
  FROM (SELECT country_name,
  		  CASE
    		WHEN forest_percentage < 25 THEN '0-25%'
			WHEN forest_percentage >= 25
             AND forest_percentage < 50 THEN '25-50%'
    		WHEN forest_percentage >= 50
	  		 AND forest_percentage < 75 THEN '50-75%'
    		ELSE '75-100%'
  			END AS quartile_group
 		FROM forestation
		WHERE year=2016 AND country_name!='World'
		AND forest_percentage IS NOT NULL) q;

  -- d. List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016.
SELECT country_name, region, ROUND(CAST(forest_percentage as numeric),2) forest_percentage
  FROM forestation
 WHERE year=2016 AND forest_percentage>75
ORDER BY forest_percentage DESC;

  -- e. How many countries had a percent forestation higher than the United States in 2016?
WITH table1 AS
	(SELECT country_name, year, forest_percentage
       FROM forestation
      WHERE year=2016 AND country_name!='World'
            AND forest_percentage IS NOT NULL
     ORDER BY forest_percentage DESC)
SELECT COUNT(t1.country_name)
  FROM table1 t1
 WHERE t1.forest_percentage>(SELECT t1.forest_percentage
                               FROM table1 t1
                              WHERE t1.country_name='United States');
