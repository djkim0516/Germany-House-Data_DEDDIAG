------------------------------------------------------------------------------------------------------------------------
-- Add Foreign Keys
------------------------------------------------------------------------------------------------------------------------
ALTER TABLE items ADD CONSTRAINT items_house_fkey FOREIGN KEY (house) REFERENCES houses(id);
------------------------------------------------------------------------------------------------------------------------
ALTER TABLE measurements ADD CONSTRAINT measurements_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);
------------------------------------------------------------------------------------------------------------------------
ALTER TABLE annotation_labels ADD CONSTRAINT annotation_labels_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);
------------------------------------------------------------------------------------------------------------------------
ALTER TABLE annotations ADD CONSTRAINT annotations_label_id_fkey FOREIGN KEY (label_id) REFERENCES annotation_labels(id);
-----------------------------------------------------------------------------------------------------------------------
ALTER TABLE annotations ADD CONSTRAINT annotations_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id);
-----------------------------------------------------------------------------------------------------------------------
-- Create Index
------------------------------------------------------------------------------------------------------------------------
CREATE INDEX idx_measurements_time ON measurements (time);
------------------------------------------------------------------------------------------------------------------------
CREATE INDEX idx_measurements_id_time ON measurements (item_id, time);
------------------------------------------------------------------------------------------------------------------------
-- Create Functions
------------------------------------------------------------------------------------------------------------------------
CREATE or REPLACE FUNCTION round_timestamp(timestamp, integer DEFAULT 1) returns
timestamp as $$
    select 'epoch'::timestamp + '1 second'::interval * ($2 *
    round(date_part('epoch', $1) / $2));
$$ language sql immutable;
------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE function get_measurements(item_id integer, from_time timestamp without time zone, to_time timestamp without time zone) returns SETOF measurements
    language sql
as
$$
WITH q AS (
      SELECT
        round_timestamp(time) AS time,
        value
      FROM
        measurements
       WHERE
          item_id=$1
          AND time between (SELECT time from measurements WHERE item_id=$1 and time <= $2 ORDER BY time desc LIMIT 1)
          AND (SELECT time from measurements WHERE item_id=$1 and time >= $3 ORDER BY time asc LIMIT 1)
          AND value < 4000
      ),

r AS (SELECT
      s.dte             AS time,
      q.value           AS p1,
      sum(CASE WHEN q.value IS NULL
        THEN 0
          ELSE 1 END)
      OVER (
        ORDER BY s.dte) AS value_partition

    FROM (SELECT generate_series(min(q.time), max(q.time), INTERVAL '1 sec') AS dte
          FROM q
         ) s FULL OUTER JOIN q
        ON s.dte = q.time
    GROUP BY dte, time, value
    ORDER BY dte
)

SELECT $1 as item_id, *
    FROM
      (SELECT
    r.time,
    first_value(p1)
    OVER (PARTITION BY value_partition
      ORDER BY time) AS value
  FROM r) as q2
WHERE time between $2 AND $3
$$;
------------------------------------------------------------------------------------------------------------------------
