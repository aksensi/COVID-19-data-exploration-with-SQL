-- COVID - 19 Data Exploration
-- this project is just a practise for me with Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types


Select *
From Project01..CovidDeaths
Where continent is not null 
order by 3,4


-- Select Data

Select location, date, total_cases, new_cases, total_deaths, population
From Project01..CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Showing likelihood of dying considering the cases

Select Location, date, total_cases,total_deaths, 
case 
	when total_cases >0 then (total_deaths/cast(total_cases as float))*100 end as DeathPercentage
From Project01..CovidDeaths
Where location like '%india%'
and continent is not null
and total_cases is not null
order by year(date),1,2


-- Total Cases vs Population
-- Showing the percentage of population affected

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From Project01..CovidDeaths
--Where location like '%india%'
where continent is not null
and total_cases is not null
order by 1,2


-- Countries with Highest affected Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Project01..CovidDeaths
--Where location like '%india%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Project01..CovidDeaths
--Where location like '%india%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc  --United States had the highest death count



-- Global

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Project01..CovidDeaths 
where continent is not null 
--Group By date
order by 1,2


-- Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as VaccinationRollingPerDay
From Project01..CovidDeaths  dea
Join Project01..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Since I want to use VaccinationRollingPerDay which i cannot since i created it, i need temporary variables
-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, VaccinationRollingPerDay)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as VaccinationRollingPerDay
--, (RollingPeopleVaccinated/population)*100
From Project01..CovidDeaths  dea
Join Project01..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (VaccinationRollingPerDay/cast(Population as float))*100 as VaccinationPercentage
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated   -- this will eliminate all previous created tables if created or want to make further changes
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Project01..CovidDeaths  dea
Join Project01..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/cast(Population as float))*100
From #PercentPopulationVaccinated




-- Creating View to store data for visualizations
DROP View if exists PercentPopulationVaccinated_02
Create View PercentPopulationVaccinated_02 as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Project01..CovidDeaths dea
Join Project01..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 



exec sp_helptext 'PercentPopulationVaccinated_02'

SELECT *
FROM PercentPopulationVaccinated_02