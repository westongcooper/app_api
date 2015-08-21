#switch database access for testing environment
if ENV['RACK_ENV'] == 'test'
  DB = Sequel.connect(:adapter=>'postgres',
                      :host=>'localhost',
                      :database=>'app_api_test',
                      :user=>'westoncooper')
else
  DB = Sequel.connect(:adapter=>'postgres',
                      :host=>'localhost',
                      :database=>'app_api_development',
                      :user=>'westoncooper',
                      :password=>ENV['PG_password'])
end

class Appt < Sequel::Model
  plugin :validation_helpers
  plugin :validation_class_methods
  set_primary_key [:id]
  def validate #validate new appointments and updates
    super
    validates_presence [:first_name, :last_name, :start_time, :end_time]
    validates_format /^[a-zA-Z]+$/, [:first_name, :last_name]
    validates_format /^$|^[a-zA-Z0-9 .!?"-]+$/, :comments
    validates_schema_types [:start_time, :end_time]
  end
  #checks each Start_time and End_time for overlapping conflicts and invalid datetime
  validates_each :start_time, :end_time do |object, attribute, value|
    object.errors.add(attribute, 'datetime overlap') if overlap_date?(object, attribute, value)
  end
  validates_each :start_time do |object, attribute, value|
    object.errors.add(attribute, 'old_start_date') if old_start_date?(value)
    object.errors.add(attribute, 'invalid datetime') if invalid_dates?(object)
    object.errors.add(attribute, 'datetime overlap') if surround_date?(object)
  end

end

def invalid_dates?(object)
  begin
    (object[:start_time] > object[:end_time] || #checks to see if end time is before start time
      object[:start_time] == object[:end_time]) #checks for valid appointment time
  rescue Exception
    true
  end
end

def old_start_date?(value)
  begin
    value < Time.now #checks for future date
  rescue Exception
    true
  end
end

def overlap_date?(object, attribute, time)
  begin
    if attribute == :start_time
      pg_code = "(start_time <= '#{time}')"
      pg_code2 = "(end_time > '#{time}')"
    else #if testing :end_time
      pg_code = "(end_time >= '#{time}')"
      pg_code2 = "(start_time < '#{time}')"
    end
    if object[:id]
      pg_code2 += " AND (id != #{object[:id]})"
    end
    old_appts = Appt.where{pg_code}.where{pg_code2}
    old_appts.any?
  rescue Exception
    true
  end
end
def surround_date?(object)
  begin
    pg_code = "(start_time > '#{object[:start_time]}') AND (start_time < '#{object[:end_time]}')"
    old_appts = Appt.where{pg_code}
    old_appts.any?
  rescue Exception
    true
  end
end
