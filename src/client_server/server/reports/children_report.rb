require 'base_report'
require 'treenode'
require 'timetools'

class ChildrenReport < BaseReport
  include TimeTools

  def report(handles)
    result = []
    handles.each do |handle|
      target = database[handle]
      if target.nil? then
        @message = "No item with handle '#{handle}' found."
        return nil
      end

      tree = TreeNode.new(target)
      result << tree.descendants_report do |t|
        if short_format then
          "#{t.handle}"
        else
          "#{t.handle}, due: #{time_24hour(t.time)} (#{t.state})"
        end
      end.strip # Strip any trailing newlines from the individual hierarchy report
    end
    result.join("\n")
  end

end
