#!/usr/bin/env ruby

# require 'logger' # For when there's enough important information to warrant application logging
require 'discordrb'
require 'time'
require 'colorize'
require 'pg'

# ** Logger prepared for when there's enough important information to warrant application logging **

# $logger = Logger.new(STDERR)
# # Colourised log output
# log_formatter = Logger::Formatter.new
# $logger.formatter = proc do |severity, datetime, progname, message|
#   other_formatting = :to_s
#
#   case severity
#   when 'DEBUG'
#     colour = :light_magenta
#   when 'ERROR'
#     colour = :red
#   when 'FATAL'
#     colour = :red
#     other_formatting = :bold
#   when 'INFO'
#     colour = :light_green
#   when 'UNKNOWN'
#     colour = :light_magenta
#   when 'WARN'
#     colour = :yellow
#   end
#
#   log_formatter.call(severity, datetime, progname, message.dump).send(colour).send(other_formatting)
# end

# Enable fancy mode for discordrb logger
Discordrb::LOGGER.fancy = true

# PostgreSQL initalisation via pg
# Global variable for accessibility in all files
# Needs to be initialised before files are required to ensure that statements
# can be prepared and other initialisation processes etc.
$postgres = PG.connect(ENV['DATABASE_URL'], sslmode: ENV['ENVIRONMENT'] == 'heroku' ? 'require' : 'allow')

# pginfo = $postgres.conninfo_hash
# $logger.info("PostgreSQL connection to database initialised: #{pginfo[:user]}@#{pginfo[:host]}/#{pginfo[:dbname]}:#{pginfo[:port]} SSL: #{pginfo[:sslmode]}")

Dir[Dir.pwd + '/src/cmd/*'].each do |file|
  require file unless file.include?('events_command')
end

class ScheduleBot
  include Discordrb

  TOKEN = "Mjk0ODA5MzAxMDQwNDk2NjQx.C7aiQA.HacES9iU9s4jRtoBq9Qh08sSXXI".freeze
  CLIENT_ID = "294809301040496641".freeze

  def initialize
    @bot = Commands::CommandBot.new(token: TOKEN, client_id: CLIENT_ID, prefix: '&', command_doesnt_exist_message: File.read('assets/help_messages/info.txt'))
  end

  def setup
    add_command(InfoCommand)
    add_command(ScheduleCommand)
    add_command(WhereCommand)
    add_command(PresetsCommand)
    add_command(WelcomeCommand)
  end

  def start
    begin
      @bot.run(:async)
      @bot.game = '&info | sch-bot.herokuapp.com'
      @bot.sync
    rescue Interrupt
      # $logger.info("Shutting down ScheduleBot..")
      @bot.stop
      # $logger.close
    end
  end

  private

  def add_command(command)
    @bot.command(command.command_name, command.options) do |event, *args|
      command.call(event, *args)
    end
  end

end

bot = ScheduleBot.new
bot.setup
bot.start
