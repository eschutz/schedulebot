require_relative 'sch/schedule'
require_relative 'path_helper'

# ScheduleHelper contains methods that assist in loading and manipulating schedules
module ScheduleHelper

  def get_schedule(user_distinct)
    schedule_data_path = PathHelper::get_data_path("user/where/#{user_distinct}")
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

  def parse_date(date, timezone)
    parsed_date = date.split(/\/|\-/).reverse.join('-')

    case date
    when "today"
      parsed_date = Time.now.in_time_zone(timezone).strftime("%F")
    when "tomorrow"
      parsed_date = (Time.now + 86400).in_time_zone(timezone).strftime("%F")
    end

    return parsed_date
  end

  def parse_time(time, timezone)
    parsed_time = time
    case parsed_time
    when "now"
      parsed_time = Time.now.in_time_zone(timezone).strftime("%H:%M")
    end

    return parsed_time
  end

end
