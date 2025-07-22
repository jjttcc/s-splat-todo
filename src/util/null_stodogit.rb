# A Null Object implementation for STodoGit.
# This class provides a safe, do-nothing alternative to STodoGit
# when Git functionality is disabled or not available. It mimics
# the public interface of STodoGit to prevent NoMethodErrors.
class NullSTodoGit
  def initialize(*args); end
  def update_count; 0; end
  def commit_pending; false; end
  def path; nil; end
  def handles_in_repo; []; end
  def in_git(handle); false; end
  def list_files(outfile = $stdout); end
  def show_git_log(hndls = [], outfile = $stdout); []; end
  def show_git_version(commit_id, handles, outfile = $stdout); []; end
  def rebuild_cache; end
  def update_file(item); end
  def update_files(item_list, only_git_items = false); end
  def update_items_and_commit(items, commit_msg, only_git_items = false); end # Added
  def move_file(old_and_new_hndl); end
  def delete_file(item); end
  def commit(commit_msg = nil); end

  alias_method :update_item, :update_file
end