WITH grades AS (
    SELECT participant_id, participant_name, round(sum(grade), 1) AS grade
    FROM (
    SELECT p.id AS participant_id, p.name AS participant_name, grade
        FROM deliverable d
        INNER JOIN team t 
        ON d.author_id = t.id 
        INNER JOIN participant_to_team ptt 
        ON t.id = ptt.team_id 
        INNER JOIN participant p 
        ON ptt.participant_id = p.id
    UNION 
    SELECT p.id AS participant_id, p.name AS participant_name, grade
        FROM deliverable d
        INNER JOIN participant p 
        ON d.author_id = p.id 
    ) s
    GROUP BY s.participant_id, s.participant_name
    ORDER BY grade DESC
), bonuses AS (
    SELECT participant_id, participant_name, round(sum(bonus), 1) AS bonus
    FROM (
    SELECT p.id AS participant_id, p.name AS participant_name, bonus
        FROM deliverable d
        INNER JOIN team t 
        ON d.author_id = t.id 
        INNER JOIN participant_to_team ptt 
        ON t.id = ptt.team_id 
        INNER JOIN participant p 
        ON ptt.participant_id = p.id
        INNER JOIN bonus b
        ON d.id = b.deliverable_id
    UNION 
    SELECT p.id AS participant_id, p.name AS participant_name, bonus
        FROM deliverable d
        INNER JOIN participant p 
        ON d.author_id = p.id 
        INNER JOIN bonus b
        ON d.id = b.deliverable_id
    ) s
    GROUP BY s.participant_id, s.participant_name
    ORDER BY bonus DESC
)
SELECT 
g.participant_id AS participant_id, 
g.participant_name AS participant_name, 
grade, bonus, grade + bonus AS total 
FROM grades g INNER JOIN bonuses b ON g.participant_id = b.participant_id