require_relative '../command'
require_relative '../sch/schedule'

class PresetsCommand
  extend Command

  CMD_NAME = :presets
  OPTIONS = {
    description: 'List available presets.',
    usage: '`&presets`'
  }

  def self.call(event, *args)
    event << "Available Presets (`&schedule preset`): \n#{Schedule::Preset.presets.collect {|preset| "#{preset[:name].to_s.capitalize}: #{preset[:description]}" }.join("\n")}"
  end

end
