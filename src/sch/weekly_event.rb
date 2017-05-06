require 'securerandom'
require_relative 'week.rb'

class Schedule

  class WeeklyEvent
    include Comparable

    attr_reader :from, :to, :activity, :id
    attr_accessor :where_string

    def initialize(from, to, activity, id=nil)
      raise ArgumentError, "#{from.class} or #{to.class} can't be coerced into Week object" if !(Week === from) || !(Week === to)
      @from = from.in_time_zone("UTC")
      @to = to.in_time_zone("UTC")
      @activity = activity
      @id = id || SecureRandom.hex
    end

    def on?(timezone="UTC")
      puts timezone
      from = @from.in_time_zone(timezone)
      to = @to.in_time_zone(timezone)
      now = Week.now.in_time_zone(timezone)
      # Check to see if it crosses the week boundary (Saturday (6th day of the week) - Sunday (0th day of the week))
      if from > to
        if now >= from || now <= to
          return true
        end
        return false
      end

      return now >= from && now <= to ? true : false
    end

    def to_s
      "#{@activity.capitalize} from #{@from} to #{@to}"
    end

    def print_tz(timezone)
      "**#{@activity.capitalize}** from __#{@from.in_time_zone(timezone)}__ to __#{@to.in_time_zone(timezone)}__"
    end

    def <=>(obj)
      return nil if !(WeeklyEvent === obj)
      return @from <=> obj.from
    end

    def serialise
      return {
        @id.to_sym => {
          type: "WeeklyEvent",
          from: @from,
          to: @to,
          activity: @activity
        }
      }
    end

    def self.deserialise(data)
      json = data.values.first
      return WeeklyEvent.new(Week.parse(json["from"]), Week.parse(json["to"]), json["activity"], data.keys[0])
    end

  end

end
