require 'json'
require_relative '../command'
require_relative '../path_helper'
require_relative '../sch/server_event'

# UNFINISHED - UNUSED
# TODO: Finish and polish &events

class EventsCommand
  extend Command

  CMD_NAME = :events

  HELP_MSG = ''

  OPTIONS = {
    description: ":calendar_spiral: Create, view, and modify server-wide community events.",
    usage: "`&events **[new][view][set_description {id} {description}]**"
  }

  def self.call(event, *args)
    schedule_data_path = PathHelper::get_data_path("server/#{event.server.id}")

    schedule = read_schedule(schedule_data_path)

    keyword = args.first.to_s.downcase.to_sym

    case keyword

    when :new # &events new dd/mm/yy hh:mm to dd/mm/yy hh:mm {activity name}
      if args.length < 7
        if args[1] == nil
          event << ":poop: __You forgot to specify the starting date!__"
        elsif args[2] == nil
          event << ":poop: __You forgot to specify the starting time!__"
        elsif args[3] != 'to'
          event << ":poop: __You forgot to use the 'to' keyword:__ `&events new {date} {time} to {date} {time} {activity}`"
        elsif args[4] == nil
          event << ":poop: __You forgot to specify the finishing date!__"
        elsif args[5] == nil
          event << ":poop: __You forgot to specify the finishing time!__"
        elsif args[6] == nil
          event << ":poop: __You forgot to specify the activity!__"
        else
          event << personal_help(event.user.username)
        end
        return
      end

      # Arguments of the form "from dd/mm/yy hh:mm to dd/mm/yy hh:mm activity"
      begin
        event_args = {from: Time.parse("#{parse_date(args[1])} #{parse_time(args[2])} #{schedule.timezone}"), to: Time.parse("#{parse_date(args[4])} #{parse_time(args[5])} #{schedule.timezone}"), activity: args[6..(args.length - 1)].join(' ')}
      rescue ArgumentError => e
        puts "ArgumentError:".red + " #{e.message}\n" + "BACKTRACE:".yellow + "\n#{e.backtrace.join("\n")}\n\n"
        return personal_help(event.user.username)
      end

      if event_args[:activity].length > Schedule::Event::MAX_ACTIVITY_LENGTH
        event << ":poop: Activity too long! The activity must be #{Schedule::Event::MAX_ACTIVITY_LENGTH} characters or fewer."
      else
        sch_event = Schedule::ServerEvent.new(event_args[:from], event_args[:to], event_args[:activity])
        schedule.add_event(sch_event)
        schedule.write(schedule_data_path)

        event << "Your schedule has been set!\n" + sch_event.print_tz(schedule.timezone)
      end

    when :view

    when :set_description

    end

  end

  private

  def self.read_schedule(path)
    if File.exists?(schedule_data_path)
      file_string = File.read(schedule_data_path)
      if file_string.length > 0
        schedule = JSON.parse(file_string)
      else
        schedule = Hash.new
      end
    else
      schedule = Hash.new
    end

    return schedule
  end

  def self.write_schedule(server_id, schedule, path)
    raise ArgumentError, "#{schedule.class} cannot be coerced into Array" if !(Array === schedule)

    write_schedule = Hash.new

    schedule.each do |event|
      write_schedule.merge(event.serialise)
    end

    File.open(path, 'w') do |f|
      f.write(
        JSON.stringify( {
          server: server_id,
          events: write_schedule
        }.to_json
        )
      )
    end

  end

end
