# Helper module for command objects

# Did some sick metaprogramming to get around Ruby's class variable inheritance
module Command

  OPTIONS = [
    :permission_level,
    :permission_message,
    :required_permissions,
    :required_roles,
    :channels,
    :chain_usable,
    :help_available,
    :description,
    :usage,
    :arg_types,
    :min_args,
    :max_args,
    :rate_limit_message,
    :bucket
  ]

  def call(event, *args)
  end

  def help_message
    Object.const_get(self.name).const_get('HELP_MSG')
  end

  def personal_help(username)
    help_message.gsub('#{username}', username)
  end

  def command_name
    Object.const_get(self.name).const_get('CMD_NAME')
  end

  def options
    Object.const_get(self.name).const_get('OPTIONS')
  end

end
