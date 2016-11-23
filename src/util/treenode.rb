class TreeNode
  public
  attr_reader :target

  def children
    if @children == nil then
      @children = []
      if target.can_have_children? then
        @children = target.tasks.map do |t|
          TreeNode.new(t)
        end
      end
    end
    @children
  end

  # A report on self's descendants (which includes self), using the block
  # &report_line to obtain the data the client needs from the respective
  # 'target'.  If &report_line is not given, this is simply target.handle.
  # 'level' is the desired starting indentation level, where 0 means start
  # with no indent.  'cutoff' specifies at what hierarchy level to cut off
  # the report - i.e., -1 -> no cutoff, 0 -> report nothing (nullop),
  # 1 -> report only the root (self), 2 -> report only the root and direct
  # children, etc.
  def descendants_report(level = 0, cutoff = -1, &report_line)
    if cutoff != 0 then
      if ! block_given? then
        result = ' ' * (level * @report_indent_size) + target.handle + "\n"
      else
        result = ' ' * (level * @report_indent_size) +
          "#{report_line.call(target, level)}\n"
      end
      children.each do |c|
        result += c.descendants_report(level + 1, cutoff - 1, &report_line)
      end
    else
      result = ""
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
