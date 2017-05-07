require 'colorize'
require_relative 'src/sch/schedule.rb'

puts '* Preset Creator *'.bold.blue
print 'Daily Starting Time (24 Hour Time, hh:mm): '
start_time = gets.chomp
print 'Daily Finishing Time (24 Hour Time, hh:mm): '
finish_time = gets.chomp
print 'Weekends? (y/n): '
weekends = gets.chomp.upcase == 'Y' ? true : false

serial_data = Preset.new

Schedule::Week::READABLE.values.each do |day|
    next if !weekends && (day == 'Saturday' || day == 'Sunday')

    Schedule::Preset.add_event(Schedule::WeeklyEvent.parse("#{day} #{start_time}"), Schedule::WeeklyEvent.parse("#{day} #{finish_time}"))

end
