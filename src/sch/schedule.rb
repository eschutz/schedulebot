require_relative 'event'
require_relative 'weekly_event'

class Schedule

  attr_reader :user, :events
  attr_accessor :timezone

  def initialize(user, *events)
    @timezone = "UTC"
    if Schedule === user
      @user = user.user
      @events = user.events.dup
    else
      @user = user
      raise ArgumentError, 'Schedule constructor takes only Event objects' if !(events.all? {|e| Event === e || WeeklyEvent === e})
      @events = events.clone.sort {|e1, e2| e1.from.to_i <=> e2.from.to_i }
    end
  end

  def add_event(event)
    @events << event
  end

  def remove_event(id)
    @events.delete_if {|e| e.id == id}
  end

  # Save a schedule to file
  def write(path)
    File.open(path, 'w') do |f|
      f.puts(
        {
          user: @user,
          events: @events.collect{|e| e.serialise},
          timezone: @timezone
        }.to_json
      )
    end
  end

  alias_method :<<, :add_event

  # Load a schedule from file
  def self.load_schedule(path)
    file = File.read(path)
    return false if file.strip.length == 0
    sch_data = JSON.parse(file)
    events = sch_data["events"].collect do |event|
      Schedule.const_get(event.values.first['type']).deserialise(event)
    end

    sch = Schedule.new(sch_data["user"], *events)
    sch.timezone = sch_data["timezone"]
    return sch
  end

  def to_s
    col1 = "**#{Time.now} – #{Time.now}**"
    "```\nDate #{"\s" * 35} Activity\n\n" + @events.collect {|e|"#{format_event(e.from.in_time_zone(@timezone))} – #{format_event(e.to.in_time_zone(@timezone))}        #{e.activity}" }.join("\n\n") + "\n\n\n(All times are displayed in #{@timezone} time.)\n```"
  end

  def inspect
    col1 = "**#{Time.now} – #{Time.now}**"
    "```\nDate #{"\s" * 35} Activity            Event ID\n\n" + @events.collect{ |e| "#{format_event(e.from.in_time_zone(@timezone))} – #{format_event(e.to.in_time_zone(@timezone))}       #{e.activity}   <#{e.id}>" }.join("\n\n") + "\n\n\n(All times are displayed in #{@timezone} time.)\n```"
  end

  private

  def format_event(event)
    if Time === event
      return event.strftime("%-d–%-m–%y %H:%M")
    elsif Week === event
      return event.to_s
    end
  end

end
