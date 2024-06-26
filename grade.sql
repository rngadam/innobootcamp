SELECT participant_id, participant_name, grade, bonus, grade + bonus + 4.8 AS total FROM (
    SELECT participant_id, participant_name, round(sum(grade), 1) AS grade, round(sum(bonus), 1) AS bonus
    FROM (
    SELECT p.id AS participant_id, p.name AS participant_name, sum(grade) AS grade, sum(bonus) AS bonus
        FROM deliverable d
        INNER JOIN team t 
        ON d.author_id = t.id 
        INNER JOIN participant_to_team ptt 
        ON t.id = ptt.team_id 
        INNER JOIN participant p 
        ON ptt.participant_id = p.id
        INNER JOIN bonus b
        ON d.id = b.deliverable_id
        GROUP BY p.id, p.name
    UNION 
    SELECT p.id AS participant_id, p.name AS participant_name, sum(grade) AS grade, sum(bonus) AS bonus
        FROM deliverable d
        INNER JOIN participant p 
        ON d.author_id = p.id 
        INNER JOIN bonus b
        ON d.id = b.deliverable_id
        GROUP BY p.id, p.name
    ) s
    GROUP BY s.participant_id, s.participant_name
) AS f 
ORDER BY total DESC