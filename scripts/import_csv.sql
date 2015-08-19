\c app_api_development;
COPY "appts"(start_time, end_time, first_name, last_name, comments) FROM '/Users/westoncooper/wyncode/Sinatra/app_api/appt_data.txt' DELIMITER ',' CSV HEADER;