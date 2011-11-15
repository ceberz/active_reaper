# README #

## Description ##

Mark your ActiveRecord models for deletion after a certain period in a single line.  Keep these kinds of specifications out of other files or rake tasks and in the models where they belong.  A rake task iterates over all participating classes and finds objects/rows ready for deletion.  Useful on Heroku where the rake task can be called from their free daily cron task.  Ideal for objects common to social networking applications that can quickly build up over time (notifications, news feeds, private messages, etc).

## How To Use ##

Within an ActiveRecord class make a call to the "reap" method with an argument to say when a row should be deleted.  ActiveReaper will assume that you intend to base the time calculation on the datetime column 'created_at':

    class PrivateMessage < ActiveRecord::Base
      # delete private messages 30 days after they've been created
      reap :after => 30.days
    end

If you need the time calculation to be based off of another value, in can be the name of a column or an instance method:

    class PrivateMessage < ActiveRecord::Base
      # delete private messages 30 days after they've been read
      reap :after => 30.days, :determined_by => :read_at
    end
    
    # == Schema Information
    #
    # Table name: private_messages
    #
    #  id              :integer(4)      not null, primary key
    #  sweet_nothings  :text
    #  read_at         :datetime
    #  created_at      :datetime
    #  updated_at      :datetime

The default method used by ActiveReaper is to delete the expired rows using `ActiveRecord::Base.delete()`.  If there are important callbacks or child models in a `has_many :dependent => :destroy` association that need to be taken care of, tell ActiveReaper to use `ActiveRecord::Base.destroy()` instead:

    class Post < ActiveRecord::Base
      has_many :comments, :dependent => :destroy
      
      # delete posts after 3 months, and take all comments with them
      reap :after => 3.months, :using => :destroy
    end

If you want to place a guard on top of the expiration time.  The guard can be the name of a column or an instance method (_NOTE: Strings in mysql have a truth value of false_): 

    class Post < ActiveRecord::Base
      # delete posts after 1 week if it's been flagged
      reap :after => 1.week, :if => :flagged
    end

`unless` may also be used:

    class PrivateMessage < ActiveRecord::Base
      # delete private messages 30 days after they've been created, unless the user wants them saved
      reap :after => 30.days, :unless => :saved
    end

## Running The Reap Task ##

Straightforward:

    rake reaper:reap

## Don't Fear The Reaper ##

Since the actual deleting of models gets performed in a rake task, performance may not _necessarily_ be an issue, but ActiveReaper is the fastest when using the delete method, and when both the arguments for 'determined\_by' and 'if/unless' are table columns.  Using the destroy method is slower for obvious reasons, and if 'determined\_by' is given as an instance method, then every row has to be instantiated as an ActiveRecord object and evaluated to look for expired objects, making it the slowest strategy.

## Author ##

Christopher Eberz; chris@chriseberz.com; @zortnac