#!/bin/env ruby

require 'ruby_contracts'

# Option processing for stodo commands
class CommandOptions
  include Contracts::DSL

  public

  ###  Access

  # Constants for commands
  DELETE        =  'delete_target'
  GIT_ADD       =  'git_add'
  GIT_LOG       =  'git_log'
  GIT_RETRIEVE  =  'git_retrieve'
  COMMANDS      =  [DELETE, GIT_ADD, GIT_LOG, GIT_RETRIEVE]

  def commands
    COMMANDS
  end

  RECURSIVE_OPT = '-r'
  MESSAGE_OPT   = '-m:'

  DELETE_OPTIONS       = [RECURSIVE_OPT]
  GIT_ADD_OPTIONS      = [RECURSIVE_OPT, MESSAGE_OPT]
  GIT_RETRIEVE_OPTIONS = [RECURSIVE_OPT]
  GIT_LOG_OPTIONS      = []

  OPTS_FOR = {
    DELETE          => DELETE_OPTIONS,
    GIT_ADD         => GIT_ADD_OPTIONS,
    GIT_RETRIEVE    => GIT_RETRIEVE_OPTIONS,
    GIT_LOG         => GIT_LOG_OPTIONS,
  }

  # Is 'recursive' a valid option for self.command and, if so, is it set?
  def recursive?
    result = OPTS_FOR[command].include?(RECURSIVE_OPT) &&
      options.include?(RECURSIVE_OPT)
    result
  end

  # If the 'message' option is valid for self.command, the contents of the
  # specified message; otherwise, nil
  def message
    result = nil
    if OPTS_FOR[command].include?(MESSAGE_OPT) then
      msg_o = options.find do |o| o =~ /^#{MESSAGE_OPT}/ end
      if msg_o then
        result = msg_o[MESSAGE_OPT.length..-1]
      end
    end
    result
  end

  private

  attr_accessor :options, :command

  pre 'cmd is string' do |c| ! c.nil? && ! c.empty? && c.is_a?(String) end
  pre 'valid command' do |c| commands.include?(c) end
  pre 'opts nil or array' do |c, opts| opts == nil || opts.is_a?(Array) end
  def initialize cmd, opts
    self.command = cmd
    self.options = opts
  end

end
