require 'time'
require 'securerandom'
require 'json'
require_relative 'timezone'
require 'active_support/core_ext/time'

class Schedule

  class Event
    include Comparable

    MAX_ACTIVITY_LENGTH = 100
    MAX_TIME_LENGTH = 60
    MARKDOWN_LENGTH = 12
    MAX_STRING_LENGTH = MAX_ACTIVITY_LENGTH + MAX_TIME_LENGTH + MARKDOWN_LENGTH

    attr_reader :from, :to, :activity, :id
    attr_accessor :where_string

    def initialize(from, to, activity, id=nil)
      raise ArgumentError, "#{from.class} or #{to.class} can't be coerced into Time object" if !(Time === from) || !(Time === to)
      @from = from.getutc
      @to = to.getutc
      @activity = activity
      raise ArgumentError, "activity length exceeds max length of #{MAX_ACTIVITY_LENGTH}" if @activity.length > MAX_ACTIVITY_LENGTH
      @id = id || SecureRandom.hex[0..5] # ID is first five characters of generated hash
    end

    def on?(timezone="UTC")
      Time.now.in_time_zone(timezone) >= @from && Time.now.in_time_zone(timezone) <= @to ? true : false
    end

    def to_s
      "#{@activity.capitalize} from #{@from} to #{@to}"
    end

    def print_tz(timezone)
      "**#{@activity.capitalize}** from __#{@from.in_time_zone(timezone).to_s.gsub(/:\d\d [+-]\d{4}/, '')}__ to __#{@to.in_time_zone(timezone).to_s.gsub(/:\d\d [+-]\d{4}/, '')}__"
    end

    def <=>(obj)
      return nil if !(Event === obj)
      return @from <=> obj.from
    end

    def serialise
      return {
        @id.to_sym => {
          type: "Event",
          from: @from,
          to: @to,
          activity: @activity
        }
      }
    end

    def self.deserialise(data)
      json = data.values.first
      return Event.new(Time.parse(json["from"]), Time.parse(json["to"]), json["activity"], data.keys[0])
    end

    def self.get_timezone(city)
      tz_period = TimeZone::TIMEZONES[city]
    end

  end

end
