/*
Found free slots to take appointments
- Everything is in the same table (openings and appointments)
- Openings can be recuring
- We only display free slot for a week
- Appointements are every 30min
 */

DROP TABLE IF EXISTS events;
DROP TYPE IF EXISTS event_type CASCADE;

CREATE TYPE event_type AS ENUM ('opening', 'appointment');
CREATE TABLE events(
  id SERIAL PRIMARY KEY,
  starts_at timestamp without time zone NOT NULL,
  ends_at timestamp without time zone NOT NULL,
  weekly_recurring boolean NOT NULL,
  kind  event_type NOT NULL
);

INSERT INTO events(starts_at, ends_at, weekly_recurring, kind)
VALUES
('2020-05-08 12:30', '2020-06-01 16:00', true, 'opening'), -- Old recuring friday
('2020-06-01 09:30', '2020-06-01 12:30', false, 'opening'), -- Monday
('2020-04-01 09:30', '2020-06-01 19:30', false, 'opening'), -- Non recuring previous date filtered
('2020-09-01 09:30', '2020-09-01 19:30', false, 'opening'), -- Non recuring futur date filtered

('2020-06-01 11:30', '2020-06-01 12:30', false, 'appointment'), -- Monday
('2020-06-05 13:30', '2020-06-05 14:00', false, 'appointment'); -- Friday

---------------------------------------------------------------------------------------------------------------
WITH openings AS (
  SELECT * FROM events
  WHERE events.kind = 'opening'
  AND (
    (weekly_recurring IS TRUE AND ends_at < '2020-06-07'::TIMESTAMP)
    OR
    (weekly_recurring IS FALSE AND starts_at >= '2020-06-01'::TIMESTAMP AND ends_at < '2020-06-07'::TIMESTAMP)
  )
),
appointments AS (
  SELECT * FROM events
  WHERE events.kind = 'appointment'
  AND starts_at >= '2020-06-01'::TIMESTAMP AND ends_at < '2020-06-07'::TIMESTAMP
),
timetable AS (
  SELECT generate_series(
    '2020-06-01'::TIMESTAMP, -- Provided by the app
    '2020-06-07'::TIMESTAMP, -- Provided by the app
    '30 minutes') AS slot_time
)
SELECT timetable.slot_time
FROM timetable
JOIN openings
  ON date_part('dow', timetable.slot_time) = date_part('dow', openings.starts_at) -- We match day number the of the week number
  AND timetable.slot_time::time >= openings.starts_at::time -- we match only opening hours
  AND timetable.slot_time::time < openings.ends_at::time
LEFT OUTER JOIN appointments
  ON timetable.slot_time >= appointments.starts_at -- we match appointments times
  AND timetable.slot_time < appointments.ends_at
WHERE appointments.kind IS NULL; -- unselected appointments
