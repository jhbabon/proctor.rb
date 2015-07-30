require "active_record"

ActiveRecord::Base.establish_connection ENV["PROCTOR_DATABASE_URL"]

class Minitest::Test
  alias :_run_ :run

  def run
    output = nil
    boom   = nil

    ActiveRecord::Base.transaction do
      begin
        output = _run_
      rescue => e
        raise ActiveRecord::Rollback
        boom = e
      ensure
        raise ActiveRecord::Rollback
      end
    end

    raise boom if boom

    output
  end
end
