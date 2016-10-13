#!/usr/bin/env ruby

require_relative 'compositetask.rb'
require_relative 'memorandum'
require_relative 'configuration'
require_relative 'filebasedspecgatherer'
require_relative 'targetbuilder'


config = Configuration.new
spec_collector = FileBasedSpecGatherer.new config
target_builder = TargetBuilder.new spec_collector.specs
#!!!!p target_builder
