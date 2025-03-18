/*************************************************
Data Preparation: players_gamedetails.csv
*************************************************/

-- Create a table called players_gamedetails.
CREATE TABLE players_gamedetails (
    id INT PRIMARY KEY,
    overall INT,
    potential INT,
    crossing INT,
    finishing INT,
    heading_accuracy INT,
    short_passing INT,
    volleys INT,
    dribbling INT,
    curve INT,
    fk_accuracy INT,
    long_passing INT,
    ball_control INT,
    acceleration INT,
    sprint_speed INT,
    agility INT,
    reactions INT,
    balance INT,
    shot_power INT,
    jumping INT,
    stamina INT,
    strength INT,
    long_shots INT,
    aggression INT,
    interceptions INT,
    positioning INT,
    vision INT,
    penalties INT,
    composure INT,
    marking INT,
    standing_tackle INT,
    sliding_tackle INT,
    gk_diving INT,
    gk_handling INT,
    gk_kicking INT,
    gk_positioning INT,
    gk_reflexes INT,
    international_reputation INT,
    weak_foot INT,
    skill_moves INT);

-- View players_gamedetails table.
SELECT * FROM public.players_gamedetails;

-- Check for duplicates.
SELECT ID, COUNT(*) 
FROM players_gamedetails
GROUP BY ID
HAVING COUNT(*) > 1;

-- Create a function to count NULL values for each column in a given table.
CREATE OR REPLACE FUNCTION nulls_count(target_table TEXT)
RETURNS TABLE(target_column TEXT, null_count BIGINT) AS
$$
DECLARE
    column_record RECORD;  -- Variable to hold column names from the table.
    query TEXT;  -- Variable to store dynamically constructed SQL query.
BEGIN
    -- Loop through each column in the specified table.
    FOR column_record IN 
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = target_table
    LOOP
        -- Construct SQL query to count NULL values for the current column.
        query := 'SELECT ' || quote_literal(column_record.column_name) || ', COUNT(*) 
                  FROM ' || quote_ident(target_table) || 
                 ' WHERE "' || column_record.column_name || '" IS NULL';
        -- Execute the constructed query and return the results.
        RETURN QUERY EXECUTE query;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Apply the nulls_count function to the 'players_gamedetails' table.
SELECT * FROM nulls_count('players_gamedetails');

-- Delete rows from players_gamedetails where crossing is NULL.
DELETE FROM players_gamedetails
WHERE crossing IS NULL;

-- Apply the nulls_count function to the 'players_gamedetails' table.
SELECT * FROM nulls_count('players_gamedetails');

-- Check if columns have values outside of 0 to 100.
SELECT *
FROM players_gamedetails
WHERE EXISTS (
    SELECT 1
    FROM (VALUES 
        (overall), (potential), (crossing), (finishing), (heading_accuracy), 
	(short_passing), (volleys), (dribbling), (curve), (fk_accuracy), 
        (long_passing), (ball_control), (acceleration), (sprint_speed), 
        (agility), (reactions), (balance), (shot_power), (jumping), 
        (stamina), (strength), (long_shots), (aggression), (interceptions), 
        (positioning), (vision), (penalties), (composure), (marking), 
        (standing_tackle), (sliding_tackle), (gk_diving), (gk_handling), 
        (gk_kicking), (gk_positioning), (gk_reflexes)
    ) AS v(val)
    WHERE val NOT BETWEEN 0 AND 100);

-- Check if international_reputation, weak_foot, or skill_moves have values outside of 0 to 5.
SELECT id, international_reputation, weak_foot, skill_moves
FROM players_gamedetails
WHERE EXISTS (
    SELECT 1
    FROM (VALUES 
        (international_reputation), 
        (weak_foot), 
        (skill_moves)
    ) AS v(val)
    WHERE val NOT BETWEEN 0 AND 5);
   
-- Check whether players have a potential lower than their overall.
SELECT *
FROM players_gamedetails
WHERE potential < overall;

/*************************************************
Data Preparation: players_personal.csv
*************************************************/

-- Create a table called players_personal.
CREATE TABLE players_personal (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    age INT,
    nationality VARCHAR(100),
    club VARCHAR(100),
    position VARCHAR(10),
    height VARCHAR(10),
    weight VARCHAR(10),
    preferred_foot VARCHAR(10),
    work_rate VARCHAR(20),
    body_type VARCHAR(20),
    joined DATE,
    loaned_from VARCHAR(100),
    contract_valid_until INT,
    value VARCHAR(20),
    release_clause VARCHAR(20),
    wage VARCHAR(20));

-- View players_personal table.
SELECT * FROM public.players_personal;

-- Check for duplicates.
SELECT ID, COUNT(*) 
FROM players_personal
GROUP BY ID
HAVING COUNT(*) > 1;
   
-- Apply the nulls_count function to the 'players_personal' table.
SELECT * FROM nulls_count('players_personal');

-- Delete rows from players_personal where height is NULL.
DELETE FROM players_personal
WHERE height IS NULL;

-- Apply the nulls_count function to the 'players_gamedetails' table.
SELECT * FROM nulls_count('players_personal');

-- Show players on loan.
SELECT *
FROM players_personal
WHERE loaned_from IS NOT NULL;

-- Replace NULL in loaned_from with N/A.
UPDATE players_personal
SET loaned_from = 'N/A'
WHERE loaned_from IS NULL;

-- Show players not on loan.
SELECT *
FROM players_personal
WHERE loaned_from = 'N/A';

-- Show players on loan.
SELECT *
FROM players_personal
WHERE loaned_from <> 'N/A';

-- Apply the nulls_count function to the 'players_gamedetails' table.
SELECT * FROM nulls_count('players_personal');

-- Replace NULL values in the club column with 'No Club'.
UPDATE players_personal
SET club = 'No Club'
WHERE club IS NULL;

-- Show all players with NULL in the position column.
SELECT *
FROM players_personal
WHERE position IS NULL;

-- Delete players with NULL in the position column.
DELETE FROM players_personal
WHERE position IS NULL;

-- Apply the nulls_count function to the 'players_gamedetails' table.
SELECT * FROM nulls_count('players_personal');

-- Keep NULL values in the joined, contract_valid_until, and release_clause.

/*************************************************
Data Preparation: players_combined
*************************************************/

-- Find IDs in players_personal that are missing in players_gamedetails.
SELECT id, 'missing in players_gamedetails' AS status
FROM players_personal 
WHERE id NOT IN (SELECT id FROM players_gamedetails)
UNION ALL
-- Find IDs in players_gamedetails that are missing in players_personal.
SELECT id, 'missing in players_personal' AS status
FROM players_gamedetails 
WHERE id NOT IN (SELECT id FROM players_personal);

-- Delete players from players_gamedetails that are not in players_personal.
-- These are the players that were just removed for having no position.
DELETE FROM players_gamedetails
WHERE id NOT IN (SELECT id FROM players_personal);

-- View players_personal table.
SELECT * FROM public.players_personal;

-- Create a new table called players_combined by joining players_personal and players_gamedetails on ID.
CREATE TABLE players_combined AS
SELECT 
    p.id,
    p.name,
    p.age,
    p.nationality,
    p.club,
    p.position,
    p.height,
    p.weight,
    p.preferred_foot,
    p.work_rate,
    p.body_type,
    p.joined,
    p.loaned_from,
    p.contract_valid_until,
    p.value,
    p.release_clause,
    p.wage,
    g.overall,
    g.potential,
    g.crossing,
    g.finishing,
    g.heading_accuracy,
    g.short_passing,
    g.volleys,
    g.dribbling,
    g.curve,
    g.fk_accuracy,
    g.long_passing,
    g.ball_control,
    g.acceleration,
    g.sprint_speed,
    g.agility,
    g.reactions,
    g.balance,
    g.shot_power,
    g.jumping,
    g.stamina,
    g.strength,
    g.long_shots,
    g.aggression,
    g.interceptions,
    g.positioning,
    g.vision,
    g.penalties,
    g.composure,
    g.marking,
    g.standing_tackle,
    g.sliding_tackle,
    g.gk_diving,
    g.gk_handling,
    g.gk_kicking,
    g.gk_positioning,
    g.gk_reflexes,
    g.international_reputation,
    g.weak_foot,
    g.skill_moves
FROM players_personal p
LEFT JOIN players_gamedetails g ON p.id = g.id;

-- View players_combined table.
SELECT * FROM public.players_combined;

-- Update value column in players_combined.
UPDATE players_combined
SET value = 
    CASE
        WHEN value LIKE '%M' THEN ROUND(CAST(REPLACE(REPLACE(value, '€', ''), 'M', '') AS NUMERIC) * 1000000)
        WHEN value LIKE '%K' THEN ROUND(CAST(REPLACE(REPLACE(value, '€', ''), 'K', '') AS NUMERIC) * 1000)
        ELSE NULL
    END;
		
-- Update release_clause column in players_combined.
UPDATE players_combined
SET release_clause = 
    CASE
        WHEN release_clause LIKE '%M' THEN ROUND(CAST(REPLACE(REPLACE(release_clause, '€', ''), 'M', '') AS NUMERIC) * 1000000)
        WHEN release_clause LIKE '%K' THEN ROUND(CAST(REPLACE(REPLACE(release_clause, '€', ''), 'K', '') AS NUMERIC) * 1000)
        ELSE NULL
    END;

-- Update wage column in players_combined.
UPDATE players_combined
SET wage = 
    CASE
        WHEN wage = 'Unknown' THEN NULL  -- Set to NULL or handle as needed
        WHEN wage LIKE '%M' THEN ROUND(CAST(REPLACE(REPLACE(wage, '€', ''), 'M', '') AS NUMERIC) * 1000000)
        WHEN wage LIKE '%K' THEN ROUND(CAST(REPLACE(REPLACE(wage, '€', ''), 'K', '') AS NUMERIC) * 1000)
        ELSE NULL
    END;

-- Alter the columns to INTEGER type.
ALTER TABLE players_combined
ALTER COLUMN value TYPE INTEGER USING value::INTEGER,
ALTER COLUMN release_clause TYPE INTEGER USING release_clause::INTEGER,
ALTER COLUMN wage TYPE INTEGER USING wage::INTEGER;

-- View players_combined table.
SELECT * FROM public.players_combined;

-- Apply the nulls_count function to the 'players_combined' table.
SELECT * FROM nulls_count('players_combined');

-- Find the number of players with no club.
SELECT COUNT(*)
FROM players_combined
WHERE club = 'No Club';
-- Answer: 229.

-- Find the number of players on loan.
SELECT COUNT(*)
FROM players_combined
WHERE loaned_from <> 'N/A';
-- Answer: 1264.
-- Total: 1264 + 229 = 1493.

-- Find out how many of the 1493 players with a NULL value in the joined column are either on loan or have no club.
SELECT COUNT(*)
FROM players_combined
WHERE joined IS NULL
  AND (loaned_from <> 'N/A' OR club = 'No Club');
-- Answer: 1493. Therefore, keep NULL values in the joined column.

-- Find out how many of the 1493 players with a NULL value in the contract_valid_until column are either on loan or have no club.
SELECT COUNT(*)
FROM players_combined
WHERE contract_valid_until IS NULL
  AND (loaned_from <> 'N/A' OR club = 'No Club');
-- Answer: 1493. Therefore, keep NULL values in the contract_valid_until column.

-- Find out how many of the 240 players with a NULL value in the value column are either on loan or have no club.
SELECT COUNT(*)
FROM players_combined
WHERE value IS NULL
  AND (loaned_from <> 'N/A' OR club = 'No Club');
-- Answer: 229. Therefore, take a closer look.

-- Show players not on loan that have a NULL value in the value column.
SELECT *
FROM players_combined
WHERE value IS NULL
  AND loaned_from = 'N/A';

-- Show players that play for a club but have a NULL value in the value column.
SELECT *
FROM players_combined
WHERE value IS NULL
  AND club <> 'No Club';
-- Answer: 11.

-- Delete rows where value is NULL and the player plays for a club.
DELETE FROM players_combined
WHERE value IS NULL
  AND club <> 'No Club';
  
-- Find out how many of the 1493 players with a NULL value in the release_clause column are either on loan or have no club.
SELECT COUNT(*)
FROM players_combined
WHERE release_clause IS NULL
  AND (loaned_from <> 'N/A' OR club = 'No Club');
-- Answer: 1493. Therefore, keep NULL values in the release_clause column.

-- Find out how many of the 229 players with a NULL value in the wage column are either on loan or have no club.
SELECT COUNT(*)
FROM players_combined
WHERE wage IS NULL
  AND (loaned_from <> 'N/A' OR club = 'No Club');
-- Answer: 229. Therefore, keep NULL values in the wage column.

-- Apply the nulls_count function to the 'players_gamedetails' table.
SELECT * FROM nulls_count('players_combined');

-- Drop the nulls_count function.
DROP FUNCTION IF EXISTS nulls_count(TEXT);

/*************************************************
Analysis
*************************************************/

-- Total number of players per nationality.
SELECT nationality, COUNT(*) AS player_count
FROM players_combined
GROUP BY nationality
ORDER BY player_count DESC;

-- Total number of players per club.
SELECT club, COUNT(*) AS player_count
FROM players_combined
GROUP BY club
ORDER BY player_count DESC;

-- Average age of players per nationality.
SELECT nationality, ROUND(AVG(age), 2) AS average_age
FROM players_combined
GROUP BY nationality
ORDER BY average_age DESC;

-- Average age of players per club.
SELECT club, ROUND(AVG(age), 2) AS average_age
FROM players_combined
GROUP BY club
ORDER BY average_age DESC;

-- Average overall of players per nationality.
SELECT nationality, ROUND(AVG(overall), 2) AS average_overall
FROM players_combined
GROUP BY nationality
ORDER BY average_overall DESC;

-- Average overall of players per club.
SELECT club, ROUND(AVG(overall), 2) AS average_overall
FROM players_combined
GROUP BY club
ORDER BY average_overall DESC;

-- Number of players per nationality with an overall score greater than or equal to 75.
SELECT nationality, COUNT(*) AS player_count
FROM players_combined
WHERE overall >= 75
GROUP BY nationality
ORDER BY player_count DESC;

-- Number of players per club with an overall score greater than or equal to 75.
SELECT club, COUNT(*) AS player_count
FROM players_combined
WHERE overall >= 75
GROUP BY club
ORDER BY player_count DESC;

-- Total value of players in euros by nationality.
SELECT nationality, SUM(value) AS total_value
FROM players_combined
GROUP BY nationality 
ORDER BY total_value DESC; 

-- Total value of players in euros by club.
SELECT club, SUM(value) AS total_value
FROM players_combined
GROUP BY club
ORDER BY total_value DESC;

-- Top 5 players with the highest release clause.
SELECT *
FROM players_combined
WHERE release_clause IS NOT NULL
ORDER BY release_clause DESC
LIMIT 5;

-- Top 5 players with the lowest release clause.
SELECT *
FROM players_combined
WHERE release_clause IS NOT NULL
ORDER BY release_clause ASC
LIMIT 5;

-- Step 1: Identify the top nationalities by total player value.
WITH NationalityTotals AS (
    SELECT nationality, SUM(value) AS total_value
    FROM players_combined
    GROUP BY nationality
    ORDER BY total_value DESC
    LIMIT 11),
-- Step 2: Rank players within these top nationalities and exclude players with NULL value.
RankedPlayers AS (
    SELECT pc.nationality, pc.name, pc.value,
        RANK() OVER (PARTITION BY pc.nationality ORDER BY pc.value DESC) AS rank
    FROM players_combined pc
    JOIN NationalityTotals nt
    ON pc.nationality = nt.nationality
    WHERE pc.value IS NOT NULL)
-- Step 3: Select top 5 players per nationality and order results.
SELECT nationality, rank, name, value
FROM RankedPlayers
WHERE rank <= 5
ORDER BY nationality, rank;

-- Step 1: Identify the top nationalities by total player value.
WITH NationalityTotals AS (
    SELECT nationality, SUM(value) AS total_value
    FROM players_combined
    GROUP BY nationality
    ORDER BY total_value DESC
    LIMIT 11),
-- Step 2: Rank players within these top nationalities based on wage and exclude players with wage = 0.
RankedPlayers AS (
    SELECT pc.nationality, pc.name, pc.wage,
           RANK() OVER (PARTITION BY pc.nationality ORDER BY pc.wage DESC) AS rank
    FROM players_combined pc
    JOIN NationalityTotals nt
      ON pc.nationality = nt.nationality
    WHERE pc.wage > 0)
-- Step 3: Select top 5 players per nationality based on wage and order results.
SELECT nationality, rank, name, wage
FROM RankedPlayers
WHERE rank <= 5
ORDER BY nationality, rank;

-- Step 1: Identify the highest potential for each position.
WITH MaxPotential AS (
    SELECT position, MAX(potential) AS max_potential
    FROM players_combined
    GROUP BY position)
-- Step 2: Select players with the highest potential, including their overall rating.
SELECT pc.position, pc.name, pc.age, pc.overall, pc.potential
FROM players_combined pc
JOIN MaxPotential mp
ON pc.position = mp.position 
AND pc.potential = mp.max_potential
ORDER BY pc.position;

-- Top 100 players with the biggest difference between their overall and potential ratings.
SELECT name, age, overall, potential, (potential - overall) AS difference
FROM players_combined
ORDER BY difference DESC
LIMIT 100;

-- View players_combined table as a final check before exporting the dataset.
SELECT * FROM public.players_combined;