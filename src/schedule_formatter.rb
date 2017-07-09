require 'discordrb'
require_relative 'comm/emote'
require_relative 'sch/event'
require_relative 'sch/week_time'

class ScheduleFormatter

  DEFAULT_EVENT_COLUMN_WIDTH = 51 # Number of characters in a left (event) column
  DEFAULT_ACTIVITY_COLUMN_WIDTH = 25 # Number of characters in a right (activity) column
  DEFAULT_SEPARATOR_WIDTH = 2 # Number of single whitespace characters (spaces) between columns
  DEFAULT_LINE_SPACING = 1 # Number of newlines between rows

  DEFAULT_EMBED_COLOUR = 0xff0000 # Colour of the side bar in embeds

  MAX_EMBED_FIELD_VALUE_LENGTH = 1024

  attr_accessor :column_width
  attr_reader :separator_width, :line_spacing

  def initialize(schedule, options = { col_width: nil, sep_width: nil, line_spacing: nil })
    @schedule = schedule
    @event_column_width = options[:e_col_width] || DEFAULT_EVENT_COLUMN_WIDTH
    @activity_column_width = options[:a_col_width] || DEFAULT_ACTIVITY_COLUMN_WIDTH
    @separator_width = options[:sep_width] || DEFAULT_SEPARATOR_WIDTH
    @separator = ' ' * @separator_width
    @line_spacing = options[:line_spacing] || DEFAULT_LINE_SPACING
    @newline = "\n" + "\n" * @line_spacing
  end

  def separator_width=(width)
    @separator_width = width
    @separator = ' ' * @separator_width
  end

  def line_spacing=(ls)
    @line_spacing = ls
    @newline = "\n" + "\n" * @line_spacing
  end

  def get_embed_from_schedule(include_id = false)
    embed = Discordrb::Webhooks::Embed.new
    embed.colour = DEFAULT_EMBED_COLOUR
    embed.title = "#{@schedule.user}'s Schedule"
    embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "All times are displayed in #{@schedule.timezone} time.")

    events_list = ['']
    id_list = ['']
    array_split = 0
    @schedule.events.each do |event|
      if (events_list[array_split].length + Schedule::Event::MAX_STRING_LENGTH) > MAX_EMBED_FIELD_VALUE_LENGTH
        array_split += 1
        events_list[array_split] = ''
        id_list[array_split] = ''
      end
      events_list[array_split] << "\n#{event.print_tz(@schedule.timezone)}"
      id_list[array_split] << "\n**#{event.activity.capitalize}:** __#{event.id}__"
    end

    events_list.each_with_index do |list, index|
      events_title = events_list.length > 1 ? "Events – Section #{index + 1}" : "Events"
      embed.add_field(name: events_title, value: list)

      if include_id
        id_title = id_list.length > 1 ? "ID – Section #{index + 1}" : "ID"
        embed.add_field(name: id_title, value: id_list[index])
      end
    end

    return embed

  end

  # Old formatting method
  def format_table(include_id = false)

    date_string = "Date".center(@event_column_width)
    activity_string = "Activity".center(@activity_column_width)
    id_string = "Event ID".center(@activity_column_width)

    formatted_events = @schedule.events.collect do |e|
      fmt_from = ScheduleFormatter::format_event(e.from.in_time_zone(@schedule.timezone))
      fmt_to = ScheduleFormatter::format_event(e.to.in_time_zone(@schedule.timezone))
      fmt_event_string = "#{fmt_from} – #{fmt_to}".center(@event_column_width)

      fmt_activity = Emote::remove_emotes(e.activity).center(@activity_column_width)
      fmt_activity = fmt_activity[0...(@activity_column_width - 3)] + '...' if fmt_activity.length > @activity_column_width

      fmt_id = "<#{e.id}>".center(@activity_column_width)

      "#{fmt_event_string}#{@separator}#{fmt_activity}#{(@separator + fmt_id) if include_id}"

    end.join(@newline)

    return <<~HEREDOC
    ```
    #{date_string}#{@separator}#{activity_string}#{(@separator + id_string) if include_id}
    #{@newline}
    #{formatted_events}


    (All times are displayed in #{@schedule.timezone} time.)
    ```
    HEREDOC
  end

  def show_single_event(id)
    event = @schedule.events.select{|e| e.id == id }[0]
    raise ArgumentError, 'no event with that ID in schedule' if event == nil
    return "#{ScheduleFormatter::format_event(event)}#{@separator}#{event.activity}#{@separator}#{event.id}"
  end

  def self.format_event(event)
    if Time === event
      return event.strftime("%-d–%-m–%y %H:%M")
    elsif Schedule::WeekTime === event
      return event.to_s
    end
  end

end
