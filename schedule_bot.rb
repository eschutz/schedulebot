#!/usr/bin/env ruby

require 'discordrb'
require 'time'
require 'colorize'

Dir[Dir.pwd + "/src/sch/*"].each do |file|
  require file
end

class ScheduleBot
  include Discordrb

  TOKEN = "Mjk0ODA5MzAxMDQwNDk2NjQx.C7aiQA.HacES9iU9s4jRtoBq9Qh08sSXXI".freeze
  CLIENT_ID = "294809301040496641".freeze

  def initialize
    @bot = Commands::CommandBot.new(token: TOKEN, client_id: CLIENT_ID, prefix: '.', command_doesnt_exist_message: HelpDialogs::help_dialog)
  end

   def setup
     @bot.command(:info, description: "**Display help & info about ScheduleBot.**") do |event|
       HelpDialogs::help_dialog
     end

     @bot.command(:schedule, description: "Set your schedule for others to see.", usage: "`.schedule` **[DAY TIME \"message\" | from DD/MM/YY hh:mm to DD/MM/YY hh:mm {activity} | {preset}]**") do |event, *args|
       ScheduleBot::cmd_schedule(event, *args)
     end

     @bot.command(:where, description: "Find out where another use is.", usage: "`.where` username") do |event, username|
       ScheduleBot::cmd_where(event, username)
     end
   end

  def start
    begin
      @bot.run
    rescue Interrupt
      @bot.stop
    end
  end

  def self.cmd_where(event, username)
    # Check if the user is in the server
    members = event.channel.server.members
    if members.collect(&:distinct).include?(username)
      queried_user = members.select{|m| m.distinct == username }[0]

      schedule = get_schedule(username)
      tz = schedule.timezone
      events = schedule.events

      if events.none?{|e| e.on?(tz) }
        output_string = "#{username} doesn't have anything scheduled right now."
        if queried_user.game
          output_string << " They are playing #{queried_user.game}."
        else
          output_string << " They are currently #{queried_user.status}."
        end
        event << output_string
      else
        events.each do |e|
          if e.on?(tz)
            (event << (e.where_string || "#{username}'s schedule says they are currently #{e.activity}."))
          end
        end

      end
    else
      event << "#{username} is not on this server. `where` uses the distinct user ID, e.g. User#1234."
    end

    return nil
  end

  def self.cmd_schedule(event, *args)

    schedule_data_path = "./data/user/where/#{event.user.distinct}"

    # Get symbol of first argument
    keyword = args.first.to_s.downcase.to_sym

    # Get schedule corresponding to user
    schedule = get_schedule(event.user.distinct)

    case keyword
    # **** 'From' keyword handler ****
    when :from
      # Error specific messages, instead of just displaying the schedule help
      if args.length < 7
        if args[1] == nil
          event << "`.schedule`: __You forgot to specify the starting date!__"
        elsif args[2] == nil
          event << "`.schedule`: __You forgot to specify the starting time!__"
        elsif args[3] == nil
          event << "`.schedule`: __You forgot to use the 'to' keyword:__ `.schedule from {starting date} {time} to {finishing date} {time} {activity}`"
        elsif args[4] == nil
          event << "`.schedule`: __You forgot to specify the finishing date!__"
        elsif args[5] == nil
          event << "`.schedule`: __You forgot to specify the finishing time!__"
        elsif args[6] == nil
          event << "`.schedule`: __You forgot to specify the activity!__"
        else
          event << HelpDialogs::schedule_help(event.user.username)
        end
        return
      end

      # Arguments of the form "from dd/mm/yy hh:mm to dd/mm/yy hh:mm activity"
      begin
        event_args = {from: Time.parse("#{parse_date(args[1])} #{args[2]} #{schedule.timezone}"), to: Time.parse("#{parse_date(args[4])} #{args[5]} #{schedule.timezone}"), activity: args[6..(args.length - 1)].join(' ')}
      rescue ArgumentError => e
        puts "ArgumentError:".red + " #{e.message}\n" + "BACKTRACE:".yellow + "\n#{e.backtrace.join("\n")}\n\n"
        return HelpDialogs::schedule_help(event.user.username)
      end

      sch_event = Schedule::Event.new(event_args[:from], event_args[:to], event_args[:activity])
      schedule.add_event(sch_event)
      schedule.save(schedule_data_path)

      event << "Your schedule has been set!\n" + sch_event.print_tz(schedule.timezone)

    # **** 'Weekly' keyword handler ****
    when :weekly

    # **** 'Status' keyword handler
    when :status

    # **** 'Preset' keyword handler ****
    when :preset

    # **** View your current schedule ****
    when :view
      if schedule.events.to_a.length == 0
        event << 'You have nothing scheduled! Add events with `.schedule from [DD/MM/YY] [HH:MM] to [DD/MM/YY] [HH:MM] {activity}`'
      elsif args[1] == 'more'
        event << schedule.inspect
      else
        event << schedule.to_s
      end

    # **** Clear your schedule completely ****
    when :clear
      if args[1].to_s.upcase == 'YES'
        schedule.events.clear
        schedule.save(schedule_data_path)
        event << "Your schedule was cleared!"
      else
        event << "Are you sure you want to **completely** clear your schedule? __This action is irreversible.__\nType `.schedule clear YES` to continue."
      end

    # **** Remove an event from your schedule ****
    when :remove
      id = args[1]
      if id.to_s.length != 32
        event << 'Invalid event ID!'
      else
        event_ids = schedule.events.sort.collect(&:id)
        if event_ids.include?(id)
          if args[2].to_s.upcase == 'YES'
            schedule.remove_event(id)
            schedule.save(schedule_data_path)
            event << "The event with id #{id} was removed."
          else
            event << "Are you sure you want to remove this event? __This action is irreversible.__\nType `.schedule remove #{id} YES` to continue"
          end
        else
          event << 'There is no event corresponding to that ID!'
        end
      end

    # **** Set the user's timezone ****
    when :timezone
      tz = args[1].capitalize
      timezone = Schedule::Event.get_timezone(tz)
      if timezone
        schedule.timezone = timezone
        schedule.save(schedule_data_path)
        event << "Your schedule will now be displayed in the #{schedule.timezone} timezone."
      else
        event << "Cannot find a timezone for that city!"
      end


    # **** Invalid command handler
    else
      return event << HelpDialogs::schedule_help(event.user.username)
    end

  end

  # timezone = event.channel.server.region.capitalize

  private

  def self.get_schedule(user_distinct)
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

  def self.parse_date(date)
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

bot = ScheduleBot.new
bot.setup
bot.start
