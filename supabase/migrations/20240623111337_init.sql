CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

create table event(
    id uuid PRIMARY KEY default gen_random_uuid(),
    name text,
    properties JSONB
);

create table participant(
    id uuid PRIMARY KEY default gen_random_uuid(),
    event_id uuid references event(id),
    name text,
    properties JSONB
);

create table team(
    id uuid PRIMARY KEY default gen_random_uuid(),
    name text,
    identifier integer,
    unique(event_id, identifier)
);

create table participant_to_team(
    participant_id uuid references participant(id),
    team_id uuid references team(id)
);

create table deliverable_type(
    id uuid PRIMARY KEY default gen_random_uuid(),
    event_id uuid references event(id),
    name TEXT,
    description TEXT,
    due_date TIMESTAMPTZ
    points NUMERIC(2)
);

create table deliverable(
    id uuid PRIMARY KEY default gen_random_uuid(),
    deliverable_type_id uuid references deliverable_type(id),
    author_id uuid NOT NULL,
    artefact_name TEXT,
    grade NUMERIC(2),
    details JSONB
);

create table bonus_malus(
    author uuid NOT NULL,
    description TEXT,
    bonus NUMERIC(2)
)