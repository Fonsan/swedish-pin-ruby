# frozen_string_literal: true

module Personnummer
  class Parser
    MATCHER = /
      \A
      (?<century>\d{2})?
      (?<year>\d{2})
      (?<month>\d{2})
      (?<day>\d{2})
      (?<separator>[+\- ]?)
      (?<sequence_number>\d{3})
      (?<control_digit>\d)
      \z
    /x.freeze

    attr_reader :now

    def initialize(input, now = Time.now)
      unless input.is_a?(String)
        raise ArgumentError, "Expected String, got #{input.inspect}"
      end

      @input = input
      @now = now
      @matches = MATCHER.match(input.strip)
    end

    def validate
      validate_match
      validate_luhn
      validate_date
    end

    def valid?
      validate
      true
    rescue
      false
    end

    def parse
      validate

      {
        year: full_year,
        month: month,
        day: day,
        sequence_number: sequence_number,
        control_digit: control_digit
      }
    end

    def full_year
      century * 100 + year
    end

    def century
      if @matches["century"]
        Integer(@matches["century"], 10)
      else
        guess_century
      end
    end

    def year
      Integer(@matches["year"], 10)
    end

    def month
      @month ||= Integer(@matches["month"], 10)
    end

    def day
      @day ||= Integer(@matches["day"], 10)
    end

    # Day, but adjusted for coordination numbers being possible.
    def real_day
      if day > 60
        day - 60
      else
        day
      end
    end

    def sequence_number
      Integer(@matches["sequence_number"], 10)
    end

    def control_digit
      Integer(@matches["control_digit"], 10)
    end

    private

    def guess_century
      guessed_year = (now.year / 100) * 100 + year

      # Don't guess future dates; skip back a century when that happens.
      if Time.new(guessed_year, month, real_day) > now
        guessed_year -= 100
      end

      # The "+" separator means another century back.
      if @matches["separator"] == "+"
        guessed_year -= 100
      end

      guessed_year / 100
    end

    def validate_match
      unless @matches
        raise ParseError.new("Input did not match expected format", :invalid_format, @input)
      end
    end

    def validate_luhn
      comparator = [
        @matches["year"],
        @matches["month"],
        @matches["day"],
        @matches["sequence_number"]
      ].join("")

      if luhn(comparator) != control_digit
        raise ParseError.new("Control digit did not match expected value", :checksum, @input)
      end
    end

    def validate_date
      raise ParseError.new("#{month} is not a valid month", :invalid_date, @input) unless (1..12).cover?(month)
      raise ParseError.new("#{day} is not a valid day", :invalid_date, @input) unless (1..31).cover?(real_day)

      unless Date.valid_date?(full_year, month, real_day)
        raise ParseError.new("Input had invalid date", :invalid_date, @input)
      end
    end

    # Implementation of Luhn algorithm
    def luhn(str)
      sum = 0

      (0...str.length).each do |i|
        v = str[i].to_i
        v *= 2 - (i % 2)
        if v > 9
          v -= 9
        end
        sum += v
      end

      ((sum.to_f / 10).ceil * 10 - sum.to_f).to_i
    end
  end
end
