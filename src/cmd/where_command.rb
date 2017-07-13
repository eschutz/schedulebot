require_relative '../command'
require_relative '../schedule_helper'

class WhereCommand
  extend Command
  extend ScheduleHelper

  CMD_NAME = [:where, :whereis, :where?]
  HELP_MSG = File.read('assets/help_messages/where_help.txt')
  OPTIONS = {
    description: ':mag_right: Find out where another use is.',
    usage: '`&where` username#1234'
  }

  def self.call(event, *args)
    username = args[0]
    members = event.channel.server.members
    if members.collect(&:distinct).include?(username)
      queried_user = members.select{|m| m.distinct == username }[0]

      schedule = get_schedule(username)
      tz = schedule.timezone
      events = schedule.events

      if events.none?{|e| e.on?(tz) }
        output_string = "#{username} doesn't have anything scheduled right now."
        if queried_user.game
          output_string << "\n:video_game: They are playing #{queried_user.game}"
        else
          output_string << "\nThey are currently #{queried_user.status}."
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
      event << ":scream: #{username} is not on this server. `where` uses the distinct user ID, e.g. User#1234."
    end

    return nil

  end
end
