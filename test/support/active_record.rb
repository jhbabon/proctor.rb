require "active_record"

ActiveRecord::Base.establish_connection ENV["PROCTOR_DATABASE_URL"]

class Minitest::Test
  alias :_run_ :run

  def run
    output = nil

    ActiveRecord::Base.transaction do
      output = _run_
      raise ActiveRecord::Rollback
    end

    output
  end
end
