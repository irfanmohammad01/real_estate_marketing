DEFAULT_RATE_LIMIT = {
  to: ENV.fetch("RATE_LIMIT_COUNT", 1000).to_i,
  within: ENV.fetch("RATE_LIMIT_WINDOW", 60).to_i.seconds
}.freeze