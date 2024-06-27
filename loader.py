import openpyxl
import psycopg
import sys
import os
import json

from functools import partial
from psycopg.types.json import Jsonb
from psycopg.rows import dict_row

from uuid import UUID, uuid4

from dotenv import load_dotenv

load_dotenv()


class UUIDEncoder(json.JSONEncoder):
    """A JSON encoder which can dump UUID."""
    def default(self, obj):
        if isinstance(obj, UUID):
            return str(obj)
        return json.JSONEncoder.default(self, obj)

uuid_dumps = partial(json.dumps, cls=UUIDEncoder, default=str)

def clean_row(row):
    return_row = []
    for c in row:
        if type(c) is str:
            c = c.strip()
        return_row.append(c)
    return return_row

def sheet_to_dict(sheet):
    values = sheet.values
    header = [col for col in next(values)]
    return [dict(zip(header, clean_row(l))) for l in values if l[0]]

def lookup_participant_id(cur, name):
    result = cur.execute(
        "SELECT id as participant_id FROM participant WHERE unaccent(name) ILIKE unaccent(%s)",
        [participant_name])
    row = result.fetchone()
    if not row:
        raise Exception(f"No match for {name}")
    return row['participant_id']

def lookup_team_id(cur, team_identifier):
    result = cur.execute(
        "SELECT id FROM team WHERE identifier = %s", [team_identifier]
    )
    row = result.fetchone()
    if not row:
        raise Exception(f"Not found: team {team_identifier}")
    return row['id']

wb = openpyxl.open('evaluation.xlsx', data_only=True)

event = {
    'id': '51a9a095-d794-4315-a0fd-c723b265d532',
    'name': 'UTSEUS Innovation Bootcamp June 2024'
}

participants = sheet_to_dict(wb['participant'])
teams = sheet_to_dict(wb['team'])
deliverable_types = sheet_to_dict(wb['evaluation'])
lookup_deliverable_type = {}

with psycopg.connect(os.environ['POSTGRES'], row_factory=dict_row) as conn:
    with conn.cursor() as cur:
        cur.execute('DELETE FROM "event" CASCADE;')
        cur.execute('DELETE FROM participant CASCADE;')
        cur.execute('INSERT INTO event(id, name) VALUES (%(id)s, %(name)s)', event)

        for participant in participants:
            participant['event_id'] = event['id']
            cur.execute(
                "INSERT INTO participant(name, properties) VALUES(%s, %s)",
                [participant['name'], Jsonb(participant)]
                )

        for team in teams:
            team['event_id'] = event['id']
            output = cur.execute(
                "INSERT into team(name, event_id, identifier)"
                " VALUES(%(name)s, %(event_id)s, %(team)s)"
                " RETURNING id",
                team)
            team['id'] = output.fetchone()['id']
            for i in range(1,6):
                member_key = 'member' + str(i)
                if member_key not in team or not team[member_key]:
                    break
                participant_name = team[member_key]
                participant_id = lookup_participant_id(cur, participant_name)
                cur.execute(
                    "INSERT INTO participant_to_team(participant_id, team_id) VALUES(%s, %s)",
                    [participant_id, team['id']])

        for deliverable_type in deliverable_types:
            deliverable_type['event_id'] = event['id']
            output = cur.execute(
                'INSERT INTO deliverable_type(event_id, name, description, due_date, points, basis)'
                ' VALUES(%(event_id)s, %(name)s, %(description)s, %(due_date)s, %(points)s, %(basis)s)'
                ' RETURNING id',
                deliverable_type)
            deliverable_type['id'] = output.fetchone()['id']
            lookup_deliverable_type[deliverable_type['name']] = deliverable_type

        for deliverable_type_name in lookup_deliverable_type.keys():
            print(deliverable_type_name)
            deliverable_type = lookup_deliverable_type[deliverable_type_name]
            if deliverable_type_name not in wb:
                print(f'{deliverable_type_name} not found, no such sheet')
                continue
            deliverable_rows = sheet_to_dict(wb[deliverable_type_name])
            for deliverable in deliverable_rows:
                deliverable['deliverable_type_id'] = deliverable_type['id']
                if 'name' in deliverable:
                    assert deliverable_type['basis'] == 'individual'
                    if not deliverable['name']:
                        print('name column but value is None, exiting processing of sheet')
                        break
                    participant_name = deliverable['name']
                    deliverable['author_id'] = lookup_participant_id(cur, participant_name)
                elif 'team' in deliverable:
                    assert deliverable_type['basis'] == 'team', deliverable
                    if not deliverable['team']:
                        print('team column but value is None, exiting processing of sheet')
                        break
                    team_identifier = deliverable['team']
                    deliverable['author_id'] = lookup_team_id(cur, team_identifier)
                else:
                    raise Exception(f"Missing name or team: {deliverable}")
                assert 'score' in deliverable, deliverable
                assert float(deliverable['score']) <= deliverable_type['points'], deliverable
                output = cur.execute(
                    'INSERT INTO deliverable(deliverable_type_id, author_id, grade)'
                    ' VALUES(%(deliverable_type_id)s, %(author_id)s, %(score)s)'
                    ' ON CONFLICT(deliverable_type_id, author_id)'
                    ' DO UPDATE SET grade = EXCLUDED.grade'
                    ' RETURNING id, iteration',
                    deliverable)
                row = output.fetchone()
                cur.execute(
                    'UPDATE deliverable SET details = %s WHERE id = %s',
                    [Jsonb(deliverable, dumps=uuid_dumps), row['id']])
                deliverable['id'] = row['id']

                if row['iteration'] > 1:
                    cur.execute(
                        'INSERT INTO bonus(deliverable_id, note, bonus)'
                        ' VALUES(%s, %s, %s)',
                        [deliverable['id'], 'iteration', 0.1])
                cur.execute(
                    'UPDATE deliverable SET iteration = iteration + 1 WHERE id = %s',
                    [deliverable['id']])

                for k in deliverable.keys():
                    if k is None or deliverable[k] is None or not 'bonus' in k:
                        continue
                    bonus_name = ' '.join(k.split(' ')[1:])
                    value = float(deliverable[k])
                    if value != 0:
                        # print(f"bonus {bonus_name} = {value}")
                        cur.execute(
                            'INSERT INTO bonus(deliverable_id, note, bonus)'
                            ' VALUES(%s, %s, %s)',
                            [deliverable['id'], bonus_name, deliverable[k]])
