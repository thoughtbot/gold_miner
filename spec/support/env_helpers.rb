module EnvHelpers
  def with_env(env)
    original_env = ENV.to_hash
    ENV.update(env)

    yield
  ensure
    ENV.replace(original_env)
  end
end

RSpec.configure do |config|
  config.include EnvHelpers
end
