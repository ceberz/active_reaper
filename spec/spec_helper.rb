require 'active_reaper'

root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => "#{root}/db/activereaper.db"
)
