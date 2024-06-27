CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "unaccent";

create table event(
    id uuid PRIMARY KEY default gen_random_uuid(),
    name text,
    properties JSONB,
    UNIQUE(name)
);

create table participant(
    id uuid PRIMARY KEY default gen_random_uuid(),
    name text,
    properties JSONB,
    UNIQUE(name)
);

create table team(
    id uuid PRIMARY KEY default gen_random_uuid(),
    event_id uuid references event(id) ON DELETE CASCADE,
    name text,
    identifier integer,
    unique(event_id, identifier),
    unique(event_id, name)
);

create table participant_to_team(
    participant_id uuid references participant(id),
    team_id uuid references team(id) ON DELETE CASCADE,
    UNIQUE(participant_id, team_id)
);

create type basis_type AS ENUM('individual', 'team');
create table deliverable_type(
    id uuid PRIMARY KEY default gen_random_uuid(),
    event_id uuid references event(id) ON DELETE CASCADE,
    name TEXT,
    description TEXT,
    due_date TIMESTAMPTZ,
    basis basis_type,
    points NUMERIC,
    UNIQUE(event_id, name)
);

create table deliverable(
    id uuid PRIMARY KEY default gen_random_uuid(),
    deliverable_type_id uuid references deliverable_type(id) ON DELETE CASCADE,
    author_id uuid NOT NULL,
    grade NUMERIC,
    iteration INTEGER DEFAULT 0,
    details JSONB,
    UNIQUE(deliverable_type_id, author_id)
);

create table bonus(
    deliverable_id uuid NOT NULL,
    note TEXT,
    bonus NUMERIC
);

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
