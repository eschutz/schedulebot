require_relative 'event'

class Schedule

  attr_reader :user, :events
  attr_accessor :timezone

  def initialize(user, *events)
    #@timezone = "UTC"
    if Schedule === user
      @user = user.user
      @events = user.events.dup
    else
      @user = user
      raise ArgumentError, 'Schedule constructor takes only Event objects' if !(events.all? {|e| Event === e})
      @events = events.clone.sort
    end
  end

  def add_event(event)
    @events << event
  end

  def remove_event(id)
    @events.delete_if {|e| e.id == id}
  end

  # Save a schedule to file
  def save(path)
    File.open(path, 'w') do |f|
      f.puts(
        {
          user: @user,
          events: @events.collect{|e| e.serialise}
          #timezone: @timezone
        }.to_json
      )
    end
  end

  # Load a schedule from file
  def self.load_schedule(path)
    file = File.read(path)
    return false if file.strip.length == 0
    sch_data = JSON.parse(file)
    sch = Schedule.new(sch_data["user"], *sch_data["events"].collect {|e| Event.deserialise(JSON.parse(e))})
    #sch.timezone = sch_data["timezone"]
    return sch
  end

  def to_s
    col1 = "**#{Time.now} – #{Time.now}**"
    "```\nDate #{"\s" * 35} Activity\n\n" + @events.collect{ |e| "#{e.from.strftime("%-d–%-m–%y %H:%M")} – #{e.to.strftime("%-d–%-m–%y %H:%M %Z")}        #{e.activity}" }.join("\n\n") + "\n```"
  end

  def inspect
    col1 = "**#{Time.now} – #{Time.now}**"
    "```\nDate #{"\s" * 35} Activity            Event ID\n\n" + @events.collect{ |e| "#{e.from.strftime("%-d–%-m–%y %H:%M")} – #{e.to.strftime("%-d–%-m–%y %H:%M %Z")}       #{e.activity}   <#{e.id}>" }.join("\n\n") + "\n```"
  end

end

__END__
  attr_reader :weekly,

  def initialize(sch_object)
    case sch_object
    when Weekly
      @weekly = true
    end
  end

  def self.weekly(t1, t2)
    sch = Schedule.new
    sch.weekly = true
    sch.start_day = t1.wday
    sch.start_time = t1.gmtime
    sch.finish_day = t2.wday
    sch.finish_time = t2.gmtime
  end

  class Weekly < Struct.new(:weekly, :start_day, :start_time, :finish_day, :finish_time)
  end

  class InvalidTimeException < Exception
  end

end
