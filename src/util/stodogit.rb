#!/bin/env ruby

require 'ruby_contracts'
require 'git'   # See References for example/info re ruby-git[1]
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

  # The handle of each item in the stodo git repository, as an array
  def handles_in_repo
#!!!!!to-do: configure the git path:
    cmd = '/bin/git'
    # (See References [2])
    args = ['ls-tree', '--full-tree', '-r', '--name-only', 'HEAD']
    ExternalCommand.execute_with_output cmd, *args
  end

  def to_s
    git.inspect
  end

  ###  Output-oriented commands

  # List all files - i.e., STodoTarget handles - in the repository, in a
  # separate process.
  def list_files outfile = $stdout
    result = ""
    handles = handles_in_repo
    if ! handles.nil? && ! handles.empty? then
      result = handles.join("\n")
    end
    outfile.puts result
  end

  # Display the git log for the specified handles.
  def show_git_log handles, outfile = $stdout
    inner_sep = '-' * 34 + "\n"
    outer_sep = '=' * 50 + "\n"
    report = ""
    if handles.nil? || handles.empty? then
      handles = handles_in_repo
    end
    first = true
    handles.each do |h|
      l = git.log(-1).object(h)
      if first then
        report += "#{h}:\n"
        first = false
      else
        report += "#{outer_sep}#{h}:\n"
      end
      entries = l.map do |commit|
        commit_report commit
      end
      report += entries.join(inner_sep)
    end
    outfile.puts report
    # (See References[3] for info on git commit names, patterns, etc.)
  end

  alias_method :list_handles, :list_files

  ###  State-changing commands

  # Update the specified file (whose name is 'handle') with contents from
  # 'item' and 'git add' it.
  pre 'handle-good' do |handle| ! handle.nil? && ! handle.empty? end
  pre 'item-good' do |f, item| ! item.nil? && item.is_a?(STodoTarget) end
  def update_file handle, item
    if ! git_path_exists then
      git.init
    end
    File.open(handle, "w") do |f|
      f.write(item.to_s)
    end
    git.add handle
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

  ### Implementation - utilities

  # A readable report based on commit 'c'
  pre 'c exists' do |c| ! c.nil? end
  def commit_report c
    "sha:     #{c.sha}\n" +
    "date:    #{c.date}\n" +
    "name:    #{c.name}\n" +
    "message: #{c.message}\n"
  end

end

=begin
References:
[1] example use with log:
  g = Git.open("/path/to/repo")
  modified = g.log(1).object(relative/path/to/file).first.date
  sha = g.log(1).object(relative/path/to/file).first.sha
Examples (Git::Log) from the ruby-git README.md:
@git.log(20).object("some_file").since("2 weeks ago").between('v2.6', 'v2.7').each { |commit| [block] }

Pass the --all option to git log as follows:
@git.log.all.each { |commit| [block] }
( https://github.com/ruby-git/ruby-git )

[2] from:
https://stackoverflow.com/questions/8533202/list-files-in-local-git-repo

[3] good, detailed explanation of what can be used for specs in a git-log
command - names, ranges, date-related specs, patterns, etc.:
https://jwiegley.github.io/git-from-the-bottom-up/1-Repository/6-a-commit-by-any-other-name.html
=end
