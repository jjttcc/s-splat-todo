class Request

  attr_reader :command, :arguments

  private

  attr_writer :command, :arguments

  def initialize
    self.command = ARGV[0]
    ARGV.shift
    self.arguments = ARGV
  end

end
