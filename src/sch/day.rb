class Schedule
  class Day
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

    attr_reader :wday, :start, :end, :activity

  end
end


__END__




    # Create a new Dat object with integers weekday, start time, and finish time
    def initialize(day, st, en, activity = '')
      raise InvalidTimeException, "#{st} is not a valid time within a day, must be in minutes (0..1439)" if !(0..1439).include?(st)
      raise InvalidTimeException, "#{en} is not a valid time within a day, must be in minutes (0..1439)" if !(0..1439).include?(en)

      @wday = day
      @start = st
      @end = en
      @hour = st.split(':')[0]
      @minute = en.split(':')[1]
      @activity = activity
    end

    # Compare two days, returns true if the the given day is within the recipient object
    def within(local_day)
      day = local_day
      day.utc
      raise ArgumentError, "cannot compare #{day.class} with #{self.class}" if !(day) === Day
      if Time.new(Time.now.year, Time.now.mon, @wday)#day.wday == @wday && day.start >= @start && day.end <= @end
        return true
      end

      return false
    end

    # Extract the day from two time objects
    # Day.from_time ignores the weekday of the second time, it will still range between the times on each day
    def self.from_time(time1, time2, activity = '')
      # Get the time within a day as minutes (0..1439)
      # Add the timezone value
      # timezone = timezone.split(':')
      # hour = timezone[0].to_i
      # Gets the offset in minutes. In "+hh:mm" it is the sum of hh * 60 and mm * 60
      # The statement `('++-'[hour <=> 0] + timezone[1]).to_i` gets the sign of hh as a string,
      # concatenates it to the mm string, then converts it to an integer
      # offset = hour * 60 + ('++-'[hour <=> 0] + timezone[1]).to_i
      t1 = time1.hour * 60 + time1.min
      t2 = time2.hour * 60 + time2.min

      # Raise an exception if the times are impossible
      raise InvalidTimeException, "invalid time: #{time1.strftime("%H:%M")} is after #{time2.strftime("%H:%M")}" if t1 > t2
      return Day.new(time1.wday, t1, t2, activity)
    end

    def to_s
      "#{@activity.capitalize} from #{READABLE[@wday]} #{(@start/60).to_s.rjust(2, '0')}:#{(@start - (@start/60) * 60).to_s.rjust(2, '0')} to #{(@end/60).to_s.rjust(2, '0')}:#{(@end - (@end/60 * 60)).to_s.rjust(2, '0')}"
    end

  end
  #
  # Preset = Struct.new(:st, :en, :days, :activity) do
  #   def get_preset(timezone)
  #     puts st, en
  #     @st = st.split(':')
  #     @en = en.split(':')
  #     days = days || (0..6)
  #     days.collect do |wday|
  #       # January 4, 1970, a Sunday
  #       Day.from_time(Time.new(1970, 1, 4 + wday, @st[0], @st[1], 0, timezone), Time.new(1970, 1,  4 + wday, @en[0], @en[1], 0, timezone), activity)
  #     end
  #   end
  # end
  #
  # PRESET_OFFICE = Preset.new('9', '17', (1..5), "at work") # 9 to 5 weekday office preset
  #
  # PRESET_SCHOOL = Preset.new('8:30', '16', (1..5), "at school")
  #
  # PRESETS = {school: PRESET_SCHOOL, office: PRESET_OFFICE}

end
