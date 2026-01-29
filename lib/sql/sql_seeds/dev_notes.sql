-- Insert dummy data
INSERT INTO notes (parent_id, title, body)
VALUES
(NULL, 'Seed note', 'Hello from seed'),
(
    NULL,
    'First note',
    'This is my first note'
),
(
    1,
    'Second note',
    'body: Another note, priority: high'
),
(
    2,
    'Ideas',
    'build app, design schema, write tests'
),
(
    3,
    'Idea2',
    'build sadgsdgma, write tests'
);