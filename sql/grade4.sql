
SELECT b.*, p.properties->>'email' FROM (
    SELECT 
        participant_id,
        participant_name, 
        team_name,
        round(sum(grade), 1) AS grade, 
        round(sum(bonus), 1) AS bonus, 
        round(sum(total), 1) AS total, 
        sum(points) AS points
    FROM per_deliverable 
    GROUP BY participant_id, participant_name, team_name
    ORDER BY total ASC 
    LIMIT 8
) b INNER JOIN participant p 
ON b.participant_id = p.id
;
