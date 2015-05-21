require 'logging'

Log = Logging.logger['example_logger']
Log.level = :debug
Logfile = Logging.appenders.file('debug.log')
Log.add_appenders Logfile, Logging.appenders.stdout
