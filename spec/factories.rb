require 'time_params.rb'

FactoryGirl.define do
  factory :appt do
    first_name {Faker::Name.first_name}
    last_name {Faker::Name.last_name}
    start_time {new_time(2016,10)}
    end_time {new_time(2016,20)}
  end
end

def new_time(year, minute)
  Time.new(year, 12, 31, 0, minute, 0, "-05:00")
end
