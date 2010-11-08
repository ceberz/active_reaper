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
      while klass.count("#{klass.table_name}.#{field} < '#{window.ago.to_s(:db)}'") > 0
        begin
          klass.find(:all, :conditions => "#{klass.table_name}.#{field} < '#{window.ago.to_s(:db)}'", :order => "#{klass.table_name}.#{field} ASC", :limit => BATCH_SIZE).each do |item|
            begin
              item.destroy
            rescue Exception => e
              # HoptoadNotifier.notify(e) # Do you use Hoptoad?
              next
            end
          end 
        rescue Exception => e
          # HoptoadNotifier.notify(e) # Do you use Hoptoad?
        end
      end
    end
  
    def self.reap_delete(klass, window, field)
      klass.delete_all("#{klass.table_name}.#{field} < '#{window.ago.to_s(:db)}'")
    end
  end
end