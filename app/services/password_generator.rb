module PasswordGenerator
  def self.generate_password(length:, uppercase:, lowercase:, digits:, symbols:)
    characters = []

    characters += ("A".."Z").to_a if uppercase
    characters += ("a".."z").to_a if lowercase
    characters += ("0".."9").to_a if digits
    characters += %w[! @ # $ % ^ & * ?] if symbols

    raise ArgumentError, "No character sets selected" if characters.empty?
    raise ArgumentError, "Length must be a positive integer" unless length.is_a?(Integer) && length > 0

    Array.new(length) { characters.sample }.join
  end
end
