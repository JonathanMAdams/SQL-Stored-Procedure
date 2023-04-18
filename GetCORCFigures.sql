/* Syntax by Jonathan Adams and Tracy Wang */
/* Instructions
	Scroll to bottom of query.
	StartDate is the beginning of the timespan of interest.
	EndDate is the end of the timespan of interest. */

CREATE PROCEDURE GetCORCSurveys @StartDate datetime, @EndDate datetime AS
	CREATE TABLE #YearMonthDisplay  
		([CollectionYearMonth] nvarchar(7),
		[CollectionYear] int,
		[CollectionMonth] int,
		[CollectionCategory] varchar(30),
		[In-Person] int,
		[Remote] int,
		[Baseline] int,
		[Follow-Up] int)
	SET ANSI_WARNINGS OFF
	INSERT #YearMonthDisplay EXEC CSP2028_Partic.Access.Completions_YearMonthDisplay
	SET ANSI_WARNINGS ON;

	WITH SummaryTable AS(
	SELECT
		CASE 
			WHEN SUBSTRING(CollectionYearMonth, 6, 7) LIKE '02' THEN CONVERT(datetime, CONCAT(CONVERT(char(7),CollectionYearMonth), '-28')) 
			WHEN SUBSTRING(CollectionYearMonth, 6, 7) LIKE '04' THEN CONVERT(datetime, CONCAT(CONVERT(char(7),CollectionYearMonth), '-30')) 
			WHEN SUBSTRING(CollectionYearMonth, 6, 7) LIKE '06' THEN CONVERT(datetime, CONCAT(CONVERT(char(7),CollectionYearMonth), '-30')) 
			WHEN SUBSTRING(CollectionYearMonth, 6, 7) LIKE '09' THEN CONVERT(datetime, CONCAT(CONVERT(char(7),CollectionYearMonth), '-30')) 
			WHEN SUBSTRING(CollectionYearMonth, 6, 7) LIKE '11' THEN CONVERT(datetime, CONCAT(CONVERT(char(7),CollectionYearMonth), '-30')) 
			ELSE CONVERT(datetime, CONCAT(CONVERT(char(7),CollectionYearMonth), '-31')) 
		END AS CollectionMonthEnd,
		([In-Person] + [Remote]) AS Specimens,
		([Baseline] + [Follow-Up]) AS Surveys
	FROM #YearMonthDisplay
	WHERE CollectionYearMonth NOT LIKE '2020-01'),

	JoinedTable AS (SELECT SummaryTableA.CollectionMonthEnd, SummaryTableA.Specimens, SummaryTableB.Surveys
	FROM SummaryTable AS SummaryTableA
	LEFT JOIN SummaryTable AS SummaryTableB 
		ON SummaryTableA.CollectionMonthEnd = SummaryTableB.CollectionMonthEnd
	WHERE SummaryTableA.Specimens IS NOT NULL AND SummaryTableB.Surveys IS NOT NULL)

	SELECT SUM(Specimens) AS [Total Specimens], SUM(Surveys) AS [Total Surveys]
	FROM JoinedTable
	WHERE CollectionMonthEnd BETWEEN @StartDate AND @EndDate
GO

EXEC GetCORCSurveys @StartDate = '2021-12-01', @EndDate = '2022-12-31'
