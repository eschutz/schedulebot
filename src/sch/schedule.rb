require_relative 'event'
require_relative 'weekly_event'
require_relative 'preset'
require_relative 'offset'
require_relative '../comm/emote'
require_relative '../schedule_formatter'


class Schedule

  attr_reader :user, :events, :enabled_presets
  attr_accessor :timezone

  def initialize(user, *events)
    @timezone = "UTC"
    @enabled_presets = Array.new
    @en_presets_set = false
    if Schedule === user
      @user = user.user
      @events = user.events.dup
    else
      @user = user
      raise ArgumentError, 'Schedule constructor takes only Event objects' if !(events.all? {|e| Event === e || WeeklyEvent === e} )
      @events = events.clone.sort {|e1, e2| e1.from.to_i <=> e2.from.to_i }
    end
  end

  def add_event(event)
    @events << event
  end

  def add_preset(preset)
    raise ArgumentError, "#{preset.class} cannot be coerced into type Preset" unless Preset === preset

    preset.events.each do |event|
      add_event(event.to_weekly_event(@timezone, preset.activity))
    end

    @enabled_presets << preset.name.to_sym
  end

  def remove_preset(preset)
    raise ArgumentError, "#{preset.class} cannot be coerced into type Preset" unless Preset === preset

    @events.select {|e| e.activity == preset.activity }.each do |preset_event|
      remove_event(preset_event.id)
    end
    @enabled_presets.delete(preset.name)

  end

  def remove_event(id)
    @events.delete_if {|e| e.id == id}
  end

  # For deserialisation
  def set_enabled_presets(en_presets)
    raise ArgumentError, "#{en_presets.class} cannot be coerced into type Array" if !(Array === en_presets)
    raise ArgumentError, "invalid array contents: enabled presets can only contain Symbols or Strings" if !(en_presets.all? {|ep| Symbol === ep || String === ep })

    @enabled_presets = en_presets.collect(&:to_sym)
    @en_presets_set = true
  end

  # Save a schedule to file
  def write(path)
    FileUtils::mkdir_p(File.dirname(path))
    File.open(path, 'w') do |f|
      f.write(
        {
          user: @user,
          events: @events.collect{|e| e.serialise},
          timezone: @timezone,
          enabled_presets: @enabled_presets
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
    sch.set_enabled_presets(sch_data["enabled_presets"])
    return sch
  end

  def to_s
    ScheduleFormatter.new(self).format_table
  end

  alias_method :inspect, :to_s

  def to_embed(include_id = false)
    ScheduleFormatter.new(self).get_embed_from_schedule(include_id)
  end

end
