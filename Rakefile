require "rake/testtask"
require "sinatra/activerecord/rake"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

task :default => :test

task :env do
  require "./environment"
end

namespace :db do
  task :load_config => :env do
    require "proctor"
  end

  namespace :test do
    desc "Setup database for test env. Use this instead of db:test:prepare"
    task :setup do
      system "RACK_ENV='test' bundle exec rake db:drop db:create db:schema:load"
    end
  end
end
