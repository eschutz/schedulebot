#!/usr/bin/env ruby

require 'colorize'
require_relative '../src/sch/schedule.rb'

begin
  puts '* Preset Creator *'.bold.blue
  print 'Activity name: '
  name = gets.chomp
  print 'Activity: '
  activity = gets.chomp
  print 'Daily Starting Time (24 Hour Time, hh:mm): '
  start_time = gets.chomp
  print 'Daily Finishing Time (24 Hour Time, hh:mm): '
  finish_time = gets.chomp
  print 'Weekends? (y/n): '
  weekends = gets.chomp.upcase == 'Y' ? true : false

  new_preset = Schedule::Preset.new(name, activity)

  Schedule::WeekTime::READABLE.values.each do |day|
      next if !weekends && (day == 'Saturday' || day == 'Sunday')

      new_preset.add_event(
        Schedule::Preset::AbstractWeeklyEvent.new(
          Schedule::Preset::new_abstract_week_time(day, start_time),
          Schedule::Preset::new_abstract_week_time(day, finish_time)
        )
      )

  end

  new_preset.write("#{ENV['HOME']}/Documents/Programs/Ruby/schedule_bot/assets/presets/#{name}.txt")
rescue Interrupt
  exit
end
