#!/usr/bin/env rake
require "bundler/gem_tasks"
require "rake/testtask"

task :default => :test

Rake::TestTask.new do |test|
  test.pattern = "test/**/test_*.rb"
end

desc "Run benchmarks"
task :benchmark do
  system "ruby benchmarks/benchmark.rb"
end
task :bm => :benchmark