require 'lib/reaper'

ActiveRecord::Base.extend Reaper::Reapable

class << ActiveRecord::Base
  def is_reaped?
    false
  end
end