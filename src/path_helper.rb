module PathHelper
  SCHEDULE_BOT_DIR = ENV['ENVIRONMENT'] == 'heroku' ? '/app' : "#{ENV['HOME']}/Documents/Programs/Ruby/schedule_bot"

  def self.get_asset(asset_path)
    File.read(get_asset_path(asset_path))
  end

  def self.get_data(data_path)
    File.read(get_data_path(data_path))
  end

  def self.get_data_path(path)
    File.join(SCHEDULE_BOT_DIR, 'data', path)
  end

  def self.get_asset_path(path)
    File.join(SCHEDULE_BOT_DIR, 'assets', path)
  end

end
