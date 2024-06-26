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