DEFAULT_RATE_LIMIT = {
  to: ENV.fetch("RATE_LIMIT_COUNT", 10).to_i,
  within: ENV.fetch("RATE_LIMIT_WINDOW", 60).to_i.seconds
}.freeze