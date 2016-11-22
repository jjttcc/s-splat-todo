class TreeNode
  public
  attr_reader :target, :children

  def children
    if @children == nil then
      children = []
      if target.can_have_children? then
        children = target.tasks.map do |t|
          TreeNode.new(t)
        end
      end
    end
  end

  # A report on self's descendants (which includes self), using the block
  # &report_line to obtain the data the client needs from the respective
  # 'target'.  If &report_line is not given, this is simply target.handle.
  def descendants_report(level = 0, &report_line)
    if ! block_given? then
      result = ' ' * (level * @report_indent_size) + target.handle + "\n"
    else
      result = ' ' * (level * @report_indent_size) +
        "#{report_line.call(target)}\n"
    end
    children.each do |c|
      result += c.descendants_report(level + 1, &report_line)
    end
    result
  end

  private

  # postcondition: target != nil
  def initialize(target, report_indent_size = 2)
    @target = target
    @report_indent_size = report_indent_size
  end

end
