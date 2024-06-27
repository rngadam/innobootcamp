CREATE OR REPLACE VIEW grades AS (
    SELECT d.id AS deliverable_id, p.id AS participant_id, grade
        FROM deliverable d
        INNER JOIN team t
        ON d.author_id = t.id
        INNER JOIN participant_to_team ptt
        ON t.id = ptt.team_id
        INNER JOIN participant p
        ON ptt.participant_id = p.id
    UNION
    SELECT d.id AS deliverable_id, p.id AS participant_id, grade
        FROM deliverable d
        INNER JOIN participant p
        ON d.author_id = p.id
);

CREATE OR REPLACE VIEW bonuses AS (
    SELECT deliverable_id, participant_id, sum(bonus) AS bonus FROM (
        SELECT d.id AS deliverable_id, p.id AS participant_id, bonus
            FROM deliverable d
            INNER JOIN bonus
            ON d.id = bonus.deliverable_id
            INNER JOIN team t
            ON d.author_id = t.id
            INNER JOIN participant_to_team ptt
            ON t.id = ptt.team_id
            INNER JOIN participant p
            ON ptt.participant_id = p.id
        UNION
        SELECT d.id AS deliverable_id, p.id AS participant_id, bonus
            FROM deliverable d
            INNER JOIN bonus
            ON d.id = bonus.deliverable_id
            INNER JOIN participant p
            ON d.author_id = p.id
    ) b
    GROUP BY deliverable_id, participant_id
);

CREATE OR REPLACE VIEW bonuses_subtotals AS (
    SELECT deliverable_id, participant_id, sum(COALESCE(bonus, 0)) AS bonus
    FROM bonuses
    GROUP BY deliverable_id, participant_id
);


CREATE OR REPLACE VIEW per_deliverable AS (
    SELECT
        g.participant_id,
        dt.name AS deliverable_name,
        p."name" AS participant_name,
        t."name" AS team_name,
        g.grade,
        COALESCE(b.bonus, 0) AS bonus,
        g.grade + COALESCE(b.bonus, 0) AS total,
        points,
        basis
    FROM grades g
    INNER JOIN participant p
    ON p.id = g.participant_id
    INNER JOIN participant_to_team ptt
    ON p.id = ptt.participant_id
    INNER JOIN team t
    ON ptt.team_id = t.id
    INNER JOIN deliverable d
    ON d.id = g.deliverable_id
    LEFT JOIN bonuses_subtotals b
    ON g.participant_id  = b.participant_id AND g.deliverable_id = b.deliverable_id
    INNER JOIN deliverable_type dt
    ON d.deliverable_type_id = dt.id
    ORDER BY due_date
);