require_relative '../command'
require_relative '../schedule_helper'
require_relative '../sch/schedule'
require_relative '../comm/emote'

class ScheduleCommand
  extend Command
  extend ScheduleHelper

  CMD_NAME = :schedule
  HELP_MSG = File.read("assets/help_messages/schedule_help.txt")
  OPTIONS = {
    description: ':calendar: Set your schedule for others to see.',
    usage: '`&schedule` **[from dd/mm/yy hh:mm to dd/mm/yy hh:mm {activity}]**'
  }

  def self.call(event, *args)

    schedule_data_path = "data/user/where/#{event.user.distinct}"

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
          event << ":poop: `schedule`: __You forgot to specify the starting date!__"
        elsif args[2] == nil
          event << ":poop: `schedule`: __You forgot to specify the starting time!__"
        elsif args[3] != 'to'
          event << ":poop: `schedule`: __You forgot to use the 'to' keyword:__ `&schedule from {starting date} {time} to {finishing date} {time} {activity}`"
        elsif args[4] == nil
          event << ":poop: `schedule`: __You forgot to specify the finishing date!__"
        elsif args[5] == nil
          event << ":poop: `schedule`: __You forgot to specify the finishing time!__"
        elsif args[6] == nil
          event << ":poop: `schedule`: __You forgot to specify the activity!__"
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
        sch_event = Schedule::Event.new(event_args[:from], event_args[:to], event_args[:activity])
        schedule.add_event(sch_event)
        schedule.write(schedule_data_path)

        event << "Your schedule has been set!\n" + sch_event.print_tz(schedule.timezone)
      end

    # **** 'Weekly' keyword handler ****
    when :weekly
      if args.length < 7
        if args[1] == nil
          event << ":poop: `schedule`: __You forgot to specify the starting day!__"
        elsif args[2] == nil
          event << ":poop: `schedule`: __You forgot to specify the starting time!__"
        elsif args[3] != 'to'
          event << ":poop: `schedule`: __You forgot to use the 'to' keyword:__ `&schedule #{keyword.upcase} DAY {starting time} to DAY {finishing time} {activity}`"
        elsif args[4] == nil
          event << ":poop: `schedule`: __You forgot to specify the finishing day!__"
        elsif args[5] == nil
          event << ":poop: `schedule`: __You forgot to specify the finishing time!__"
        elsif args[6] == nil
          event << ":poop: `schedule`: __You forgot to specify the activity!__"
        else
          event << personal_help(event.user.username)
        end
      else

        sday = args[1].length == 3 ? Schedule::WeekTime::ABBREV_TO_COMPLETE[args[1].upcase] : args[1].capitalize
        fday = args[4].length == 3 ? Schedule::WeekTime::ABBREV_TO_COMPLETE[args[4].upcase] : args[4].capitalize
        st = args[2].split(':').collect(&:to_i)
        ft = args[5].split(':').collect(&:to_i)

        if sday == nil || fday == nil
          event << ":poop: Invalid day!"
        elsif st == nil || ft == nil
          event << ":poop: Invalid time!"
        elsif args[6].length > Schedule::Event::MAX_ACTIVITY_LENGTH
          event << ":poop: Activity too long! The activity must be #{Schedule::Event::MAX_ACTIVITY_LENGTH} or fewer."
        else
          begin
            weekly_event = Schedule::WeeklyEvent.new(Schedule::WeekTime.parse("#{args[1]} #{args[2]} #{schedule.timezone}"), Schedule::WeekTime.parse("#{args[4]} #{args[5]} #{schedule.timezone}"), args[6])
          rescue ArgumentError => e
            puts "ArgumentError:".red + " #{e.message}\n" + "BACKTRACE:".yellow + "\n#{e.backtrace.join("\n")}\n\n"
            return personal_help(event.user.username)
          end

          schedule.add_event(weekly_event)
          schedule.write(schedule_data_path)

          event << ":calendar: Your schedule has been set! Added a new weekly event:\n" + weekly_event.print_tz(schedule.timezone)
        end
      end

    # **** 'Preset' keyword handler ****
    when :preset
      if args[1] == nil
        event << ":poop: `schedule`: __No preset specified!__ To view presets, use `.presets`"
      elsif !(Schedule::Preset::presets.collect{ |pre| pre[:name].downcase.to_sym }.include?(args[1].to_s.downcase.to_sym))
        event << ":poop: `schedule`: __Preset not found!__ To view presets, use `.presets`"
      elsif !(['enable', 'disable'].include?(args[2].to_s.downcase))
        event << ":poop: `schedule`: __Invalid setting specified!__"
      else
        preset = Schedule::Preset::get_preset(args[1])
        if args[2].downcase == 'enable'
          schedule.add_preset(preset)
          schedule.write(schedule_data_path)
          event << ":calendar: #{preset.name.capitalize} preset was added to your schedule! Use `&schedule view` to view your schedule."
        else
          if schedule.enabled_presets.include?(preset.name)
            schedule.remove_preset(preset)
            schedule.write(schedule_data_path)
            event << "#{preset.name.capitalize} preset was removed from your schedule!"
          else
            event << "You don't have that preset enabled! To enable a preset, use `&schedule preset {preset} ENABLE|DISABLE`"
          end
        end
      end


    # **** View your current schedule ****
    when :view
      if schedule.events.to_a.length == 0
        event << 'You have nothing scheduled! Add events with `&schedule from [DD/MM/YY] [HH:MM] to [DD/MM/YY] [HH:MM] {activity}`'
      elsif args[1] == 'more'
        event.channel.send_embed('', schedule.to_embed(true))
      else
        event.channel.send_embed('', schedule.to_embed)
      end

    # **** Clear your schedule completely ****
    when :clear
      if args[1].to_s.upcase == 'YES'
        schedule.events.clear
        schedule.write(schedule_data_path)
        event << ":fire: Your schedule was cleared!"
      else
        event << "Are you sure you want to **completely** clear your schedule? __This action is irreversible.__\nType `&schedule clear YES` to continue."
      end

    # **** Remove an event from your schedule ****
    when :remove
      id = args[1]
      if id.to_s.length != 6
        event << ':poop: Invalid event ID!'
      else
        event_ids = schedule.events.sort_by { |e| e.from.to_i }.collect(&:id)
        if event_ids.include?(id)
          if args[2].to_s.upcase == 'YES'
            schedule.remove_event(id)
            schedule.write(schedule_data_path)
            event << ":fire: The event with ID __#{id}__ was removed."
          else
            event << "Are you sure you want to remove this event? __This action is irreversible.__\nType `&schedule remove #{id} YES` to continue"
          end
        else
          event << ':poop: There is no event corresponding to that ID!'
        end
      end

    # **** Set the user's timezone ****
    when :timezone
      tz = args[1].to_s.capitalize
      if tz == ''
        event << "#{Emote::clock_now(schedule.timezone)} Your timezone is currently set to #{schedule.timezone}."
        return
      end

      timezone = Schedule::Event.get_timezone(tz)
      if timezone
        schedule.timezone = timezone
        schedule.write(schedule_data_path)
        event << "#{Emote::get_flag(timezone)} Your schedule will now be displayed in the #{schedule.timezone} timezone."
      else
        event << "Cannot find a timezone for that city!"
      end

    # **** Invalid command handler
    else
      return event << personal_help(event.user.username)
    end

  end

end
