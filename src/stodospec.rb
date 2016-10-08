require_relative 'spectools'

# Specification for a target (action, project, or memorandum) of the s*todo
# system
class STodoSpec
  include SpecTools

  REMINDER_EXPR, START_EXPR = 'reminders?', 'start[a-z_]*'

  public

  def action_manager
    @config.action_manager
  end

  private

  def initialize spec_string, config
    split_expr = '('
    for k in [TYPE_KEY, TITLE_KEY, DESCRIPTION_KEY, HANDLE_KEY, PRIORITY_KEY,
        DUE_DATE_KEY, GOAL_KEY, MEDIA_KEY, COMMENT_KEY, PARENT_KEY] do
      split_expr += '^' + k + ':\s*|'
    end
    split_expr += '^' + REMINDER_EXPR + ':\s*|^' + START_EXPR + ':\s*)'
    split_regex = Regexp.new(split_expr)
    components = spec_string.split(split_regex, -1)
#    components = spec_string.split(split_regex)
    if components.length > 0 and components[0] == "" then
      components.shift  # Remove useless empty first element.
    end
    @setting_for = {}
    if not components.empty? and components.length % 2 == 0 then
      (0 .. components.length - 1).step(2) do |i|
        key = standardized_key(components[i].sub(/: */, ""))
        value = components[i + 1]
        @setting_for[key] = value.chomp
      end
    end
    @config = config
  end

  def method_missing method_name
    result = @setting_for[method_name.to_s]
    result
  end

  def standardized_key k
    result = k
    case result
    when 'start'
      result = 'start_date'
    when 'due'
      result = 'due_date'
    end
    result
  end
end
