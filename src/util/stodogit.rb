#!/bin/env ruby

require 'ruby_contracts'
require 'git'   # See References for example/info re ruby-git[1]
require 'errortools'
require 'externalcommand'

# Abstraction for the management of a git repository for "stodo"
# This class is designed to be used essentially as a singleton - i.e.,
# instantiated as part of the process's "configuration" instantiated
# and available to be used throughout the duration of the process.
class STodoGit
  include Contracts::DSL, ErrorTools

  public

  ###  Access

  # Number of 'update_item's executed and not yet committed:
  attr_reader :update_count
  # Has a git action been performed that requires a commit?
  attr_reader :commit_pending
  # The path of the working git repository
  attr_reader :path

  # The handle of each item in the stodo git repository, as an array
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

  # Display the git log for the specified handles. If 'hndls' is nil,
  # display the entire log.
  # Return the result as an array as well.
  def show_git_log hndls = [], outfile = $stdout
    outer_sep = '=' * 50
    report = ""
    if hndls.nil? || hndls.empty? then
      handles = []
    else
      handles = hndls
    end
    config = Configuration.instance
    cmd = config.git_executable
    entries = []
    if handles.empty? then
      entries.concat(ExternalCommand.execute_with_output(cmd,
                                                         *config.git_log_args))
    else
      last = handles.count - 1
      (0 .. last).each do |i|
        args = config.git_log_args [handles[i]]
        entries << "#{handles[i]}:"
        entries.concat(ExternalCommand.execute_with_output(cmd, *args))
        if i < last then
          entries << outer_sep
        end
      end
    end
    report = entries.join("\n")
    outfile.puts report
    # (See References[3] for info on git commit names, patterns, etc.)
    entries
  end

  alias_method :list_handles, :list_files

  # Display the contents of the specified (via 'handles') items of the
  # specified commit.
  def show_git_version(commit_id, handles, outfile = $stdout)
    outer_sep = '=' * 50
    report = ""
    config = Configuration.instance
    cmd = config.git_executable
    entries = []
    last = handles.count - 1
    (0 .. last).each do |i|
      args = config.git_show_args(commit_id, handles[i])
      entries << "#{handles[i]}:"
      entries.concat(ExternalCommand.execute_with_output(cmd, *args))
      if i < last then
        entries << outer_sep
      end
    end
    report = entries.join("\n")
    outfile.puts report
    entries
  end

  ###  Element change

  # Rebuild the 'repository handles' cache used in 'handle' lookups.
  def rebuild_cache
    build_repo_handles_hash true
  end

  ###  State-changing commands

  # Update the specified file/item (via item.handle) with contents from
  # 'item' and 'git add' it. If the file associated with 'item' does not
  # exist (i.e., item is not yet in the git repository), create it before
  # writing item's contents to it and git-adding it.
  def update_file item
    filepath = File.join(path, item.handle)
    File.open(filepath, "w") do |f|
      f.write(item.to_s)
    end
    git.add item.handle
    @update_count += 1
    @commit_pending = true
  end

  # Update the specified files/items (via <item>.handle) with contents from
  # 'item_list' (STodoTarget objects) and 'git add' them.
  # If 'only_git_items' then only do an update for members of 'items' that
  # are already in git - i.e., bypass non-git items.
  def update_files item_list, only_git_items = false
    items = item_list
    if only_git_items then
      items = item_list.select do |i|
        in_git i.handle
      end
    end
    items.each do |i|
      update_item(i)
    end
  end

  alias_method :update_item, :update_file
  alias_method :update_items, :update_files

  # Do an 'update_items' on 'items' and 'commit'.
  # If 'only_git_items' then only do an update for members of 'items' that
  # are already in git - i.e., bypass non-git items.
  def update_files_and_commit(items, commit_msg, only_git_items = false)
    old_update_count = update_count
    update_items(items, only_git_items)
    if update_count > old_update_count then
      commit(commit_msg)
    end
  end

  alias_method :update_items_and_commit, :update_files_and_commit

  # Move ('git mv') the specified file/handle (old_and_new_hndl[0]) to have
  # the new name (old_and_new_hndl[1]).
  def move_file old_and_new_hndl
    config = Configuration.instance
    old_handle, new_handle = old_and_new_hndl[0], old_and_new_hndl[1]
    cmd = config.git_executable
    args = config.git_mv_args(old_handle, new_handle)
    ExternalCommand.execute_and_block(cmd, *args)
    # Force the "handles" cache to be rebuilt.
    build_repo_handles_hash true
    @commit_pending = true
  end

  # Remove the specified file/item (IDd with item.handle).
  def delete_file item
    git.rm item.handle
    # Force the "handles" cache to be rebuilt.
    build_repo_handles_hash true
    @commit_pending = true
  end

  alias_method :delete_item, :delete_file

  # git-commit any pending, "staged" changes.
  def commit commit_msg = nil
    if commit_pending then
      if ! commit_msg.nil? && ! commit_msg.empty? then
        msg = commit_msg
      else
        msg = "added #{update_count} files"
      end
      begin
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
  def commit_report c
    "sha:     #{c.sha}\n" +
    "date:    #{c.date}\n" +
    "name:    #{c.name}\n" +
    "message: #{c.message}\n"
  end

  # If 'force', (re-)build @repo_handles even if it already exists.
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
