#!/bin/env ruby

require 'ruby_contracts'

# Option processing for stodo commands
class CommandOptions
  include Contracts::DSL

  public

  ###  Access

  # Constants for commands
  DELETE             =  'delete_target'
  STATE              =  'modify_state'
  GIT_ADD            =  'git_add'
  GIT_LOG            =  'git_log'
  GIT_RETRIEVE       =  'git_retrieve'
  CHANGE_PARENT      =  'change_parent'
  CHANGE_HANDLE      =  'change_handle'
  CLEAR_DESCENDANTS  =  'clear_descendants'
  REMOVE_DESCENDANT  =  'remove_descendant'
  COMMANDS           =  [
    DELETE, GIT_ADD, GIT_LOG, GIT_RETRIEVE, CHANGE_PARENT, CHANGE_HANDLE,
    CLEAR_DESCENDANTS, REMOVE_DESCENDANT, STATE
  ]

  def commands
    COMMANDS
  end

  RECURSIVE_OPT = '-r'
  MESSAGE_OPT   = '-m'
  FORCE_OPT     = '-f'

  DELETE_OPTIONS             = [RECURSIVE_OPT, MESSAGE_OPT, FORCE_OPT]
  STATE_OPTIONS              = [MESSAGE_OPT]
  GIT_ADD_OPTIONS            = [RECURSIVE_OPT, MESSAGE_OPT]
  GIT_RETRIEVE_OPTIONS       = [RECURSIVE_OPT]
  CHANGE_PARENT_OPTIONS      = [MESSAGE_OPT]
  CHANGE_HANDLE_OPTIONS      = [MESSAGE_OPT]
  CLEAR_DESCENDANTS_OPTIONS  = [MESSAGE_OPT]
  REMOVE_DESCENDANT_OPTIONS  = [MESSAGE_OPT]
  GIT_LOG_OPTIONS            = []

  OPTS_FOR = {
    DELETE            => DELETE_OPTIONS,
    STATE             => STATE_OPTIONS,
    GIT_ADD           => GIT_ADD_OPTIONS,
    GIT_RETRIEVE      => GIT_RETRIEVE_OPTIONS,
    GIT_LOG           => GIT_LOG_OPTIONS,
    CHANGE_PARENT     => CHANGE_PARENT_OPTIONS,
    CHANGE_HANDLE     => CHANGE_HANDLE_OPTIONS,
    CLEAR_DESCENDANTS => CLEAR_DESCENDANTS_OPTIONS,
    REMOVE_DESCENDANT => REMOVE_DESCENDANT_OPTIONS,
  }

  # Is 'recursive' a valid option for self.command and, if so, is it set?
  def recursive?
    result = OPTS_FOR[command].include?(RECURSIVE_OPT) &&
      options.include?(RECURSIVE_OPT)
    result
  end

  # Is 'force' a valid option for self.command and, if so, is it set?
  def force?
    result = OPTS_FOR[command].include?(FORCE_OPT) &&
      options.include?(FORCE_OPT)
    result
  end

  # If the 'message' option is valid for self.command, the contents of the
  # specified message; otherwise, nil
  def message
    result = nil
    if OPTS_FOR[command].include?(MESSAGE_OPT) then
      msg_index = options.index(MESSAGE_OPT)
      if ! msg_index.nil? && msg_index < options.count - 1 then
        result = options[msg_index + 1]
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
