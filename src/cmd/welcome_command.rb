require 'open-uri'
require 'discordrb'
require 'nokogiri'
require_relative '../command'
require_relative '../schedule_formatter'

class WelcomeCommand
  extend Command

  CMD_NAME = :welcome
  OPTIONS = {
    description: 'Displays a tutorial for ScheduleBot.',
  }

  def self.call(event, *args)
    address = ENV['ENVIRONMENT'] == 'heroku' ? 'https://sch-bot.herokuapp.com/getting-started' : 'http://localhost:3000/getting-started'

    begin
      page = Nokogiri::HTML(open(address))
    rescue Errno::ECONNREFUSED
      event << "ScheduleBot website not available! Try again later."
      return
    end

    embed = Discordrb::Webhooks::Embed.new
    embed.colour = ScheduleFormatter::DEFAULT_EMBED_COLOUR
    embed.title = "Getting Started with ScheduleBot"
    embed.url = address
    embed.description = page.css('h3 small').inner_html

    content = page.css('.getting-started-section').first
    children = content.children
    # Remove all elements that contain empty text
    children.dup.each {|element| children.delete(element) if element.text.strip.length == 0 }
    # Set the NodeSet with the removed empty text elements as children of the '.getting-started-section' div
    content.children = children

    content.css('h4.subtitle').each do |heading|
      value = ''
      element = heading.next
      until element.nil? || element.name == 'h4' do
        if element.name == 'div'
          text = "```#{element.text.strip}```"
        else
          # Replaces <pre>, </pre>, <em>, and </em> with _
          text = element.inner_html.strip.gsub(/<\/?(pre|em)>/, '_').gsub(/<\/?code>/, '').gsub(/<\/?strong>/, '**')
        end
        value << text
        element = element.next
      end
      embed.add_field(name: heading.text, value: value)
    end

    if args[0] == 'server' && event.author.permission?(:manage_server)
      event.channel.send_embed('', embed)
    else
      # Delete message after 30 seconds to avoid clogging up the channel
      event.channel.send_temporary_message("Sending help message! Check your DMs.", 30)
      begin
        # Delete message after to avoid clogging up the channel
        event.message.delete
      rescue Discordrb::Errors::NoPermission
        event.channel.send_temporary_message("ScheduleBot doesn't have the necessary permissions to delete messages!", 60)
      end
      # Privately messages author
      event.author.pm.send_embed('', embed)
    end

  end

end
