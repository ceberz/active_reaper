require 'rails'

module ActiveReaper
  class Railtie < Rails::Railtie  
    rake_tasks do
      load "tasks/active_reaper.rake"
    end
  end
end