require 'json'
require_relative 'weekly_event'

class Schedule

  class Preset

    attr_reader :name, :activity, :events

    def initialize(name, activity, *events)
      @name = name
      @activity = activity
      raise ArgumentError, 'array of events contains an object(s) that is not of type AbstractWeeklyEvent' unless events.all? {|e| AbstractWeeklyEvent === e }
      @events = events
    end

    def add_event(event)
      raise ArgumentError, "#{event.class} cannot be coerced into type AbstractWeeklyEvent" unless AbstractWeeklyEvent === event
      @events << event
    end

    def write(path)
      serialised_data = { name: @name, events: @events.collect {|e| { from: e.from.to_s, to: e.to.to_s } }, activity: @activity }

      File.open(path, 'w') do |f|
        f.write(serialised_data.to_json)
      end
    end

    def self.load(path)
      data = JSON.parse(File.read(path))
      loaded_preset = Preset.new(data['name'], data['activity'])
      data['events'].each do |event|
        loaded_preset.add_event(AbstractWeeklyEvent.new(new_abstract_week_time(*event['from'].split), new_abstract_week_time(*event['to'].split)))
      end

      return loaded_preset

    end

    # Event that stores just the times, without timezone and optional activity
    class AbstractWeeklyEvent

      attr_reader :from, :to, :activity

      def initialize(from, to, activity=nil)
        @from = from
        @to = to
        @activity = activity
      end

      def to_weekly_event(timezone, activity = @activity)
        return WeeklyEvent.new(from.to_week_time(timezone), to.to_week_time(timezone), activity)
      end

      AbstractWeekTime = Struct.new(:day, :time) do
        def initialize(day, time)
          @day = day
          @time = time
        end

        def to_week_time(timezone)
          return WeekTime.parse("#{@day} #{@time} #{timezone}")
        end

        def to_s
          return "#{@day} #{@time}"
        end
      end

    end

    # Helper method to reduce namespacing
    def self.new_abstract_week_time(*args)
      return AbstractWeeklyEvent::AbstractWeekTime.new(*args)
    end

  end

end
