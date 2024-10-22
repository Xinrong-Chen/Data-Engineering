-- originally written in snowflake SQL
-- retrieve wanted columns

SELECT COLUMN_NAME
FROM engine.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'AS_PROD' AND TABLE_NAME = 'DIMDATE'
  AND COLUMN_NAME != 'FISCALYEAR'
  AND COLUMN_NAME NOT LIKE '%FRENCH%'
  AND COLUMN_NAME NOT LIKE '%SPANISH%'
  ORDER BY COLUMN_NAME;

-- populate table from main source

CREATE OR REPLACE TRANSIENT TABLE DIMDATE_MINE AS
SELECT 
    CALENDARQUARTER,
    CALENDARSEMESTER,
    CALENDARYEAR,
    DATEKEY,
    DAYNUMBEROFMONTH,
    DAYNUMBEROFWEEK,
    DAYNUMBEROFYEAR,
    ENGLISHDAYNAMEOFWEEK,
    ENGLISHMONTHNAME,
    FISCALQUARTER,
    FISCALSEMESTER,
    FULLDATEALTERNATEKEY,
    MONTHNUMBEROFYEAR,
    WEEKNUMBEROFYEAR
FROM engine.database.DIMDATE;

DESC TABLE DIMDATE_MINE;

-- create a temporary table for backup before making changes

CREATE OR REPLACE TEMPORARY TABLE TempHistorical AS
    SELECT * FROM DIMDATE_MINE;

-- data exploration
SELECT * FROM DIMDATE_MINE LIMIT 50;

-- assume and verify potential primary key
SELECT COUNT(*) AS total, COUNT(DISTINCT FULLDATEALTERNATEKEY) AS potential_pk,  MAX(FULLDATEALTERNATEKEY) AS last FROM DIMDATE_MINE;

-- check relationship between fiscal and calendar quarter/ semester 
SELECT DISTINCT FISCALQUARTER, CALENDARQUARTER FROM DIMDATE_MINE;
SELECT DISTINCT FISCALSEMESTER, CALENDARSEMESTER FROM DIMDATE_MINE;

----------

INSERT INTO DIMDATE_MINE (
    FULLDATEALTERNATEKEY, CALENDARQUARTER, CALENDARSEMESTER, CALENDARYEAR,
    DATEKEY, DAYNUMBEROFMONTH, DAYNUMBEROFWEEK, DAYNUMBEROFYEAR,
    ENGLISHDAYNAMEOFWEEK, ENGLISHMONTHNAME,
    FISCALQUARTER, FISCALSEMESTER,
    MONTHNUMBEROFYEAR, WEEKNUMBEROFYEAR
)
    SELECT 
        DATEADD(day, SEQ4(), TO_DATE('2015-01-01')) AS FULLDATEALTERNATEKEY,
        QUARTER(FULLDATEALTERNATEKEY) AS CALENDARQUARTER,
        IFF(MONTH(FULLDATEALTERNATEKEY)<7, 1,2) AS CALENDARSEMESTER,
        YEAR(FULLDATEALTERNATEKEY) AS CALENDARYEAR,
        TO_CHAR(FULLDATEALTERNATEKEY, 'YYYYMMDD') AS DATEKEY,
        DAYOFWEEKISO(FULLDATEALTERNATEKEY) AS DAYNUMBEROFWEEK,  // ISO format starts from 1
        DAYOFMONTH(FULLDATEALTERNATEKEY) AS DAYNUMBEROFMONTH,
        DAYOFYEAR(FULLDATEALTERNATEKEY) AS DAYNUMBEROFYEAR,
        DECODE(DAYOFWEEKISO(FULLDATEALTERNATEKEY),    1, 'Monday',
                                                      2, 'Tuesday',
                                                      3, 'Wednesday',
                                                      4, 'Thursday',
                                                      5, 'Friday',
                                                      6, 'Saturday',
                                                      7, 'Sunday') AS ENGLISHDAYNAMEOFWEEK,
        DECODE(MONTH(FULLDATEALTERNATEKEY),  1, 'January',
                                             2, 'February',
                                             3, 'March',
                                             4, 'April',
                                             5, 'May',
                                             6, 'June',
                                             7, 'July',
                                             8, 'August',
                                             9, 'September',
                                             10, 'October',
                                             11, 'November',
                                             12, 'December') AS ENGLISHMONTHNAME,
        DECODE(CALENDARQUARTER,     1,3,
                                    2,4,
                                    3,1,
                                    4,2) AS FISCALQUARTER,
        DECODE(CALENDARSEMESTER,    1,2,
                                    2,1) AS FISCALSEMESTER,
        MONTH(FULLDATEALTERNATEKEY) AS MONTHNUMBEROFYEAR,
        WEEK(FULLDATEALTERNATEKEY) AS WEEKNUMBEROFYEAR
    
    FROM TABLE(GENERATOR(ROWCOUNT => 10000))
    WHERE DATEKEY < '20310101';  -- expand to 2030-12-31, as requested


SELECT *
FROM DIMDATE_MINE
WHERE DATEKEY < '20150101'
EXCEPT
SELECT *
FROM TempHistorical;

SELECT (SELECT COUNT(*) FROM DIMDATE_MINE) - 
        (SELECT COUNT(*) FROM TempHistorical) AS update_diff;


SELECT COUNT(Datekey) AS total, COUNT(DISTINCT Datekey) AS unique_num
FROM DIMDATE_MINE;

SELECT COUNT(*) AS null_count FROM DIMDATE_MINE WHERE Datekey IS NULL;

DROP TABLE IF EXISTS TempHistorical;


-- Cross-validate table from another source with mine;
SELECT * FROM DIMDATE_OTHER LIMIT 100; 

SHOW COLUMNS IN TABLE DIMDATE_OTHER;

/*
DATEKEY
FULLDATEALTERNATEKEY
CALENDARQUARTER
CALENDARYEAR
CALENDARSEMESTER
DAYNUMBEROFWEEK
DAYNUMBEROFMONTH
DAYNUMBEROFYEAR
WEEKNUMBEROFYEAR
MONTHNUMBEROFYEAR
ENGLISHDAYNAMEOFWEEK
ENGLISHMONTHNAME
*/

// Test Case 1: Date range completeness  -- DATEKEY and FULLDATEALTERNATEKEY

-- gap check
WITH DateDiffs AS (
    SELECT 
        FULLDATEALTERNATEKEY, 
        DATEDIFF(day, FULLDATEALTERNATEKEY, LAG(FULLDATEALTERNATEKEY) OVER (ORDER BY FULLDATEALTERNATEKEY ASC)) AS diff
    FROM 
        DIMDATE_OTHER
)
SELECT 
    IFF(COUNT(*) = 0, 'Passed', 'Not Passed') AS status
FROM 
    DateDiffs
WHERE 
    diff > 1;

-- null check

SELECT 
    DATEKEY,
    FULLDATEALTERNATEKEY,
    COUNT(*) OVER () AS total_rows,
    COUNT(DATEKEY) OVER () AS non_null_datekey_count,
    COUNT(FULLDATEALTERNATEKEY) OVER () AS non_null_full_date_count
FROM 
    DIMDATE_MINE
LIMIT 1;

-- passed

// Test 2 -- Calendar fields
SELECT IFF(SUM(IFF(QUARTER(FULLDATEALTERNATEKEY) = CALENDARQUARTER,1,0)) = COUNT(*), 'Passed', 'Not Passed') AS status
FROM DIMDATE_OTHER;

SELECT IFF(SUM(IFF(YEAR(FULLDATEALTERNATEKEY) = CALENDARYEAR,1,0)) = COUNT(*), 'Passed', 'Not Passed') AS status
FROM DIMDATE_OTHER;

SELECT IFF(SUM(IFF(IFF(MONTH(FULLDATEALTERNATEKEY) < 7, 1, 2) = CALENDARSEMESTER,1,0)) = COUNT(*), 'Passed', 'Not Passed') AS status
FROM DIMDATE_OTHER;

-- passed

// Test 3 -- week and month number

SELECT IFF(SUM(IFF(MONTH(FULLDATEALTERNATEKEY) = MONTHNUMBEROFYEAR,1,0)) = COUNT(*), 'Passed', 'Not Passed') AS status
FROM DIMDATE_OTHER;

SELECT IFF(SUM(IFF(WEEK(FULLDATEALTERNATEKEY) = WEEKNUMBEROFYEAR,1,0)) = COUNT(*), 'Passed', 'Not Passed') AS status
FROM DIMDATE_OTHER;

-- not passed at first, print out inconsistent fields and found differences in parameter used

ALTER SESSION SET week_of_year_policy=1;  // year of week start counting from 1, new week starts from Sundays
ALTER SESSION SET week_start = 7; 

SELECT IFF(SUM(IFF(WEEK(FULLDATEALTERNATEKEY) = WEEKNUMBEROFYEAR,1,0)) = COUNT(*), 'Passed', 'Not Passed') AS status
FROM DIMDATE_OTHER;

-- passed

// Test 4 -- English names

SELECT IFF(SUM(IFF(DAYNAME(FULLDATEALTERNATEKEY) = LEFT(ENGLISHDAYNAMEOFWEEK, 3),1,0)) = COUNT(*), 'Passed', 'Not Passed') AS status
FROM DIMDATE_OTHER;

SELECT IFF(SUM(IFF(MONTHNAME(FULLDATEALTERNATEKEY) = LEFT(ENGLISHMONTHNAME, 3),1,0)) = COUNT(*), 'Passed', 'Not Passed') AS status
FROM DIMDATE_OTHER;

-- passed

// Test 5 -- DAYNUMBEROFWEEK

SELECT ENGLISHDAYNAMEOFWEEK, 
    COUNT(CASE WHEN DAYOFWEEK(FULLDATEALTERNATEKEY) = DAYNUMBEROFWEEK THEN 1 END) OVER (PARTITION BY ENGLISHDAYNAMEOFWEEK) AS corrected_count,
    COUNT(*) OVER (PARTITION BY ENGLISHDAYNAMEOFWEEK) AS total_count
FROM DIMDATE_OTHER
LIMIT 7;

-- passed

// Test 6 -- DAYNUMBEROFMONTH

SELECT DISTINCT ENGLISHMONTHNAME, 
    COUNT(CASE WHEN DAYOFMONTH(FULLDATEALTERNATEKEY) = DAYNUMBEROFMONTH THEN 1 END) OVER (PARTITION BY ENGLISHMONTHNAME) AS corrected_count,
    COUNT(*) OVER (PARTITION BY ENGLISHMONTHNAME) AS total_count
FROM DIMDATE_OTHER;

-- passed

// Test 7 -- DAYNUMBEROFYEAR

SELECT DISTINCT DAYNUMBEROFYEAR,
    COUNT(CASE WHEN DAYOFYEAR(FULLDATEALTERNATEKEY) = DAYNUMBEROFYEAR THEN 1 END) OVER (PARTITION BY DAYNUMBEROFYEAR) AS corrected_count,
    COUNT(*) OVER (PARTITION BY DAYNUMBEROFYEAR) AS total_count
FROM DIMDATE_OTHER
ORDER BY DAYNUMBEROFYEAR ASC;

-- passed




