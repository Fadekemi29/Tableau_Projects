
-- DERMAI DIAGNOSTICS - SKIN CANCER ANALYSIS

-- DATA EXPLORATION

-- rename tablename

ALTER TABLE table1
RENAME TO Patient_Info;

ALTER TABLE table2
RENAME TO Lesion_Info;



SELECT * FROM patient_info
LIMIT 5;


SELECT * FROM lesion_info
LIMIT 5;


-- Check for missing values in patient_info
SELECT 
    COUNT(*) AS total_records,
    COUNT(patient_id) AS patient_id_count,
    COUNT(age) AS age_count,
    COUNT(gender) AS gender_count,
    COUNT(smoke) AS smoke_count,
    COUNT(drink) AS drink_count,
    COUNT(pesticide) AS pesticide_count,
    COUNT(skin_cancer_history) AS skin_cancer_history_count,
    COUNT(cancer_history) AS cancer_history_count,
    COUNT(has_piped_water) AS has_piped_water_count,
    COUNT(has_sewage_system) AS has_sewage_system_count
FROM patient_info;

-- Check for missing values in lesion_info
SELECT 
    COUNT(*) AS total_records,
    COUNT(lesion_id) AS lesion_id_count,
    COUNT(patient_id) AS patient_id_count,
    COUNT(diagnostic) AS diagnostic_count,
    COUNT(diameter_1) AS diameter_1_count,
    COUNT(diameter_2) AS diameter_2_count,
    COUNT(itch) AS itch_count,
    COUNT(grew) AS grew_count,
    COUNT(hurt) AS hurt_count,
    COUNT(changed) AS changed_count,
    COUNT(bleed) AS bleeds_count,
    COUNT(elevation) AS elevation_count,
    COUNT(biopsed) AS biopsed_count
FROM lesion_info;


-- Basic record counts
SELECT COUNT(*) AS total_patients 
FROM patient_info;

SELECT COUNT(*) AS total_lesions 
FROM lesion_info;

-- Check diagnostic categories
SELECT diagnostic, COUNT(*) AS count
FROM lesion_info
GROUP BY diagnostic
ORDER BY count DESC;

-- Age distribution
SELECT 
    MIN(age) AS min_age,
    MAX(age) AS max_age,
    AVG(age) AS avg_age,
    STDDEV(age) AS std_age
FROM patient_info;

-- Gender distribution
SELECT gender, COUNT(*) AS count
FROM patient_info
GROUP BY gender;

-- Check for data consistency issues
SELECT 
    COUNT(DISTINCT patient_id) AS unique_patients_in_patient_info
FROM patient_info;

SELECT 
    COUNT(DISTINCT patient_id) AS unique_patients_in_lesion_info
FROM lesion_info;

-- Data Distribution Analysis

-- Lesion diameter distribution
SELECT 
    MIN(diameter_1) AS min_diameter_1,
    MAX(diameter_1) AS max_diameter_1,
    AVG(diameter_1) AS avg_diameter_1,
    MIN(diameter_2) AS min_diameter_2,
    MAX(diameter_2) AS max_diameter_2,
    AVG(diameter_2) AS avg_diameter_2
FROM lesion_info;

-- Boolean field distributions
SELECT 
    SUM(CASE WHEN smoke = TRUE THEN 1 ELSE 0 END) AS smokers,
    SUM(CASE WHEN drink = TRUE THEN 1 ELSE 0 END) AS drinkers,
    SUM(CASE WHEN pesticide = TRUE THEN 1 ELSE 0 END) AS pesticide_exposed,
    SUM(CASE WHEN skin_cancer_history = TRUE THEN 1 ELSE 0 END) AS previous_skin_cancer,
    SUM(CASE WHEN cancer_history = TRUE THEN 1 ELSE 0 END) AS family_cancer_history,
    COUNT(*) AS total_patients
FROM patient_info;

-- DATA INTEGRATION

CREATE VIEW lesion_patient_view AS
SELECT
    li.*,
    pi.age,
    pi.gender,
    pi.pesticide,
    pi.has_piped_water,
    pi.has_sewage_system,
    pi.smoke,
    pi.drink,
    pi.background_father,
    pi.background_mother,
    pi.skin_cancer_history,
    pi.cancer_history
FROM
    lesion_info li
JOIN
    patient_info pi
 ON li.patient_id = pi.patient_id;

select * from lesion_patient_view
		
-- 					Environmental Risk Factor Profile

SELECT
    CASE
        WHEN diagnostic IN ('MEL', 'SCC', 'BCC') THEN 'Malignant'
        WHEN diagnostic IN ('ACK') THEN 'Precancerous'
        WHEN diagnostic IN ('SEK', 'NEV') THEN 'Benign'
        ELSE 'Unknown'
    END AS diagnosis_category,
	
	SUM(CASE WHEN pesticide = TRUE THEN 1 ELSE 0 END) AS pesticide_exposed,
   	SUM(CASE WHEN has_piped_water = False THEN 1 ELSE 0 END) AS lacks_piped_water,
    SUM(CASE WHEN has_sewage_system = False THEN 1 ELSE 0 END) AS lacks_sewage_system,
    COUNT(*) AS total_lesions
FROM lesion_patient_view
GROUP BY diagnosis_category;


-- 					Demographic Risk Factor Profile

SELECT
    CASE
        WHEN diagnostic IN ('MEL', 'SCC', 'BCC') THEN 'Malignant'
        WHEN diagnostic IN ('ACK') THEN 'Precancerous'
        WHEN diagnostic IN ('SEK', 'NEV') THEN 'Benign'
        ELSE 'Unknown'
    END AS diagnosis_category,
	gender,
	CASE
        WHEN age < 30 THEN 'Below 30'
        WHEN age BETWEEN 30 AND 49 THEN '30-49'
        WHEN age BETWEEN 50 AND 69 THEN '50-69'
        ELSE '70+'
    END AS age_group,
    SUM(CASE WHEN smoke = TRUE THEN 1 ELSE 0 END) AS smokes,
    SUM(CASE WHEN drink = True THEN 1 ELSE 0 END) AS drinks,
   	SUM(CASE WHEN skin_cancer_history = True THEN 1 ELSE 0 END) AS has_skin_cancer_history,
   	SUM(CASE WHEN cancer_history = True THEN 1 ELSE 0 END) AS has_cancer_history,
   	COUNT(*) AS total_lesions
FROM lesion_patient_view
GROUP BY 1,2,3
ORDER BY 1,2,3;



-- Lesion Size vs. Diagnosis

-- Calculate the average lesion area for each diagnostic category.


SELECT 
		diagnostic,
		ROUND(AVG(diameter_1)) AS avg_diameter_mm			-- this calculates the avg diameter_1( one axis of the lesion) per diagnostic
FROM lesion_patient_view
GROUP BY 1

-- lesions are 2D shapes, not just single diameters. 

	-- Area = 𝜋 * (diameter_1)/2 * (diameter_2)/2

SELECT
    diagnostic,
    ROUND(AVG(3.142 * diameter_1/2 * diameter_2/2)::numeric, 2) AS avg_area_mm2	-- this calculates the avg diameter_1 and diameter_2( two axis of the lesion) per diagnostic
FROM lesion_patient_view
GROUP BY diagnostic
ORDER BY avg_area_mm2 DESC;


-- Cancer Symptom Indicator

-- (a) For each diagnostic category, how many lesions exhibit each key symptom (itching, bleeding, growth, pain, color change, elevation),
-- and how many have been confirmed via biopsy?”

SELECT diagnostic,
    SUM(CASE WHEN itch = TRUE THEN 1 ELSE 0  END ) AS lesion_itching,
    SUM(CASE WHEN bleed = TRUE THEN 1 ELSE 0  END ) AS lesion_bleeding,		
    SUM(CASE WHEN grew = TRUE THEN 1 ELSE 0  END ) AS lesion_grown,
    SUM(CASE WHEN hurt = TRUE THEN 1 ELSE 0  END ) AS lesion_hurts,
    SUM(CASE WHEN changed = TRUE THEN 1 ELSE 0  END ) AS lesion_changed_color,
    SUM(CASE WHEN elevation = TRUE THEN 1 ELSE 0  END ) AS lesion_elevates,
    SUM(CASE WHEN biopsed = TRUE THEN 1 ELSE 0  END ) AS biopsy_confirmed
FROM lesion_patient_view
GROUP BY diagnostic;


-- (b) For each diagnostic type, how many lesions show no symptoms (such as itching, bleeding, growth, pain, color change, or elevation) 
-- and have not been confirmed by biopsy?

SELECT diagnostic,
    SUM(CASE WHEN itch = FALSE THEN 1 ELSE 0  END ) AS no_itching,
    SUM(CASE WHEN bleed = FALSE THEN 1 ELSE 0  END ) AS no_bleeding,		
    SUM(CASE WHEN grew = FALSE THEN 1 ELSE 0  END ) AS no_growth,
    SUM(CASE WHEN hurt = FALSE THEN 1 ELSE 0  END ) AS no_hurts,
    SUM(CASE WHEN changed = FALSE THEN 1 ELSE 0  END ) AS no_colour_change,
    SUM(CASE WHEN elevation = FALSE THEN 1 ELSE 0  END ) AS no_elevation,
    SUM(CASE WHEN biopsed = FALSE THEN 1 ELSE 0  END ) AS biopsy_not_confirmed
FROM lesion_patient_view
GROUP BY diagnostic;

-- High-Risk Patient


-- Create a table listing all patients who:
	-- Have a personal history of skin cancer
	-- Are over 50
	-- Have at least one lesion diagnosed as BCC or MEL or SCC
	 -- Are exposed to pesticides

SELECT
    patient_id,
	diagnostic,
	fitspatrick,
	region,
    gender,
    age,
    background_father,
    background_mother,
    has_piped_water,
    has_sewage_system,
    pesticide, 
    COUNT(*) AS high_risk_lesion_count
FROM lesion_patient_view
WHERE
    skin_cancer_history = TRUE
    AND age > 50
    AND pesticide = TRUE
    AND diagnostic IN ('BCC', 'MEL', 'SCC')
GROUP BY 
    patient_id,
	diagnostic,
	fitspatrick,
	region,
    gender,
    age,
    background_father,
    background_mother,
    has_piped_water,
    has_sewage_system,
    pesticide
ORDER BY high_risk_lesion_count DESC;




