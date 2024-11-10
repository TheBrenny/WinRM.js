require 'logging'
require_relative 'winrm/version'
require_relative 'winrm/connection'
require_relative 'winrm/exceptions'

# Main WinRM module entry point
module WinRM
  # Enable logging if it is requested. We do this before
  # anything else so that we can setup the output before
  # any logging occurs.
  if ENV['WINRM_LOG'] && ENV['WINRM_LOG'] != ''
    begin
      Logging.logger.root.level = ENV['WINRM_LOG']
      Logging.logger.root.appenders = Logging.appenders.stderr
    rescue ArgumentError
      # This means that the logging level wasn't valid
      warn "Invalid WINRM_LOG level is set: #{ENV['WINRM_LOG']}"
      warn ''
      warn 'Please use one of the standard log levels: ' \
        'debug, info, warn, or error'
    end
  end
end
