#!/usr/bin/env ruby
# debugging wrapper for 'stodo-mgmt.rb'
# Needs to be run from ../ relative to this file's path.

pwd = ENV["PWD"]
["src/configuration/", "src/coordination/", "src/core/", "src/data/", "src/error/", "src/facility/",
"src/main/", "src/notification/", "src/specs/", "src/util/"].each do |p|
  $LOAD_PATH.unshift "#{pwd}/#{p}"
end
puts "before: #{ARGV}"
env_args = ENV['dbug_temp_args']
env_args.split(/ /).each do |a|
  ARGV << a
end
puts "after: #{ARGV}"
require 'stodo-mgmt.rb'
