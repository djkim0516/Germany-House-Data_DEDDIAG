------------------------------------------------------------------------------------------------------------------------
-- Create tables without foreign keys to speed up import
------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS houses (
    id      SERIAL not null PRIMARY KEY,
    persons JSON
);
------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS items (
    id      SERIAL not null PRIMARY KEY,
    name    VARCHAR(500) not null,
    category    VARCHAR(500) not null,
    house   INTEGER
);
------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS measurements (
    item_id INTEGER,
    time    TIMESTAMP,
    value   FLOAT
);
------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS annotation_labels (
  id SERIAL not null PRIMARY KEY,
  item_id INTEGER,
  text TEXT,
  description TEXT
);
------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS annotations (
  id SERIAL not null PRIMARY KEY,
  item_id INTEGER,
  label_id INTEGER ,
  start_date TIMESTAMP,
  stop_date TIMESTAMP
);
------------------------------------------------------------------------------------------------------------------------
alter system set max_wal_size = 4096;
