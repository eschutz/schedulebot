class Schedule
  
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
