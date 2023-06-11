
--Creating table for Country_Code with primary key

CREATE TABLE Country_Code
(iso_code VARCHAR(50) NOT NULL UNIQUE PRIMARY KEY,
 location VARCHAR(50) NOT NULL,
 continent VARCHAR(50) NOT NULL
);

--Import country_code.csv via interface

--Create table Covid_Vaccinations

CREATE TABLE Covid_Vaccinations
(iso_code VARCHAR(50) NOT NULL,
 continent VARCHAR(50) NOT NULL,
 location VARCHAR(50) NOT NULL,
 date date,
 new_tests NUMERIC,
 total_tests NUMERIC,
 total_tests_per_thousand NUMERIC,
 new_tests_per_thousand NUMERIC,
 new_tests_smoothed NUMERIC,
 new_tests_smoothed_per_thousand NUMERIC,
 positive_rate NUMERIC,
 tests_per_case NUMERIC,
 tests_units VARCHAR(50),
 total_vaccinations NUMERIC,
 people_vaccinated NUMERIC,
 people_fully_vaccinated NUMERIC,
 total_boosters NUMERIC,
 new_vaccinations NUMERIC,
 new_vaccinations_smoothed NUMERIC,
 total_vaccinations_per_hundred NUMERIC,
 people_vaccinated_per_hundred NUMERIC,
 people_fully_vaccinated_per_hundred NUMERIC,
 total_boosters_per_hundred NUMERIC,
 new_vaccinations_smoothed_per_million NUMERIC,
 new_people_vaccinated_smoothed NUMERIC,
 new_people_vaccinated_smoothed_per_hundred NUMERIC,
 stringency_index NUMERIC,
 population_density NUMERIC,
 median_age NUMERIC,
 aged_65_older NUMERIC,
 aged_70_older NUMERIC,
 gdp_per_capita NUMERIC,
 extreme_poverty NUMERIC,
 cardiovasc_death_rate NUMERIC,
 diabetes_prevalence NUMERIC,
 female_smokers NUMERIC,
 male_smokers NUMERIC,
 handwashing_facilities NUMERIC,
 hospital_beds_per_thousand NUMERIC,
 life_expectancy NUMERIC,
 human_development_index NUMERIC,
 excess_mortality_cumulative_absolute NUMERIC,
 excess_mortality_cumulative NUMERIC,
 excess_mortality NUMERIC,
 excess_mortality_cumulative_per_million NUMERIC
);

--import csv file

COPY covid_vaccinations 
FROM 'D:\Portfolio\Covid_Vaccinations.csv' with csv header;

--add foreign key to covid_vaccinations table

ALTER TABLE covid_vaccinations
ADD CONSTRAINT fk
FOREIGN KEY (iso_code)
REFERENCES country_code(iso_code);

--create table for Covid_Deaths with foreign key

CREATE TABLE covid_deaths
(iso_code VARCHAR(50) NOT NULL REFERENCES country_code (iso_code),
 continent VARCHAR(50) NOT NULL,
 location VARCHAR(50) NOT NULL,
 date date,
 population NUMERIC,
 total_cases NUMERIC,
 new_cases NUMERIC,
 new_cases_smoothed NUMERIC,
 total_deaths NUMERIC,
 new_deaths NUMERIC,
 new_deaths_smoothed NUMERIC,
 total_cases_per_million NUMERIC,
 new_cases_per_million NUMERIC,
 new_cases_smoothed_per_million NUMERIC,
 total_deaths_per_million NUMERIC,
 new_deaths_per_million NUMERIC,
 new_deaths_smoothed_per_million NUMERIC,
 reproduction_rate NUMERIC,
 icu_patients NUMERIC,
 icu_patients_per_million NUMERIC,
 hosp_patients NUMERIC,
 hosp_patients_per_million NUMERIC,
 weekly_icu_admissions BIGINT,
 weekly_icu_admissions_per_million NUMERIC,
 weekly_hosp_admissions BIGINT,
 weekly_hosp_admissions_per_million NUMERIC
);

--import covid_deaths.csv

COPY covid_deaths 
FROM 'D:\Portfolio\Covid_Deaths.csv' with csv header;

SELECT *
FROM covid_deaths
ORDER BY 3,4;

-- SELECT *
-- FROM COVID_VACCINATIONS
-- ORDER BY 3,4;

--Select Data we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
ORDER BY 1,2;

-- Look at total cases vs total deaths of Philippines (this is more relevant to me)
-- This shows likelihood of dying if you contract covid

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100  AS Death_Percentage
FROM covid_deaths
WHERE total_cases IS NOT NULL
AND LOCATION = 'Philippines'
ORDER BY 1,2;

--Looking at Total Cases vs Population, it shows what percentage of population got covid

SELECT Location, date, population, total_cases, (total_cases/population)*100  AS Infection_Percentage
FROM covid_deaths
WHERE total_cases IS NOT NULL
AND LOCATION = 'Philippines'
ORDER BY 1,2;

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT Location, population, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases/population))*100  AS Infection_Percentage
FROM covid_deaths
WHERE total_cases IS NOT NULL
GROUP BY Location, population
ORDER BY Infection_Percentage DESC;

--Showing Countries with highest death count per population

SELECT Location, continent, MAX(Total_deaths) AS TotalDeathCount
FROM covid_deaths
WHERE total_deaths IS NOT NULL
GROUP BY Location, continent
ORDER BY TotalDeathCount DESC;

--Showing Continent with highest death count per population

SELECT continent, MAX(Total_deaths) AS TotalDeathCount
FROM covid_deaths
WHERE total_deaths IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--Showing growing global number count of cases for each day including percentage of global infection rate

SELECT date, SUM(total_cases) AS TotalGlobalCases, (SUM(total_cases)/SUM(population))*100  AS GlobalInfectionPercentage
FROM covid_deaths
WHERE total_cases IS NOT NULL
GROUP BY date
ORDER BY 1,2;

--Showing growing Philippine number count of cases for each day

SELECT date, Location, SUM(total_cases) AS TotalCases, (SUM(total_cases)/SUM(population))*100  AS LocalInfectionPercentage
FROM covid_deaths
WHERE total_cases IS NOT NULL
AND location = 'Philippines'
GROUP BY date, Location
ORDER BY 1,2,3 ASC;

--Showing aggregated global deaths and Death Percentage per population

SELECT SUM(total_deaths) AS TotalDeathCount, (SUM(total_cases)/SUM(population))*100  AS GlobalDeathPercentage
FROM covid_deaths
WHERE total_deaths IS NOT NULL
ORDER BY 1,2;

--Looking at Total Population vs Vaccinations using CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) 
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentageOfRollingVaccinated
FROM PopvsVac


--Creating view to store data for later visualizations

CREATE VIEW GlobalCovidDeath AS
SELECT SUM(total_deaths) AS TotalDeathCount, (SUM(total_cases)/SUM(population))*100  AS GlobalDeathPercentage
FROM covid_deaths
WHERE total_deaths IS NOT NULL
ORDER BY 1,2;
