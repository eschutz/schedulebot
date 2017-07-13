require 'shellwords'

module Emote
  ALL = File.read('assets/discord_emojis.txt').split.collect(&:to_sym)

  def self.clock_now(tz)
    minute = Time.now.in_time_zone(tz).min

    hour = Time.now.in_time_zone(tz).hour

    unless hour == 12
      hour %= 12
      hour.to_s
    end

    minute = minute >= 30 ? '30' : ''

    return get("clock#{hour}#{minute}")

  end

  def self.get_flag(timezone)

    flag_emote = get(:globe_with_meridians)

    TIMEZONE_EMOTES.each do |tz, emote|
      if tz.include?(timezone)
        flag_emote = get(emote)
        break
      end
    end

    return flag_emote
  end

  def self.get(name)
    return ":#{name}:" if ALL.include?(name.to_sym)
  end

  # Remove emotes from string, useful for special markup formatting
  def self.remove_emotes(str)
    return str.gsub(Regexp.new(":(#{ALL.collect{|e| e.to_s.shellescape }.join('|')}):"), '')
  end

  private

  TIMEZONE_EMOTES = {
    ["Europe/London"] => :flag_gb,
    ["Europe/Paris"] => :flag_fr,
    ["Europe/Berlin"] => :flag_de,
    ["Europe/Moscow", "Europe/Kaliningrad", "Europe/Volgograd", "Europe/Samara", "Asia/Yakutsk", "Asia/Krasnoyarsk", "Asia/Yekaterinburg", "Asia/Irkutsk", "Asia/Vladivostok", "Asia/Srednekolymsk", "Asia/Kamchatka"] => :flag_ru,
    ["Europe/Rome"] => :flag_it,
    ["Europe/Madrid"] => :flag_es,
    ["Asia/Seoul"] => :flag_kr,
    ["Asia/Tokyo"] => :flag_jp,
    ["Asia/Shanghai", "Asia/Chongqing", "Asia/Hong_Kong", "Asia/Urumqi"] => :flag_cn,
    ["Pacific/Honolulu", "America/Juneau", "America/Los_Angeles", "America/Denver", "America/Phoenix", "America/Chicago", "America/New_York"] => :flag_us
  }

end
