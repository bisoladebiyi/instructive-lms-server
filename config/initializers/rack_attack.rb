# Rack::Attack configuration for rate limiting

class Rack::Attack
  ### Configure Cache ###
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Spammy Clients ###
  throttle("req/ip", limit: 60, period: 1.minute) do |req|
    req.ip
  end

  ### Prevent Brute-Force Login Attacks ###
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/api/v1/auth/login" && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email (5 attempts per minute)
  throttle("logins/email", limit: 5, period: 1.minute) do |req|
    if req.path == "/api/v1/auth/login" && req.post?
      # Normalize email to prevent case-sensitivity bypass
      req.params.dig("user", "email")&.downcase&.strip
    end
  end

  ### Prevent Signup Abuse ###
  throttle("signups/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/api/v1/auth/signup" && req.post?
      req.ip
    end
  end

  ### Custom Throttle Response ###
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [{ error: "Rate limit exceeded. Retry in #{retry_after} seconds." }.to_json]
    ]
  end
end
