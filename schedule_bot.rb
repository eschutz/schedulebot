#!/usr/bin/env ruby

require 'discordrb'
require 'time'
require 'colorize'
require 'pg'

# PostgreSQL initalisation via pg
# Global variable for accessibility in all files
# Needs to be initialised before files are required to ensure that statements
# can be prepared and other initialisation processes etc.
$postgres = PG.connect(ENV['DATABASE_URL'], sslmode: ENV['ENVIRONMENT'] == 'heroku' ? 'require' : 'allow')

Dir[Dir.pwd + '/src/cmd/*'].each do |file|
  require file unless file.include?('events_command')
end

class ScheduleBot
  include Discordrb

  TOKEN = "Mjk0ODA5MzAxMDQwNDk2NjQx.C7aiQA.HacES9iU9s4jRtoBq9Qh08sSXXI".freeze
  CLIENT_ID = "294809301040496641".freeze

  def initialize
    @bot = Commands::CommandBot.new(token: TOKEN, client_id: CLIENT_ID, prefix: '&', command_doesnt_exist_message: File.read('assets/help_messages/info.txt'))
    @channel = nil
  end

  def setup
    add_command(InfoCommand)
    add_command(ScheduleCommand)
    add_command(WhereCommand)
    add_command(PresetsCommand)
  end

  def log_exception(e)
    puts "In log_exception!"
    @bot.send_message(@channel, "```ruby\n#{e.class.name}: #{e.message}\n```")
    super
  end

  def start
    begin
      @bot.run(:async)
      @bot.game = '&info'
      @bot.sync
    rescue Interrupt
      @bot.stop
    end
  end

  private

  def add_command(command)
    @bot.command(command.command_name, command.options) do |event, *args|
      @channel = event.channel
      command.call(event, *args)
    end
  end


end

bot = ScheduleBot.new
bot.setup
bot.start
