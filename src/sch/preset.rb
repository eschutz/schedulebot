require 'json'
require 'struct'
require_relative 'weekly_event'

class Schedule

  class Preset

    def initialize(activity, *events)
      @activity = activity
      @events = events
    end

    def add_event(event)
      @events << event
    end

    def write(path)
      serial_data = { events: Array.new, activity: @activity }

      @events.each do |event|
        serial_data[:events].push({
          from: event.from,
          to: event.to
        })
      end

      File.open(path, 'w') do |f|
        f.write(serial_data.to_json)
      end
    end

    def self.load(path)
      data = JSON.parse(File.read(path))
      loaded_preset = Preset.new(data['activity'])
      data['events'].each do |event|
        loaded_preset.add_event(WeeklyEvent.new(Week.parse(event['from']), Week.parse(event['to']), data['activity']))
      end

      return loaded_preset

    end

    # Event that stores just the times, without timezone
    class AbstractWeeklyEvent

      attr_reader :from, :to

      AbstractWeek = Struct.new(:)

    end

  end

end
