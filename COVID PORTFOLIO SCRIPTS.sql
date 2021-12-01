/*

Covid 19 data exploration using Microsft SQL Server Management Studio.

I am trying to answer three main questions: 
-What countries have the largest percent of their population vaccinated with the first and second dose?
-What do vaccination rates, Covid19 cases and Covid related deaths look like over time for different countries around the world?
-How effective were vaccinations at reducing Covid cases and deaths for different countries around the world?

Skills that I used include CTE's, Temp Tables, Subqueries, Windows Functions, Aggregate Functions, Creating Views, Updating tables, Converting Data Types.

I exported views using the Export Wizard and created visualizations in Tableau.

Link to Data: https://ourworldindata.org/covid-deaths

There are two data tables: CovidDeaths and CovidVaccinations

*/

-- VIEW ENTIRE CovidDeaths TABLE 

SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

-- VIEW ENTIRE CovidVaccinations TABLE 

SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4


-- SELECT COLUMNS FROM CovidDeaths TABLE I WILL BE WORKING WITH AND FILTER OUT DATA WHERE CONTINENT COLUMN IS NULL

SELECT location, date, total_cases, new_cases, new_cases_smoothed, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- DEATH PERCENTAGE (CHANCE OF DYING IF YOU CONTRACT COVID19 IN CANADA) OVER TIME

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Canada' AND continent IS NOT NULL
ORDER BY 1,2


-- PERCENT OF CANADIAN POPULATION INFECTED WITH COVID19 OVER TIME

SELECT location, date, population, total_cases, total_deaths, (total_cases/population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- COUNTRIES WITH HIGHEST COVID19 INFECTION RATE 

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC
 

 -- COUNTRIES WITH THE HIGHEST TOTAL DEATH COUNT

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- CONTINENTS WITH THE HIGHEST TOTAL DEATH COUNT

SELECT continent, SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- TOTAL CASES, TOTAL DEATHS, AND DEATH PERCENTAGE FOR ENTIRE WORLD OVER TIME

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2 

-- TOTAL DEATHS, CASES, AND DEATH PERCENTAGE

SELECT sum(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2 

-- JOIN TOGETHER CovidDeaths and CovidVaccinations on columns 'location' and 'date'
-- ROLLING FIRST DOSE, SECOND DOSE, AND TOTAL VACCINATIONS GIVEN OVER TIME FOR EACH COUNTRY

SELECT dea.continent, dea.location, dea.date, dea.population, dea.total_cases, dea.total_deaths, vac.people_vaccinated AS FirstDose, vac.people_fully_vaccinated AS SecondDose
, vac.total_vaccinations
, MAX(CAST(vac.people_vaccinated AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingFirstDose
, MAX(CAST(vac.people_fully_vaccinated AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingSecondDose
, MAX(CAST(vac.total_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations,
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- UPDATE POPULATION OF NORTHER CYPRUS FROM NULL TO 326,000

UPDATE PortfolioProject..CovidDeaths
SET population = 326000
Where location = 'Northern Cyprus'


-- CREATE TEMP TABLE FROM PREVIOUS QUERY  

DROP TABLE IF EXISTS #VaccineProgress
CREATE TABLE #VaccineProgress
(
continent nvarchar(255), 
location nvarchar(255),
date datetime, 
population numeric, 
total_cases numeric,
new_cases numeric,
new_cases_smoothed numeric,
total_deaths numeric,
new_deaths numeric,
new_deaths_smoothed numeric,
FirstDose numeric,
SecondDose numeric,
total_vaccinations numeric,
RollingFirstDose numeric, 
RollingSecondDose numeric, 
RollingTotalVaccinations numeric
)

INSERT INTO #VaccineProgress
SELECT dea.continent, dea.location, dea.date, dea.population, dea.total_cases, dea.new_cases, dea.new_cases_smoothed
, dea.total_deaths, dea.new_cases, dea.new_deaths_smoothed, vac.people_vaccinated AS FirstDose, vac.people_fully_vaccinated AS SecondDose
, vac.total_vaccinations
, MAX(CAST(vac.people_vaccinated AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingFirstDose
, MAX(CAST(vac.people_fully_vaccinated AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingSecondDose
, MAX(CAST(vac.total_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- FIRST DOSE, SECOND DOSE AND TOTAL DOSES AS PERCENTAGE OF TOTAL POPULATION

SELECT continent, location, date, population, total_cases, new_cases, new_cases_smoothed, total_deaths, new_deaths, new_deaths_smoothed, RollingFirstDose, RollingSecondDose, RollingTotalVaccinations
, (RollingFirstDose/population)*100 AS FirstDosePercentage
, (RollingSecondDose/population)*100 AS SecondDosePercentage
, (RollingTotalVaccinations/population)*100 AS TotalVaccinationsPercentage
FROM #VaccineProgress


-- SUBQUERY TOTAL FIRST DOSE, SECOND DOSE, TOTAL VACCINATIONS AS PERCENTAGE OF POPULATION

SELECT prog.location, prog.population, prog.TotalFirstDose, prog.TotalSecondDose, prog.TotalVaccinations
, (prog.TotalFirstDose/prog.population)*100 AS FirstDosePercent
, (prog.TotalSecondDose/prog.population)*100 AS SecondDosePercent 
FROM 
	(SELECT location, MAX(population) AS population
	, MAX(RollingFirstDose) AS TotalFirstDose
	, MAX(RollingSecondDose) AS TotalSecondDose
	, MAX(RollingTotalVaccinations) AS TotalVaccinations
     FROM #VaccineProgress
	 GROUP BY location) AS prog
ORDER BY 7 DESC


--CREATE VIEW FOR LAST TWO QUERIES (Can't store a temp table as a view so I created a CTE) 

-- Covid19 cases, deaths, and vaccine progress over time for each country 
USE PortfolioProject
CREATE VIEW VaccineProgressTimeline AS 
WITH CTERollingVaccinations (continent, location, date, population, total_cases, new_cases, new_cases_smoothed, total_deaths, new_deaths, new_deaths_smoothed, FirstDose, SecondDose, total_vaccinations, RollingFirstDose, RollingSecondDose, RollingTotalVaccinations) AS
(SELECT dea.continent, dea.location, dea.date, dea.population, dea.total_cases, dea.new_cases, dea.new_cases_smoothed
, dea.total_deaths, dea.new_deaths, dea.new_deaths_smoothed, vac.people_vaccinated AS FirstDose, vac.people_fully_vaccinated AS SecondDose
, vac.total_vaccinations
, MAX(CAST(vac.people_vaccinated AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingFirstDose
, MAX(CAST(vac.people_fully_vaccinated AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingSecondDose
, MAX(CAST(vac.total_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT continent, location, date, population, total_cases, new_cases, new_cases_smoothed
, total_deaths, new_deaths, new_deaths_smoothed, RollingFirstDose, RollingSecondDose, RollingTotalVaccinations
, (RollingFirstDose/population)*100 AS FirstDosePercentage
, (RollingSecondDose/population)*100 AS SecondDosePercentage
, (RollingTotalVaccinations/population)*100 AS TotalVaccinationsPercentage
FROM CTERollingVaccinations


-- Total vaccine progress for each country 

CREATE VIEW VaccineProgressTotals AS
SELECT prog.location, prog.population, prog.TotalFirstDose, prog.TotalSecondDose, prog.TotalVaccinations
, (prog.TotalFirstDose/prog.population)*100 AS FirstDosePercent
, (prog.TotalSecondDose/prog.population)*100 AS SecondDosePercent 
FROM 
	(SELECT location, MAX(population) AS population
	, MAX(RollingFirstDose) AS TotalFirstDose
	, MAX(RollingSecondDose) AS TotalSecondDose
	, MAX(RollingTotalVaccinations) AS TotalVaccinations
     FROM PortfolioProject.dbo.VaccineProgressTimeline
	 GROUP BY location) AS prog

-- I will export the VaccineProgressTimeline View and the VaccineProgressTotals View and import both tables into Tableau for visualization

SELECT *
FROM PortfolioProject..VaccineProgressTimeline
ORDER BY 2 


SELECT *
FROM PortfolioProject..VaccineProgressTotals
ORDER BY 7 DESC