module Reaper
  REAPABLE_CLASSES = []
  BATCH_SIZE = 5000
  
  module Reapable
    def reap(opts = {})
      raise ArgumentError.new("Reapable class must provide time for deletion") unless opts[:after].respond_to?(:ago)
      raise ArgumentError.new("Reapable class must use either destroy (default) or delete") unless opts[:using].nil? || [:delete, :destroy].member?(opts[:using])
      
      Reaper::REAPABLE_CLASSES << { :klass => self, 
                                    :after => opts[:after], 
                                    :using => (opts[:using] || :destroy), 
                                    :determined_by => (opts[:determined_by] || :created_at) }
      
      class << self
        def is_reaped?
          true
        end
      end
    end
  end
  
  def self.reap!
    REAPABLE_CLASSES.each do |registrant|
      if registrant[:using] == :destroy
        Reaper::Methods.reap_destroy(registrant[:klass], registrant[:after], registrant[:determined_by])
      else
        Reaper::Methods.reap_delete(registrant[:klass], registrant[:after], registrant[:determined_by])
      end
    end
  end
  
  class Methods
    def self.reap_destroy(klass, window, field)
      ids_to_destroy = klass.connection.select_values("SELECT #{klass.table_name}.id FROM #{klass.table_name} WHERE #{klass.table_name}.#{field} < '#{window.ago.to_s(:db)}'")
      ids_to_destroy.each_slice(BATCH_SIZE) do |batch|
        begin
          klass.destroy(batch)
        rescue
          HoptoadNotifier.notify(e) # Do you use Hoptoad?
        end
      end
    end
  
    def self.reap_delete(klass, window, field)
      klass.delete_all("#{klass.table_name}.#{field} < '#{window.ago.to_s(:db)}'")
    end
  end
end