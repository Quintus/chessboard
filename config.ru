# config.ru
# Rack handler configuration.

# This is a little hacky, but the only way to run code after
# the application has shutdown. It must come before Sinatra
# gets time to register its own exit handler, see
# http://stackoverflow.com/questions/12724066
# http://stackoverflow.com/questions/11105556
at_exit{ Chessboard::Forum.stop_monitoring_threads }

require_relative "lib/chessboard"

# Spawn the threads monitoring the mailinglists. Again, like
# the at_exit handler above, this is hacky and binds things to
# a single process. It will fail if you run Chessboard over multiple
# processes, because each process would then use its own monitor,
# and mails are going to appear in the board multiple times (corresponding
# to the number of processes you spawned). The correct way to resolve
# this would be to extract the monitor into a separate process, but
# that is fairly complicated then.
Chessboard::Forum.start_monitoring_threads

run Chessboard::Application
