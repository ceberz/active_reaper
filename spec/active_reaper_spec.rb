require 'spec_helper.rb'

ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'posts'")
ActiveRecord::Base.connection.create_table(:posts) do |t|
    t.string :title
    t.string :content
    t.boolean :flagged
    t.timestamps
end
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'comments'")
ActiveRecord::Base.connection.create_table(:comments) do |t|
    t.belongs_to :post
    t.string :content
end

class Post < ActiveRecord::Base
  has_many :comments, :dependent => :destroy
end

class Comment < ActiveRecord::Base
  belongs_to :post
end

describe ActiveReaper do
  before do
      ActiveRecord::Base.connection.increment_open_transactions
      ActiveRecord::Base.connection.begin_db_transaction
      
      @post_to_be_deleted = Post.create
      @post_that_survives = Post.create
      @comment = Comment.create(:post_id => @post_to_be_deleted.id)
  end
  
  describe "classes set to be reaped after an expiration date" do
    before do
      Post.class_eval do
        reap :after => 10.days
      end
      
      @post_that_survives.update_attribute :created_at, 9.days.ago
      @post_to_be_deleted.update_attribute :created_at, 11.days.ago
    end
    
    it "should correctly delete only the instances that have expired" do
      ActiveReaper.reap!
      Post.exists?(@post_that_survives.id).should be_true
      Post.exists?(@post_to_be_deleted.id).should_not be_true
    end
  end
  
  describe "classes set to be reaped after an expiration date, based on a field" do
    before do
      Post.class_eval do
        reap :after => 10.days, :determined_by => :created_at
      end
      
      @post_that_survives.update_attribute :created_at, 9.days.ago
      @post_to_be_deleted.update_attribute :created_at, 11.days.ago
    end
    
    it "should correctly delete only the instances that have expired" do
      ActiveReaper.reap!
      Post.exists?(@post_that_survives.id).should be_true
      Post.exists?(@post_to_be_deleted.id).should_not be_true
    end
  end
  
  describe "classes set to be reaped after an expiration date, based on a value returned by a method" do
    before do
      Post.class_eval do
        def last_looked_at
          created_at
        end
        
        reap :after => 10.days, :determined_by => :last_looked_at
      end
      
      @post_that_survives.update_attribute :created_at, 9.days.ago
      @post_to_be_deleted.update_attribute :created_at, 11.days.ago
    end
    
    it "should correctly delete only the instances that have expired" do
      ActiveReaper.reap!
      Post.exists?(@post_that_survives.id).should be_true
      Post.exists?(@post_to_be_deleted.id).should_not be_true
    end
  end
  
  describe "classes set to be reaped using the default delete method" do
    before do
      Post.class_eval do
        reap :after => 10.days, :determined_by => :created_at
      end
      
      @post_to_be_deleted.update_attribute :created_at, 11.days.ago
    end
    
    it "should leave dependent models behind" do
      ActiveReaper.reap!
      Comment.exists?(@comment.id).should be_true
      Post.exists?(@post_to_be_deleted.id).should_not be_true
    end
  end
  
  describe "classes set to be reaped using the optional destroy method" do
    before do
      Post.class_eval do
        reap :after => 10.days, :determined_by => :created_at, :using => :destroy
      end
      
      @post_to_be_deleted.update_attribute :created_at, 11.days.ago
    end
    
    it "should also delete dependent models" do
      ActiveReaper.reap!
      Comment.exists?(@comment.id).should_not be_true
      Post.exists?(@post_to_be_deleted.id).should_not be_true
    end
  end
  
  describe "classes set to be reaped after an expiration date, with a condition based on a field" do
    before do
      Post.class_eval do
        reap :after => 10.days, :determined_by => :created_at, :if => :flagged
      end
      
      @post_that_survives.update_attribute :created_at, 11.days.ago
      @post_that_survives.update_attribute :flagged, false
      @post_to_be_deleted.update_attribute :created_at, 11.days.ago
      @post_to_be_deleted.update_attribute :flagged, true
    end
    
    it "should correctly delete only the instances that have expired" do
      ActiveReaper.reap!
      Post.exists?(@post_that_survives.id).should be_true
      Post.exists?(@post_to_be_deleted.id).should_not be_true
    end
  end
  
  describe "classes set to be reaped after an expiration date, with a condition based on a method" do
    before do
      Post.class_eval do
        reap :after => 10.days, :determined_by => :created_at, :if => :flagged?
      end
      
      @post_that_survives.update_attribute :created_at, 11.days.ago
      @post_that_survives.update_attribute :flagged, false
      @post_to_be_deleted.update_attribute :created_at, 11.days.ago
      @post_to_be_deleted.update_attribute :flagged, true
    end
    
    it "should correctly delete only the instances that have expired" do
      ActiveReaper.reap!
      Post.exists?(@post_that_survives.id).should be_true
      Post.exists?(@post_to_be_deleted.id).should_not be_true
    end
  end
  
  describe "classes set to be reaped after an expiration date, with a negative condition based on a field" do
    before do
      Post.class_eval do
        reap :after => 10.days, :determined_by => :created_at, :unless => :flagged
      end
      
      @post_that_survives.update_attribute :created_at, 11.days.ago
      @post_that_survives.update_attribute :flagged, true
      @post_to_be_deleted.update_attribute :created_at, 11.days.ago
      @post_to_be_deleted.update_attribute :flagged, false
    end
    
    it "should correctly delete only the instances that have expired" do
      ActiveReaper.reap!
      Post.exists?(@post_that_survives.id).should be_true
      Post.exists?(@post_to_be_deleted.id).should_not be_true
    end
  end
  
  describe "classes set to be reaped after an expiration date, with a negative condition based on a method" do
    before do
      Post.class_eval do
        reap :after => 10.days, :determined_by => :created_at, :unless => :flagged?
      end
      
      @post_that_survives.update_attribute :created_at, 11.days.ago
      @post_that_survives.update_attribute :flagged, true
      @post_to_be_deleted.update_attribute :created_at, 11.days.ago
      @post_to_be_deleted.update_attribute :flagged, false
    end
    
    it "should correctly delete only the instances that have expired" do
      ActiveReaper.reap!
      Post.exists?(@post_that_survives.id).should be_true
      Post.exists?(@post_to_be_deleted.id).should_not be_true
    end
  end

  after do
      ActiveRecord::Base.connection.rollback_db_transaction
      ActiveRecord::Base.connection.decrement_open_transactions
  end  
end
