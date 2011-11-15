namespace 'reaper' do
  desc "Run the reaper and clean up expired objects"
  task :reap => :environment do
    ActiveReaper.reap!
  end
end
