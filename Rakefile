require 'bundler'
require 'rake/testtask'

desc "Same as 'rake test'"
task default: %w[test]

desc "Application environment"
task :environment do
  # Bootstrap environment here
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end
