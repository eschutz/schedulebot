require 'time'
require 'securerandom'
require 'json'
require_relative 'timezone'
require 'active_support/core_ext/time'

class Schedule


  class Event
    include Comparable

    attr_reader :from, :to, :activity, :id
    attr_accessor :where_string

    def initialize(from, to, activity, id=nil)
      raise ArgumentError, "#{from.class} or #{to.class} can't be coerced into Time object" if !(Time === from) || !(Time === to)
      @from = from.getutc
      @to = to.getutc
      @activity = activity
      @id = id || SecureRandom.hex
    end

    def on?(timezone="UTC")
      Time.now.in_time_zone(timezone) > @from && Time.now.in_time_zone(timezone) < @to ? true : false
    end

    def to_s
      "#{@activity.capitalize} from #{@from} to #{@to}"
    end

    def print_tz(timezone)
      "**#{@activity.capitalize}** from __#{@from.in_time_zone(timezone)}__ to __#{@to.in_time_zone(timezone)}__"
    end

    def <=>(obj)
      return nil if !(Event === obj)
      return @from <=> obj.from
    end

    def serialise
      return {
        @id.to_sym => {
          from: @from,
          to: @to,
          activity: @activity
        }
      }.to_json
    end

    def self.deserialise(data)
      json = data[data.keys[0]]
      return Event.new(Time.parse(json["from"]), Time.parse(json["to"]), json["activity"], data.keys[0])
    end

    def self.get_timezone(city)
      tz_period = TimeZone::TIMEZONES[city]
    end

  end


end
