Timecop.safe_mode = true

module TimecopHelpers
  def travel_to(date, &)
    Timecop.travel(date, &)
  end
end

RSpec.configure do |config|
  config.include TimecopHelpers
end
