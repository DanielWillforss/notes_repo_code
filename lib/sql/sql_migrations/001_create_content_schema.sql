-- Create notes table
DROP TABLE IF EXISTS notes;

CREATE TABLE notes (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    parent_id INTEGER,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
