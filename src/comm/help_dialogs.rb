# A module of help dialogs to clean up code in the main file

module HelpDialogs

  def self.schedule_help(username)
    <<~HEREDOC
    **.schedule** – *Set your schedule for other users to see.*

    **Usage:**

    __Create a new event on the specified date, during the specified times__
    `.schedule from dd/mm/yy hh:mm to dd/mm/yy hh:mm event`

    __Set a weekly event__
    `.schedule weekly DAY hh:mm to DAY hh:mm event`

    __Set your status temporarily__
    `.schedule status {status} ON|OFF` (`.statuses` for a list of statuses)

    __Set your weekly schedule to a preset containing common hours__
    `.schedule preset {preset} ADD|REMOVE` (`.presets` for a list of presets)

    __View your schedule__
    `.schedule view`

    __Clear your schedule__
    `.schedule clear`

    __Remove an event from your schedule__
    `.schedule remove {event id}` (view event IDs with `.schedule view more`)

    __Set the timezone in which schedules are displayed__ (This affects only the schedules that you view)
    `.schedule timezone {city}`

    ***Examples***
                              __Command__                                                    __Appearance to other users (`.where`)__

    `.schedule from 27/8/17 10:00 to 2/9/17 19:00 on holidays`        #=>   *__#{username} is on holidays__*

    `.schedule MON 6pm to 7pm eating dinner`        #=>   *__#{username}__ is eating dinner*

    `.schedule status sick ON`        #=>    *__#{username} is feeling a bit under the weather right now! :nauseated_face:__*

    `.schedule preset office ADD`       #=>   *__#{username} is at work right now :computer:__*

    `.schedule remove a0b1c2d3e4f5g6h7i8j9k10l11m12n13`        #=> [Removes event with the given id]

    HEREDOC
  end

  def self.help_dialog
      <<~HEREDOC
      **ScheduleBot:** A simple bot to let others know where you are and when you are busy.

    __Execute each command without arguments to display in-depth help.__

      Commands:

      `.info`
            Display this help dialog.

      `.where` **[username]**
            Find out what a user is currently doing.

      `.schedule` **[DAY TIME "message" | from DD/MM/YY hh:mm to DD/MM/YY hh:mm {activity} | {preset}]**
            Set your schedule for the specified day/time. This will be displayed to other users when they query your username with `.where`.

      HEREDOC
  end

end
