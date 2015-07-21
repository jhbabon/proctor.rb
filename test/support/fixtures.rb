module Fixtures
  def fixtures_path
    File.join(__dir__, "..", "fixtures")
  end

  def fixture_file(filename)
    File.new(File.join(fixtures_path, filename))
  end
end

Minitest::Test.send(:include, Fixtures)
