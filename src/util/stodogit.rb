#!/bin/env ruby

require 'ruby_contracts'
require 'git'   # See References for example/info re ruby-git[1]
require 'externalcommand'

# Abstraction for the management of a git repository for "stodo"
# This class is designed to be used essentially as a singleton - i.e.,
# instantiated as part of the process's "configuration" instantiated
# and available to be used throughout the duration of the process.
class STodoGit
  include Contracts::DSL

  public

  ###  Access

  # Number of 'update_item's executed and not yet committed:
  attr_reader :update_count
  # Has a git action been performed that requires a commit?
  attr_reader :commit_pending
  # The path of the working git repository
  attr_reader :path

  # The handle of each item in the stodo git repository, as an array
  post 'repo_handles exists' do ! @repo_handles.nil? end
  post 'repo_handles hash_exists' do ! @repo_handles_hash.nil? end
  def handles_in_repo
    # Ensure that cache (@repo_handles and @repo_handles_hash) exists:
    build_repo_handles_hash
    @repo_handles
  end

  def to_s
    git.inspect
  end

  ###  Status report

  # Is the item associated with 'handle' in the git repository (class)?
  pre 'handle' do |handle| ! handle.nil? end
  def in_git(handle)
    # Ensure that cache (@repo_handles and @repo_handles_hash) exists:
    build_repo_handles_hash
    @repo_handles_hash[handle]
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

  ###  Element change

  # Rebuild the 'repository handles' cache used in 'handle' lookups.
  def rebuild_cache
    build_repo_handles_hash true
  end

  ###  State-changing commands

  # Update the specified file/item (via item.handle) with contents from
  # 'item' and 'git add' it.
  pre  'item-good' do |item| ! item.nil? && item.is_a?(STodoTarget) end
  post 'u-count incremented by 1' do update_count > 0 end
  post 'commit pending' do commit_pending end
  def update_file item
    filepath = File.join(path, item.handle)
    File.open(filepath, "w") do |f|
      f.write(item.to_s)
    end
$log.warn "[#{__method__}] updating #{item.handle}"
    git.add item.handle
    @update_count += 1
    @commit_pending = true
  end

  # Update the specified file/item (via item.handle) with contents from
  # 'item' and 'git add' it.
  pre  'item-good' do |item| ! item.nil? && item.is_a?(STodoTarget) end
  post 'counted' do update_count > 0 end
  def old___remove___update_file item
    if ! git_path_exists then
      git.init
    end
    File.open(item.handle, "w") do |f|
      f.write(item.to_s)
    end
$log.warn "[#{__method__}] updating #{item.handle}"
    git.add item.handle
    @update_count += 1
  end

  # Update the specified files/items (via <item>.handle) with contents from
  # 'item_list' (STodoTarget objects) and 'git add' them.
  # If 'only_git_items' then only do an update for members of 'items' that
  # are already in git - i.e., bypass non-git items.
  pre  'items-good' do |ilist| ! ilist.nil? && ilist.is_a?(Array) end
  post 'counted' do update_count > 0 end
  def update_files item_list, only_git_items = false
$log.warn "[#{__method__}] ilist, ogi: #{item_list}, #{only_git_items}"
    items = item_list
    if only_git_items then
      items = item_list.select do |i|
        in_git i.handle
      end
    end
$log.warn "[#{__method__}] items: #{items}"
    items.each do |i|
      update_item(i)
    end
  end

  alias_method :update_item, :update_file
  alias_method :update_items, :update_files

  # Do an 'update_items' on 'items' and 'commit'.
  # If 'only_git_items' then only do an update for members of 'items' that
  # are already in git - i.e., bypass non-git items.
  pre  'items-good' do |items| ! items.nil? && items.is_a?(Array) end
  def update_files_and_commit(items, commit_msg, only_git_items = false)
    old_update_count = update_count
    update_items(items, only_git_items)
    if update_count > old_update_count then
      commit(commit_msg)
    end
  end

  alias_method :update_items_and_commit, :update_files_and_commit

  # Remove the specified file/item (IDd with item.handle).
  pre  'item-good' do |item| ! item.nil? && item.is_a?(STodoTarget) end
  pre  'item-in-git' do |item| in_git(item.handle) end
  post 'commit pending' do commit_pending end
  def delete_file item
$log.warn "[#{__method__}] 'rm'ing #{item.handle}"
    git.rm item.handle
    # Force the "handles" cache to be rebuilt.
    build_repo_handles_hash true
    @commit_pending = true
  end

  alias_method :delete_item, :delete_file

  # git-commit any pending, "staged" changes.
  post 'count reset' do update_count == 0 end
  post 'commit NOT pending' do ! commit_pending end
  def commit commit_msg = nil
    if commit_pending then
      msg = Time.now.to_s
      if ! commit_msg.nil? && ! commit_msg.empty? then
        msg += " - #{commit_msg}"
      end
      begin
$log.warn "#{self.class}.#{__method__} calling git.commit"
        git.commit msg
      rescue Exception => e
        $log.warn e
      end
      @update_count = 0
      @commit_pending = false
    else
      assert('update_count is 0') { update_count == 0 }
      assert('NOT commit_pending') { ! commit_pending }
      @commit_pending = false
$log.warn "#{self.class}.#{__method__} NOT calling git.commit"
    end
  end

  private

  attr_accessor :git

  # Assume that the path of the intended git workspace is the current
  # directory.
  def initialize path
    self.git = Git.init(path)
    @path = path
    @update_count = 0
    @repo_handles = nil
    @repo_handles_hash = nil
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

  # If 'force', (re-)build @repo_handles even if it already exists.
  post 'repo_handles exists' do ! @repo_handles.nil? end
  def build_repo_handles force = false
    if force || @repo_handles.nil? then
      config = Configuration.instance
      cmd = config.git_executable
      # (See References [2])
      args = config.git_lsfile_args
      @repo_handles = ExternalCommand.execute_with_output cmd, *args
    end
  end

  # If 'force', (re-)build @repo_handles and @repo_handles_hash even if
  # they already exist.
  post 'repo_handles hash_exists' do ! @repo_handles_hash.nil? end
  post 'repo_handles exists' do ! @repo_handles.nil? end
  def build_repo_handles_hash force = false
    if force then
      @repo_handles = nil
      @repo_handles_hash = nil
    end
    if @repo_handles_hash.nil? then
      if @repo_handles.nil? then
        build_repo_handles
      end
      @repo_handles_hash = @repo_handles.to_h do |e|
        [e, true]
      end
    end
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
