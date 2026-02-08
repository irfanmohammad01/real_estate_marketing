module PasswordGenerator
  def self.generate_password(length:, uppercase:, lowercase:, digits:, symbols:)
    raise ArgumentError, "Length must be a positive integer" unless length.is_a?(Integer) && length > 0

    sets = []
    sets << ("A".."Z").to_a if uppercase
    sets << ("a".."z").to_a if lowercase
    sets << ("0".."9").to_a if digits
    sets << %w[! @ # $ % ^ & * ?] if symbols

    raise ArgumentError, "No character sets selected" if sets.empty?

    password_chars = sets.map(&:sample)

    if password_chars.length > length
      raise ArgumentError, "Length too short for selected character sets"
    end

    all_chars = sets.flatten

    (length - password_chars.length).times do
      password_chars << all_chars.sample
    end

    password_chars.shuffle.join
  end
end
