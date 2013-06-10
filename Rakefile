# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))
require 'rake'
require 'rake/testtask'

require 'vendor/plugins/sunspot_rails-1.1.0/lib/sunspot/rails/tasks'

require 'tasks/rails'
                       
begin
  gem 'delayed_job'
  require 'delayed/tasks'
rescue LoadError
  STDERR.puts "Run `rake gems:install` to install delayed_job"
end
