#!/bin/env ruby

require 'ruby_contracts'
require 'git'
##!!!ExternalCommand will probably be needed for doing a
##!!!git checkout by date/time.
require 'externalcommand'

# Abstraction for the management of a git repository for "stodo"
class STodoGit
  include Contracts::DSL

  public

  ###  Access

  GIT_PATH = './.git'

  # Does the top-level git-repository directory exist in the current
  # directory?
  def git_path_exists
    Dir.exist?(GIT_PATH)
  end

  def to_s
    git.inspect
  end

  ###  Basic operations

  # Update the specified file (whose name is 'handle') with contents from
  # 'item' and 'git add' it.
  pre 'handle-good' do |handle| ! handle.nil? && ! handle.empty? end
  pre 'item-good' do |f, item| ! item.nil? && item.is_a?(STodoTarget) end
  def update_file handle, item
$log.warn "handle: #{handle}"
$log.warn "item: #{item}"
$log.warn "c ! nil, c.class: #{! item.nil?}, #{item.class}"
    if ! git_path_exists then
      git.init
    end
    File.open(handle, "w") do |f|
      f.write(item.to_s)
    end
    git.add handle
  end

  # Update the specified file with 'contents' and 'git add' it.
  pre 'filename-good' do |filename| ! filename.nil? && ! filename.empty? end
#  pre 'contents-good' do |f, contents| ! contents.nil? && ! contents.empty? end
  def old__update_file filename, contents, commit_msg = nil
$log.warn "filename: #{filename}"
$log.warn "contents: #{contents}"
$log.warn "c ! nil, c.class: #{! contents.nil?}, #{contents.class}"
#$log.warn "c ! nil, c ! empty: #{! contents.nil?}, #{! contents.empty?}"
    if ! git_path_exists then
      git.init
    end
    File.open(filename, "w") do |f|
      f.write(contents)
    end
    git.add filename
    msg = Time.now
    if commit_msg then msg += " - #{commit_msg}" end
    begin
      git.commit msg
    rescue Exception => e
      $log.warn e
    end
  end

  # git-commit any pending, "staged" changes.
  pre 'git-path exists' do git_path_exists end
  def commit commit_msg = nil
    msg = Time.now.to_s
    if ! commit_msg.nil? && ! commit_msg.empty? then
      msg += " - #{commit_msg}"
    end
    begin
      git.commit msg
    rescue Exception => e
      $log.warn e
    end
  end

  private

  attr_accessor :git

  # Assume that the path of the intended git workspace is the current
  # directory.
  post 'git-dir exists' do git_path_exists end
  def initialize
    self.git = Git.init
    invariant
  end

  def invariant
    ! git.nil?
  end

end
