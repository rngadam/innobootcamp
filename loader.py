import openpyxl
import psycopg
import dotenv

dotenv.load()

def sheet_to_dict(sheet):
    values = sheet.values
    header = [col.value for col in next(values)]
    return [dict(zip(header, list(l))) for l in values]

wb = openpyxl.open('evaluation.xlsx')

event = {
    id: '51a9a095-d794-4315-a0fd-c723b265d532',
    name: 'UTSEUS Innovation Bootcamp June 2024'
}

participants = sheet_to_dict(wb['participant'])
teams = sheet_to_dict(wb['team'])
deliverable_types = sheet_to_dict(wb['evaluation'])
lookup_deliverable_type = {}
with psycopg.connect(sys.env['POSTGRES']) as conn:
    with conn.cursor() as cur:
        cur.execute('INSERT INTO event(id, name) VALUES (%(id)s, %(name)s)', event)

        for participant in participants:
                cur.execute(
                    "INSERT INTO participant(event_id, name) VALUES(%(event_id)s, %(name)s)",
                    event['id'], participant['name']
                    )

        for team in teams:
            output = cur.execute(
                "INSERT into team(name, identifier) VALUES(%(name), %(team)) RETURNING id", team)
            team['id'] = output['id']
            for i in range(1,6):
                member_key = 'member' + i
                if member_key not in team:
                    break
                participant_name = team[member_key]
                result = cur.execute(
                    "SELECT id as participant_id FROM participant WHERE name ILIKE %s",
                    participant_name)
                participant_id = result['participant_id']
                cur.execute(
                    "INSERT INTO participant_to_team(participant_id, team_id) VALUES(%s, %s)",
                    participant_id, team['id'])

        for deliverable_type in deliverable_types:
            deliverable_type['event_id'] = event['id']
            output = cur.execute(
                'INSERT INTO deliverable_type(event_id, name, description, due_date, points) VALUES(%(event_id)s, %(name)s, %(description)s, %(due_date)s, %(points)s) RETURNING id')
            deliverable_type['id'] = output['id']
            lookup_deliverable_type[deliverable_type['name']] = deliverable_type
