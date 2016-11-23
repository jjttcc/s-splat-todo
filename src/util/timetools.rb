module TimeTools
  private

  # 'datetime' in 24-hour format - all spaces if 'datetime' == nil
  def time_24hour(datetime)
    result = nil
    if datetime == nil then
      result = ' ' * 16
    else
      result = datetime.strftime("%Y-%m-%d %H:%M")
    end
    result
  end
end
