# Configuration settings for the current run
class Configuration
  # path of the stodo specification files
  attr_reader :spec_path

  def initialize
    @spec_path = './testdir'  # (Temporarily hard-coded for early testing)
  end
end
