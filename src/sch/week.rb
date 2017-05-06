require 'active_support/core_ext/time'
require_relative 'timezone'

class Schedule

  class Week
    include Comparable

    # Although these values are obvious, naming them is useful for metaprogramming
    # See Week#to_i
    SECONDS_IN_DAY = 24 * 60 * 60
    SECONDS_IN_HOUR = 60 * 60
    SECONDS_IN_MINUTE = 60
    SECONDS_IN_SECOND = 1

    SUN = 0
    MON = 1
    TUE = 2
    WED = 3
    THU = 4
    FRI = 5
    SAT = 6

    READABLE = {  SUN => 'Sunday',
                  MON => 'Monday',
                  TUE => 'Tuesday',
                  WED => 'Wednesday',
                  THU => 'Thursday',
                  FRI => 'Friday',
                  SAT => 'Saturday'
                }
    NUMERIC = READABLE.invert

    DAY_ABBREVIATIONS = Week::READABLE.values.collect(&:upcase) + ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']

    ABBREV_TO_COMPLETE = { "SUN" => "Sunday",
                           "MON" => "Monday",
                           "TUE" => "Tuesday",
                           "WED" => "Wednesday",
                           "THU" => "Thursday",
                           "FRI" => "Friday",
                           "SAT" => "Saturday"
                         }

    TIMEZONE_ABBREVIATION_NAMES = Hash[ActiveSupport::TimeZone.all.sort.collect{|t| t.now.zone}.zip(ActiveSupport::TimeZone.all.sort.collect(&:name))]

    attr_reader :day, :hour, :minute, :second, :timezone

    def initialize(*args)
      if args.length >= 2
        @day = args[0].to_i % 7
        @hour = args[1].to_i % 24
        @minute = args[2].to_i % 60
        @second = args[3].to_i % 60
        if TIMEZONE_ABBREVIATION_NAMES.include?(args[4]) || args[4].to_s.match?(/^[+|-]\d\d\d\d$/) # Matches ±hh:mm timezone offset string
          @timezone = args[4]
        else
          args[4] = "UTC"
        end
      elsif args.length == 0
        time = Time.now
        @day = time.wday
        @hour = time.hour
        @minute = time.min
        @second = time.sec
        @timezone = time.zone
      else
        raise ArgumentError, "Not enough arguments for Week object."
      end
    end

    def self.now
      self.new
    end

    # Works the same way as Time#in_time_zone
    def in_time_zone(tz)

      tz_offset = Offset.new(Time.now.in_time_zone(tz))
      utc_offset = Offset.new(Time.now.in_time_zone(TIMEZONE_ABBREVIATION_NAMES[@timezone]), true)

      offset = utc_offset
      minute = @minute
      hour = @hour
      day = @day

      # This loop firstly changes the minute, hour, and day values to UTC,
      # then changes them from UTC to the timezone in tz

      2.times do

        minute += offset.minute
        # Check if the minute value is impossible, i.e. less than 0 or more than 59
        # If so tick increment or decrement the hour value
        if minute < 0
          hour -= 1
          minute = 60 - (-minute)
        elsif minute >= 60
          hour += 1
          minute = minute - 60
        end

        hour += offset.hour

        if hour < 0
          day -= 1
          hour = 24 - (-hour)
        elsif hour >= 24
          day += 1
          hour = hour - 24
        end

        offset = tz_offset
      end

      return Week.new(day, hour, minute, second, offset.to_s)
    end

    def to_i
      week_i = 0
      ["day", "hour", "minute", "second"].each do |time|
        week_i += instance_variable_get('@' + time) * self.class.const_get("SECONDS_IN_#{time.upcase}")
      end
      return week_i
    end

    def to_s
      return "#{READABLE[@day]} #{@hour.to_s.rjust(2, '0')}:#{@minute.to_s.rjust(2, '0')}:#{@second.to_s.rjust(2, '0')} #{@timezone}"
    end

    def inspect
      to_s
    end

    def <=>(other_week)
      return to_i <=> other_week.to_i
    end

    def self.parse(string)
      args = string.split

      parse_result = catch :unable_to_parse do
        if DAY_ABBREVIATIONS.include?(args[0].upcase)
          if args[0].length == 3
            day = NUMERIC[ABBREV_TO_COMPLETE[args[0].upcase]]
          else
            day = NUMERIC[args[0].capitalize]
          end
        else
          throw :unable_to_parse, :err
        end

        time = [0, 0, 0]

        if args[1].match?(/^\d\d?(:\d\d)?(:\d\d)?$/) # Matches hh:mm:ss time format string
          t = args[1].split(':').collect(&:to_i)

          # Checks if the times are valid, e.g. not negative numbers, hour not above 23 etc.
          if t.any?{|n| n < 0 } || t[0] > 23 || (t[1] && t[1] > 59) || (t[2] && t[2] > 59)
            throw :unable_to_parse, :err
          end

          t.each_with_index do |n, index| # Replaces [0, 0, 0] with each value present in t
            time[index] = n               # e.g.  [0,  0, 0]
          end                             #     + [1, 12]    = [1, 12, 0]

        elsif args[1].match?(/^\d\d?[ap]m$/) # Matches to hham or hhpm, e.g. 10am, 3pm etc.
          t = args[1].to_i # Extracts the number from the am or pm expression
          if t > 12 || t < 0
            throw :unable_to_parse, :err
          end

          if args[1][-2] == 'p' # 'a' or 'p' (in am and pm)
            unless t == 12
              t += 12 # if pm add 12 hours
            end
          else
            if t == 12
              t = 0
            end
          end

          time[0] = t

        else
          throw :unable_to_parse, :err
        end

        if TIMEZONE_ABBREVIATION_NAMES.include?(args[2])
          tz = args[2]
        else
          throw :unable_to_parse, :err
        end

        [day, time, tz]

      end

      unless parse_result == :err
        return Week.new(parse_result[0], *parse_result[1], parse_result[2])
      else
        raise ArgumentError, "invalid time format: unable to parse"
      end

    end

    private

    class Offset

      def initialize(time, negative = false)
        offset = time.to_s.split.last # Will return a value like +1030, -0200
        @sign = offset[0]

        if negative
          if @sign == '-'
            @sign = '+'
          elsif @sign == '+'
            @sign = '-'
          end
        end

        @hour = offset[1..2]
        @minute = offset[3..4]
      end

      # Return the offsets with the signs included
      def hour
        return "#{@sign}#{@hour}".to_i
      end

      def minute
        return "#{@sign}#{@minute}".to_i
      end

      def to_s
        return "#{@sign}#{@hour}#{@minute}"
      end

    end

  end

end

class Time
  def week
    return Schedule::Week.new(wday, hour, min, sec, zone)
  end
end
