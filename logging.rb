require 'logging'

Log = Logging.logger(STDOUT)
Log.level = :debug
Logfile = Logging.appenders.file('debug.log')
Log.add_appenders Logfile
