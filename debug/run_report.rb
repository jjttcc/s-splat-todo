#!/usr/bin/env ruby
# debugging wrapper for 'report.rb'
# Needs to be run from ../ relative to this file's path.

pwd = ENV["PWD"]
["src/configuration/", "src/coordination/", "src/core/", "src/data/",
 "src/error/", "src/facility/", "src/main/", "src/notification/",
 "src/specs/", "src/util/", "src/attributes"].each do |p|
  $LOAD_PATH.unshift "#{pwd}/#{p}"
end
require 'report.rb'
