-- DROP TABLE IF EXISTS employee;

CREATE TABLE employee_CHENXINRONG(
    ID int,
    Name varchar(255),
    Salary int,
    Department varchar(255)
);

INSERT INTO employee
VALUES
(1, 'Alice Johnson', 70000, 'Engineering'),
(2, 'Bob Smith', 55000, 'Marketing'),
(3, 'Charlie Davis', 60000, 'Sales'),
(4, 'Diana Evans', 72000, 'Engineering'),
(5, 'Edward Brown', 45000, 'Support'),
(6, 'Fiona White', 68000, 'Finance'),
(7, 'George Miller', 53000, 'Sales'),
(8, 'Hannah Wilson', 48000, 'Marketing'),
(9, 'Isaac Moore', 59000, 'Finance'),
(10, 'Julia Thompson', 71000, 'Engineering');

/*
Retrieve the 2nd to 5th highest-paid employees.
If there's a tie for 5th place, show the employee with the higher name alphabetically (descending).
*/

SELECT Name, Salary
FROM EMPLOYEE
ORDER BY Salary DESC, Name DESC
LIMIT 4 OFFSET 1;

-- check null situation
UPDATE EMPLOYEE SET salary = 70000;

SELECT MAX(Salary) AS SecondHighestSalary
FROM EMPLOYEE
WHERE Salary < (SELECT MAX(Salary) FROM EMPLOYEE);

SELECT Department, SUM(salary) AS total
FROM EMPLOYEE
GROUP BY Department
ORDER BY SUM(salary) DESC;

-- Data Exploratory Analysis

DESCRIBE TABLE Game;

SELECT * FROM Game LIMIT 1000;

SELECT league, COUNT(*) AS records
FROM Game
GROUP BY league
ORDER BY 
    CASE
        WHEN league = 'Delirium' THEN 1
        WHEN league = 'Hardcore Delirium' THEN 2
        WHEN league = 'Harvest' THEN 3
        WHEN league = 'Hardcore Harvest' THEN 4
        WHEN league = 'Expedition' THEN 5
        WHEN league = 'Hardcore Expedition' THEN 6
    END
;

SELECT league, MIN(date) AS league_start_date, MAX(date) AS league_end_date
FROM Game
GROUP BY league;

