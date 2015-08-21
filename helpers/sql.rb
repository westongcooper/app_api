def create_sql_helper
  if filter_params['start_time']
    start_time = "(start_time >= '#{filter_params['start_time']}')"
  end
  if filter_params['end_time']
    end_time = "(end_time <= '#{filter_params['end_time']}')"
  end
  if filter_params['start_time'] && filter_params['end_time']
    pg_code = "#{start_time} AND #{end_time}"
  elsif filter_params['start_time']
    pg_code = start_time
  else
    pg_code = end_time
  end
  pg_code
end
