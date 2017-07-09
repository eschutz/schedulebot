require_relative 'event'

class Schedule

  class ServerEvent < Event

    def initialize(from, to, activity, description, id=nil)
      @description = description
      super(from, to, activity, id)
    end

    def serialise
      return {
        @id.to_sym => {
          type: "ServerEvent",
          from: @from,
          to: @to,
          activity: @activity,
          description: @description
        }
      }
    end

    def self.deserialise(data)
      json = data.values.first
      return ServerEvent.new(Time.parse(json["from"]), Time.parse(json["to"]), json["activity"], json["description"], data.keys[0])
    end

  end

end
