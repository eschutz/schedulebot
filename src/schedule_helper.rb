require_relative 'sch/schedule'

# ScheduleHelper contains methods that assist in loading and manipulating schedules
module ScheduleHelper

  def get_schedule(user_distinct)
    schedule_data_path = "./data/user/where/#{user_distinct}"
    if File.exists?(schedule_data_path)
      schedule = Schedule.load_schedule(schedule_data_path)
      if schedule == false
        schedule = Schedule.new(user_distinct)
      end
    else
      schedule = Schedule.new(user_distinct)
    end

    return schedule
  end

  def parse_date(date)
    parsed_date = date.split(/\/|\-/).reverse.join('-')

    case date
    when "today"
      parsed_date = Time.now.strftime("%F")
    when "tomorrow"
      parsed_date = (Time.now + 86400).strftime("%F")
    end

    return parsed_date
  end

end
