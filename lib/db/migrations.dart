final List<String> migrations = [
  '''
  CREATE TABLE tasks (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    done INTEGER DEFAULT 0,
    parent_id INTEGER,
    idx INTEGER,

    FOREIGN KEY(parent_id) REFERENCES tasks(id) ON DELETE CASCADE
  ) STRICT;
  
  CREATE UNIQUE INDEX ux_tasks_parent_idx ON tasks(COALESCE(parent_id, -1), idx);
  ''',
  '''
  ALTER TABLE tasks ADD COLUMN is_project INTEGER NOT NULL DEFAULT 0;
  ''',
  '''
  ALTER TABLE tasks ADD column start_since_dt TEXT
  ''',
];
