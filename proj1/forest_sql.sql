--JOIN tables together
SELECT * FROM land_area l
JOIN forest_area f
ON l.country_code = f.country_code AND l.year = f.year
JOIN regions r
ON r.country_code = l.country_code


DROP VIEW IF EXISTS forestation;
CREATE VIEW forestation
AS 
SELECT 	l.country_code,l.country_name,l.year,
		r.region, r.income_group, l.total_area_sq_mi,
        f.forest_area_sqkm,
		(100*f.forest_area_sqkm) / (l.total_area_sq_mi * 2.59) AS pct_forest_land 
FROM land_area l
JOIN forest_area f
ON l.country_code = f.country_code AND l.year = f.year
JOIN regions r
ON r.country_code = l.country_code



--1a, 1b What was the total forest area (in sq km) of the world in 1990 and 2016
SELECT 	country_name,year,total_area_sq_mi,
		round(forest_area_sqkm) AS forest_area_sq_km FROM forestation
WHERE country_name = 'World' AND year in (1990,2016)


--1c and d What was the change (in sq km) in the forest area of the world FROM 1990 to 2016?
SELECT 	(a.pct_forest_land - b.pct_forest_land ) AS percent_difference,
		(a.forest_area_sqkm - b.forest_area_sqkm ) AS forest_difference
FROM forestation a,forestation b
WHERE 	a.year=1990 AND b.year=2016 AND a.country_name='World' AND 
		a.country_name=b.country_name

--e. If you compare the amount of forest area lost between 1990 and 2016, to which country's total area in 2016 is it closest to?
SELECT country_name, total_area_sq_mi*2.59 AS square_km
FROM forestation 
WHERE year='2016' AND total_area_sq_mi * 2.59 < 1324449
ORDER BY 2 DESC
LIMIT 1

--2. REGIONAL OUTLOOK
--Create a table that shows the Regions and their percent forest area in 1990 and 2016
CREATE TABLE regional_outlook AS 
(
	SELECT f.year, r.region,
	ROUND(CAST((SUM(f.forest_area_sqkm)*100)/(sum(l.total_area_sq_mi*2.59))AS NUMERIC),2) AS forest_area_percentage
	FROM forest_area f
	JOIN land_area l
	ON f.country_code=l.country_code AND f.year=l.year
	JOIN regions r
	ON r.country_code=f.country_code
	WHERE f.year IN(1990, 2016)
	Group by 2,1
);

--a. What was the percent forest of the entire world in 2016? Which region had the HIGHEST percent forest in 2016,
--and which had the LOWEST, to 2 decimal places?
SELECT * FROM regional_outlook
WHERE year = 2016
ORDER BY forest_area_percentage DESC

--b What was the percent forest of the entire world in 1990? Which region had the HIGHEST percent forest in 1990,
-- and which had the LOWEST, to 2 decimal places?
SELECT * FROM regional_outlook
WHERE year = 1990
ORDER BY forest_area_percentage DESC



--c Based ON the table you created, which regions of the world DECREASED in forest area FROM 1990 to 2016?
SELECT 	region,(a.forest_area_sqkm - b.forest_area_sqkm ) AS forest_difference
FROM regional_outlook a,regional_outlook b
WHERE 	a.year=1990 AND b.year=2016

--this shows all the changes per region per year
SELECT * FROM regional_outlook
ORDER BY region, year

--this gives the percent change FROM 1990 to 2016
SELECT a.region,(b.forest_area_percentage - a.forest_area_percentage) AS pct_change
FROM regional_outlook a
JOIN regional_outlook b
ON a.region = b.region
WHERE a.year = 1990 AND b.year = 2016

--3. COUNTRY-LEVEL DETAIL
--B Largest Concerns
--a. Which 5 countries saw the largest amount decrease in forest area FROM 1990 to 2016? What was the difference in forest area for each?
SELECT a.country_name,a.region,(b.forest_area_sqkm - a.forest_area_sqkm) AS forest_area_change
FROM forestation a
JOIN forestation b
ON a.country_name = b.country_name
WHERE a.year = 1990 AND b.year = 2016 AND a.country_name <> 'World'
ORDER BY forest_area_change
LIMIT 5


--b. Which 5 countries saw the largest percent decrease in forest area FROM 1990 to 2016? What was the percent change to 2 decimal places for each?
SELECT 	a.country_name, b.region,
		ROUND(CAST (( (b.forest_area_sqkm - a.forest_area_sqkm) *100/a.forest_area_sqkm) AS NUMERIC),2) AS percent_change
FROM forestation a
JOIN forestation b
ON a.country_name=b.country_name AND a.country_name <> 'World'
WHERE a.year=1990 AND b.year=2016
ORDER BY percent_change
LIMIT 5


--c. If countries were grouped by percent forestation in quartiles, which group had the most countries in it in 2016?
--SELECT f.country_name, pct_forest_land,
--Case When pct_forest_land >75 THEN 'Quartile4'
--When pct_forest_land >50 AND pct_forest_land <75 THEN 'Quartile3'
--When pct_forest_land >25 AND pct_forest_land <50 THEN 'Quartile2'
--When pct_forest_land <25 THEN 'Quartile1'
--End
--From forestation f
--Where f.year='2016' AND pct_forest_land is not null AND region <> 'World'
--Order By 2,1 DESC


--3. COUNTRY-LEVEL DETAIL
--SUCCESS STORIES
--iceland
SELECT a.country_name, a.pct_forest_land AS Forest_area_1990,
 	b.pct_forest_land AS Forest_area_2016,
 	abs(a.pct_forest_land  - b.pct_forest_land)/a.pct_forest_land*100 AS increase FROM forestation a 
 	JOIN forestation b ON a.country_name = b.country_name WHERE a.year = 1990 AND b.year = 2016
 	 AND a.pct_forest_land < b.pct_forest_land ORDER BY increase desc ;

--China & USA
SELECT a.country_name,a.region,
round(cast((a.forest_area_sqkm - b.forest_area_sqkm)AS numeric),2) AS forest_area_change
FROM forestation a
JOIN forestation b
ON a.country_name = b.country_name
WHERE a.year = 1990 AND b.year = 2016 AND a.country_name <> 'World'
ORDER BY forest_area_change
LIMIT 5


--c. If countries were grouped by percent forestation in quartiles, which group had the most countries in it in 2016?
WITH table1 AS
( 	SELECT * FROM forestation WHERE year = 2016 AND region <> 'World'
	AND pct_forest_land is not null
),
table2 AS
(
	SELECT *,
	Case When pct_forest_land >75 THEN 'Quartile4'
	When pct_forest_land >50 AND pct_forest_land <=75 THEN 'Quartile3'
	When pct_forest_land >25 AND pct_forest_land <=50 THEN 'Quartile2'
	ELSE 'Quartile1'
	END AS quartiles
	FROM table1
)
SELECT quartiles, count(*) AS quartiles_group FROM table2
group by 1
ORDER BY 1

--d. List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016.
SELECT DISTINCT(quartiles), COUNT(country_name)
OVER (PARTITION BY quartiles)
FROM 
	(SELECT country_name,
		CASE WHEN pct_forest_land > 75 THEN '75%-100%'
			WHEN pct_forest_land >50 AND pct_forest_land <=75 THEN '50%-75%'
			WHEN pct_forest_land >25 AND pct_forest_land <=50 THEN '25%-75%'
			ELSE '0-25%'
			END AS quartiles
			FROM forestation
			WHERE pct_forest_land IS NOT NULL AND year = 2016
		)sub;

--top quartile countries
SELECT country_name, region, round(pct_forest_land::numeric,2)AS pct_as_forest
FROM forestation
WHERE pct_forest_land > 75 AND pct_forest_land IS NOT NULL AND year = 2016
ORDER BY 3 DESC;

--e. How many countries had a percent forestation higher than the United States in 2016?
SELECT COUNT(country_name)
FROM forestation
WHERE year = 2016 AND pct_forest_land >
    (SELECT pct_forest_land
	 FROM forestation
	 WHERE country_name = 'United States' AND year = 2016
	 );