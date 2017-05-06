require_relative '../command'

class InfoCommand
  extend Command

  CMD_NAME = :info
  HELP_MSG = File.read('assets/help_messages/info.txt')
  OPTIONS = {
    description: '**Display help & info about ScheduleBot.**'
  }

  def self.call(event, *args)
    event << help_message
  end

end
