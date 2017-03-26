require 'time'
require 'securerandom'
require 'json'
require_relative 'timezone'
require 'tzinfo'

class Schedule


  class Event
    include Comparable

    attr_reader :from, :to, :activity, :id
    attr_accessor :where_string

    def initialize(from, to, activity, id=nil)
      raise ArgumentError, "#{from.class} or #{to.class} can't be coerced into Time object" if !(Time === from) || !(Time === to)
      @from = from
      @to = to
      @activity = activity
      @id = id || SecureRandom.hex
    end

    def on?(timezone="UTC")
      Time.now > @from && Time.now < @to ? true : false
    end

    def to_s
      "#{@activity.capitalize} from #{@from} to #{@to}"
    end

    def print_tz(timezone)
      "#{@activity.capitalize} from #{@from} to #{@to}"
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

    def self.change_timezone(time, timezone)
      puts time
      t = time.getutc
      puts t
      puts Time.parse(t.strftime("%c") + ' ' + Event.get_offset(timezone))
      Time.parse(t.strftime("%c") + ' ' + Event.get_offset(timezone))
    end

    def self.get_offset(city)
      tz_period = TZInfo::Timezone.get(city).current_period
      offset = tz_period.utc_offset
      # Offset in seconds, accounting for daylight savings
      offset += tz_period.std_offset if tz_period.dst?
      return "#{"++ "[offset <=> 0]}#{(offset / 3600).to_s.rjust(2, '0')}:#{((offset%3600)/60).to_s.rjust(2, '0')}"
    end

  end


end
