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
  ALTER TABLE tasks ADD COLUMN start_since_dt TEXT;
  ''',
  '''
  ALTER TABLE tasks ADD COLUMN status TEXT NOT NULL DEFAULT "open";
  UPDATE tasks SET status = (
    CASE
      WHEN done THEN 'done'
      WHEN start_since_dt IS NOT NULL THEN 'inWork'
      ELSE 'open'
    END
  );
  ALTER TABLE tasks DROP COLUMN done;
  ''',
  '''
  ALTER TABLE tasks ADD COLUMN link TEXT;
  ''',
  '''
  CREATE TABLE groups (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    system_type TEXT NOT NULL
  ) STRICT;

  CREATE UNIQUE INDEX ux_groups_title ON groups (title);
  CREATE UNIQUE INDEX ux_groups_system_type ON groups (system_type);

  INSERT INTO groups (title, system_type) VALUES ('Сегодня', 'today'), ('Неделя', 'week');

  ALTER TABLE tasks ADD COLUMN groups_ids TEXT;
  '''
];
