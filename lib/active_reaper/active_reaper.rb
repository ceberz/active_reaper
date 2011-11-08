require "active_support"
require "active_record"

module ActiveReaper
  REAPED_CLASSES = {}
  
  def self.included(base)
    base.extend(ClassMethods)  
  end
  
  def self.reap!
    REAPED_CLASSES.each_pair do |klass, settings|
      if settings[:determined_by_type] == :column && settings[:condition].nil?
        ActiveReaper.reap_simply(klass, settings)
      elsif settings[:determined_by_type] == :column && !settings[:condition].nil? && settings[:condition_type] == :column
        ActiveReaper.reap_quickly(klass, settings)
      elsif settings[:determined_by_type] == :column && !settings[:condition].nil? && settings[:condition_type] == :method
        ActiveReaper.reap_conditionally(klass, settings)
      elsif settings[:determined_by_type] == :method
        ActiveReaper.reap_meticulously(klass, settings)
      end
    end
  end
  
  module ClassMethods
    def reap(opts)
      unless opts[:after].respond_to?(:ago)
        raise ArgumentError.new("ActiveReaper: option for 'after' must be a FixNum (amount in seconds)")
      end
      
      unless [:delete, :destroy].include? (opts[:using] || :delete)
        raise ArgumentError.new("ActiveReaper: option for 'using' must be either :delete or :destroy")
      end
      
      unless  self.column_names.include?(opts[:determined_by].to_s) || 
              self.instance_methods.include?(opts[:determined_by]) ||
              (opts[:determined_by].nil? && self.column_names.include?('created_at'))
        raise ArgumentError.new("ActiveReaper: option for 'determined_by' must be either a table column name or an instance method.  If option is left blank, table must have a datetime 'created_at' column.")
      end
      
      unless (opts[:if].nil? && opts[:unless].nil?) || ( !!opts[:if] ^ !!opts[:unless])
        raise ArgumentError.new("ActiveReaper: Pass only 'if' or 'unless' as a condition")
      end
      
      unless self.column_names.include?(opts[:if].to_s) || (opts[:if].to_s.last=='?' && self.column_names.include?(opts[:if].to_s.chop)) || self.instance_methods.include?(opts[:if]) || opts[:if].nil?
        raise ArgumentError.new("ActiveReaper: option for 'if' or 'unless' must be either a table column name or an instance method.")
      end
      
      settings = {
        :after => opts[:after],
        :using => opts[:using] || :delete,
        :determined_by => opts[:determined_by].nil? ? :created_at : opts[:determined_by],
        :determined_by_type => self.column_names.include?(opts[:determined_by].to_s) ? :column : :method,
        :condition => opts[:if].nil? ? opts[:unless] : opts[:if],
        :condition_type => nil,
        :truth_value => nil
      }
      
      if settings[:condition]
        settings[:truth_value] = opts[:if].nil? ? false : true
        settings[:condition_type] = self.column_names.include?(settings[:condition].to_s) ? :column : :method
      end  
      
      REAPED_CLASSES[self] = settings
    end
  end
  
  # run a simple delete_all or destroy_all; no conditions or method-based expiration
  def self.reap_simply(klass, settings)
    if settings[:using] == :delete
      klass.where("#{settings[:determined_by]} < ?", settings[:after].ago.to_s(:db)).delete_all
    else
      klass.where("#{settings[:determined_by]} < ?", settings[:after].ago.to_s(:db)).destroy_all
    end
  end
  
  # run a delete_all or destroy_all with the value of the column given as the condition made part of the query
  def self.reap_quickly(klass, settings)
    if settings[:using] == :delete
      klass.where("#{settings[:determined_by]} < ?", settings[:after].ago.to_s(:db)).where(settings[:condition] => settings[:truth_value]).delete_all
    else
      klass.where("#{settings[:determined_by]} < ?", settings[:after].ago.to_s(:db)).where(settings[:condition] => settings[:truth_value]).destroy_all
    end
  end
  
  # objects can be selected quickly, but have to be individually evaluated for the extra condition
  def self.reap_conditionally(klass, settings)
    klass.where("#{settings[:determined_by]} < ?", settings[:after].ago.to_s(:db)).each do |object|
      if object.send(settings[:condition]) == settings[:truth_value]
        if settings[:using] == :delete
          klass.delete(object.id)
        else
          klass.destroy(object.id)
        end
      end
    end
  end
  
  # All objects must be iterated over to see which have expired, and then may or may not require an extra condition
  def self.reap_meticulously(klass, settings)
    klass.all.each do |object|
      if (object.send(settings[:determined_by]) < settings[:after].ago) && (settings[:condition].nil? || object.send(settings[:condition]) == settings[:truth_value])
        if settings[:using] == :delete
          klass.delete(object.id)
        else
          klass.destroy(object.id)
        end
      end
    end
  end
end

::ActiveRecord::Base.send(:include, ActiveReaper)
