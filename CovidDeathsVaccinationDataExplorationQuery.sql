Select *
From PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4

--Select *
--From PortfolioProject..CovidVaccination
--order by 3,4

-- Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country(rough estimate)

Select Location, date, total_cases, total_deaths, 
(Convert (Decimal(15, 3), total_deaths)/Convert (Decimal(15, 3),total_cases)*100) as deathpercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null
order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

Select Location, date, total_cases, population, 
(Convert (Decimal(15, 3), total_cases)/Convert (Decimal(15, 3),population)*100) as PercentofPopulationInfected
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null
order by 1,2

-- List of Countries and their infection rate?

Select Location, population, max(cast(total_cases as int)) as HighestInfectionCount,
max((Convert (Decimal(15, 3), total_cases)/Convert (Decimal(15, 3),population)*100)) as PercentofPopulationInfected
From PortfolioProject..CovidDeaths
Where continent is not null
group by location, population
order by PercentofPopulationInfected desc

--How many people actually died for every country?
-- We're adding Continent is not null because it's meddling with the data

Select Location, Max(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
group by location
order by TotalDeathCount desc

--LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing the continents with the highest death count

Select continent, Max(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

Select  
sum(cast(new_cases as Decimal(15,3))) as totalcases, 
sum(cast(new_deaths as Decimal(15,3))) as totaldeaths,
sum(convert(DECIMAL(15,3), new_deaths))/sum(convert(DECIMAL(15,3), new_deaths)) as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
--Group by date
order by 1,2

--Looking for Total Population, Vaccinations/perdate, SumofVac/atdate

Select dea.continent, dea.location, dea.date, dea.population, new_vaccinations,
SUM(convert(bigint,vac.new_vaccinations)) over (partition by dea.location Order by dea.Location, dea.date) as SumofVac@location
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

SET ANSI_WARNINGS OFF
GO

-- PopvsVac (This wont work so u have to use CTE)

Select 
	dea.continent, dea.location, dea.date, dea.population, new_vaccinations
	,SUM(convert(bigint,vac.new_vaccinations)) over (partition by dea.location Order by dea.Location, dea.date) as SumofVaclocation
	
From 
	PortfolioProject..CovidDeaths dea
Join 
	PortfolioProject..CovidVaccination vac
	on 
		dea.location = vac.location and dea.date = vac.date
where 
	dea.continent is not null
order by
	2,3

-- Use CTE 
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, SumofVaclocation)
as
(
Select dea.continent, dea.location, dea.date, dea.population, new_vaccinations
	,SUM(convert(bigint,vac.new_vaccinations)) over (partition by dea.location Order by 
	dea.Location, dea.date) as SumofVaclocation
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select *, (SumofVaclocation/Population)*100
From PopvsVac
Where New_Vaccinations is not null

-- Using temp tables
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
Population numeric,
New_Vaccinations numeric,
SumofVaclocation numeric
)
Insert Into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, new_vaccinations
	,SUM(convert(bigint,vac.new_vaccinations)) over (partition by dea.location Order by 
	dea.Location, dea.date) as SumofVaclocation
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null

Select *, (SumofVaclocation/Population)*100
From #PercentPopulationVaccinated
Where New_Vaccinations is not null

-- then what if we want to remove line 141?
DROP Table if exists  #PercentPopulationVaccinated 
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
Population numeric,
New_Vaccinations numeric,
SumofVaclocation numeric
)
Insert Into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, new_vaccinations
	,SUM(convert(bigint,vac.new_vaccinations)) over (partition by dea.location Order by 
	dea.Location, dea.date) as SumofVaclocation
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location 
	and dea.date = vac.date
--where dea.continent is not null


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated As
Select dea.continent, dea.location, dea.date, dea.population, new_vaccinations
	,SUM(convert(bigint,vac.new_vaccinations)) over (partition by dea.location Order by 
	dea.Location, dea.date) as SumofVaclocation
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

----

Select *
From PercentPopulationVaccinated
