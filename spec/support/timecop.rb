Timecop.safe_mode = true

module TimecopHelpers
  def travel_to(date, &block)
    Timecop.travel(date, &block)
  end
end

RSpec.configure do |config|
  config.include TimecopHelpers
end
