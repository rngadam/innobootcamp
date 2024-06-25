CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "unaccent";

create table event(
    id uuid PRIMARY KEY default gen_random_uuid(),
    name text,
    properties JSONB
);

create table participant(
    id uuid PRIMARY KEY default gen_random_uuid(),
    name text,
    properties JSONB
);

create table team(
    id uuid PRIMARY KEY default gen_random_uuid(),
    event_id uuid references event(id),
    name text,
    identifier integer,
    unique(event_id, identifier)
);

create table participant_to_team(
    participant_id uuid references participant(id),
    team_id uuid references team(id)
);

create type basis_type AS ENUM('individual', 'team');
create table deliverable_type(
    id uuid PRIMARY KEY default gen_random_uuid(),
    event_id uuid references event(id),
    name TEXT,
    description TEXT,
    due_date TIMESTAMPTZ,
    basis basis_type,
    points NUMERIC(3)
);

create table deliverable(
    id uuid PRIMARY KEY default gen_random_uuid(),
    deliverable_type_id uuid references deliverable_type(id),
    author_id uuid NOT NULL,
    grade NUMERIC(3),
    details JSONB
);

create table bonus(
    deliverable_id uuid NOT NULL,
    note TEXT,
    bonus NUMERIC(3)
)