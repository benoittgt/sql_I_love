/*
Display free 30min slot using generate series and a list of interval
*/

CREATE TABLE openings (
  opening_id serial PRIMARY KEY,
  starttime TIMESTAMP NOT NULL,
  endtime TIMESTAMP NOT NULL
);

INSERT INTO openings (starttime, endtime)
VALUES
  ('2020-06-01 09:00', '2020-06-01 17:00'),
  ('2020-06-04 14:00', '2020-06-04 19:00'),
  ('2020-06-05 09:00', '2020-06-05 17:00'),
  ('2020-06-08 14:00', '2020-06-08 19:00');

WITH RECURSIVE timeslots (opening_id, slot_time) AS (
    SELECT opening_id, generate_series(starttime, (endtime - '00:01'::time), '30 minutes') AS slot_time
    FROM openings
    WHERE opening_id = 1

    UNION

    SELECT opening_id, generate_series(starttime, (endtime - '00:01'::time), '30 minutes') AS slot_time
    FROM openings
    WHERE opening_id > 1
)
SELECT * FROM timeslots ORDER BY slot_time;


