# require 'fileutils' -> old dependency
require 'colorize'
require_relative 'event'
require_relative 'weekly_event'
require_relative 'preset'
require_relative 'offset'
require_relative '../comm/emote'
require_relative '../schedule_formatter'

# PostgreSQL Statement Preparations

if $postgres
  # Schedule#remove_event
  $postgres.prepare('remove_event', 'delete from UserEvents.Events where ID=$1')

  # Schedule#write
  $postgres.prepare('check_exists', 'select exists(select 1 from UserEvents.Events where ID=$1)')
  $postgres.prepare('insert_event', 'insert into UserEvents.Events ("User", Type, StartingTime, FinishingTime, Activity, ID) values ($1, $2, $3, $4, $5, $6)')

  # Schedule#clear
  $postgres.prepare('clear_events', 'delete from UserEvents.Events where "User"=$1')

  # Schedule#load_schedule
  $postgres.prepare('load_schedule', 'select Type, StartingTime, FinishingTime, Activity, ID from UserEvents.Events where "User"=$1')
  $postgres.prepare('get_timezone', 'select Timezone, EnabledPresets from UserEvents.UserData where UserDistinct=$1')
else
  puts "WARNING: No global postgres PG::Connection object available! Schedule#remove_event, Schedule#write, Schedule#clear, and Schedule#load_schedule will raise errors.".red
  puts "If in REPL, please initialise a $postgres PG::Connection object and then run `load 'path/to/schedule.rb'.`".yellow
end


class Schedule

  attr_reader :user, :events, :enabled_presets, :timezone

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

  alias_method :<<, :add_event

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
    $postgres.exec_prepared('remove_event', [id])
  end

  def timezone=(tz)
    @timezone = tz
    # Instead of using a prepared statement here, I had to instead
    # use PG::Connection#escape_string and string interpolation,
    # as PG uses the dollar sign ($) for interpolation of
    # variables ($1, $2, etc.) in a prepared query.
    # This means that 'do $$' made it ignore all subsequent
    # dollar signs, warranting this solution.
    $postgres.exec(
      <<~HEREDOC
      do $$
        begin
          if exists (select 1 from UserEvents.UserData where UserDistinct='#{$postgres.escape_string(@user)}') then
            update UserEvents.UserData set timezone='#{$postgres.escape_string(tz)}' where UserDistinct='#{$postgres.escape_string(@user)}';
          else
            insert into UserEvents.UserData (UserDistinct, Timezone) values ('#{$postgres.escape_string(@user)}', '#{$postgres.escape_string(tz)}');
          end if;
        end
      $$
      HEREDOC
    )

  end

  # For deserialisation
  def set_enabled_presets(en_presets)
    raise ArgumentError, "#{en_presets.class} cannot be coerced into type Array" if !(Array === en_presets)
    raise ArgumentError, "invalid array contents: enabled presets can only contain Symbols or Strings" if !(en_presets.all? {|ep| Symbol === ep || String === ep })

    @enabled_presets = en_presets.collect(&:to_sym)
    @en_presets_set = true
  end

  def write
    @events.each do |event|
      if $postgres.exec_prepared('check_exists', [event.id]).values.flatten.first == 'f' # Query returns [['t']] or [['f']]
        $postgres.exec_prepared('insert_event', [@user, event.class.name.split('::').last, event.from.to_s, event.to.to_s, event.activity, event.id])
      end
    end
  end

  def clear
    $postgres.exec_prepared('clear_events', [@user])
  end

  def self.load_schedule(user_distinct)
    events = $postgres.exec_prepared('load_schedule', [user_distinct])
    schedule_data = $postgres.exec_prepared('get_timezone', [user_distinct]).values.flatten

    schedule_events = events.collect do |event_data|
      # Omits the type when passing to the event constructor
      Schedule.const_get(event_data['type']).deserialise(event_data)
    end

    schedule = Schedule.new(user_distinct, *schedule_events)
    schedule.timezone = schedule_data[0]
    # Send loaded data or empty array
    schedule.set_enabled_presets(schedule_data[1] || Array.new)

    # Clearing all query (Result) objects for memory
    events.clear
    schedule_data.clear

    return schedule

  end

  # -- Old methods - no database, only json files --
  # Save a schedule to file
  # def write(path)
  #   FileUtils::mkdir_p(File.dirname(path))
  #   File.open(path, 'w') do |f|
  #     f.write(
  #       {
  #         user: @user,
  #         events: @events.collect{|e| e.serialise},
  #         timezone: @timezone,
  #         enabled_presets: @enabled_presets
  #       }.to_json
  #     )
  #   end
  # end
  #
  # # Load a schedule from file
  # def self.load_schedule(path)
  #   file = File.read(path)
  #   return false if file.strip.length == 0
  #   sch_data = JSON.parse(file)
  #   events = sch_data["events"].collect do |event|
  #     Schedule.const_get(event.values.first['type']).deserialise(event)
  #   end
  #
  #   sch = Schedule.new(sch_data["user"], *events)
  #   sch.timezone = sch_data["timezone"]
  #   sch.set_enabled_presets(sch_data["enabled_presets"])
  #   return sch
  # end

  def to_s
    ScheduleFormatter.new(self).format_table
  end

  alias_method :inspect, :to_s

  def to_embed(include_id = false)
    ScheduleFormatter.new(self).get_embed_from_schedule(include_id)
  end

end
