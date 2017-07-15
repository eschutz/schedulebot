require 'securerandom'
require_relative 'week_time'

class Schedule

  class WeeklyEvent
    include Comparable

    attr_reader :from, :to, :activity, :id
    attr_accessor :where_string

    def initialize(from, to, activity, id=nil)
      raise ArgumentError, "#{from.class} or #{to.class} can't be coerced into WeekTime object" if !(WeekTime === from) || !(WeekTime === to)
      @from = from.in_time_zone("UTC")
      @to = to.in_time_zone("UTC")
      @activity = activity
      raise ArgumentError, "activity length exceeds max length of #{Event::MAX_ACTIVITY_LENGTH}" if @activity.length > Event::MAX_ACTIVITY_LENGTH
      @id = id || SecureRandom.hex[0..5] # ID is first five characters of generated hash
    end

    def on?(timezone="UTC")
      from = @from.in_time_zone(timezone)
      to = @to.in_time_zone(timezone)
      now = WeekTime.now.in_time_zone(timezone)
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
      "**#{@activity.capitalize}** from __#{@from.in_time_zone(timezone).to_s.gsub(/:\d\d [+-]\d{4}/, '')}__ to __#{@to.in_time_zone(timezone).to_s.gsub(/:\d\d [+-]\d{4}/, '')}__"
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

    def self.deserialise(data) # data is a hash containing Type, StartingTime, FinishingTime, Activity, ID
      raise ArgumentError, "invalid event data array: #{data}" unless data.length == 5

      return WeeklyEvent.new(WeekTime.parse(data['startingtime']), WeekTime.parse(data['finishingtime']), data['activity'], data['id'])

      # Old method
      # json = data.values.first
      # return WeeklyEvent.new(WeekTime.parse(json["from"]), WeekTime.parse(json["to"]), json["activity"], data.keys[0])
    end

  end

end
