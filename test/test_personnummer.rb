require "minitest/autorun"
require "personnummer"

class PersonnummerTest < Minitest::Test
  def assert_parse_error(input)
    error = assert_raises(Personnummer::ParseError) { Personnummer.parse(input) }
    yield error
  end

  def test_valid_12_digit_personnummer
    personnummer = Personnummer.parse("198507099805")
    assert_equal false, personnummer.coordination_number?
    assert_equal 1985, personnummer.year
    assert_equal 7, personnummer.month
    assert_equal 9, personnummer.day
    assert_equal Date.civil(1985, 7, 9), personnummer.birthday
    assert_equal 980, personnummer.sequence_number
    assert_equal 5, personnummer.control_digit

    assert_equal "850709-9805", personnummer.to_s
    assert_equal "850709-9805", personnummer.to_s(10)
    assert_equal "19850709-9805", personnummer.to_s(12)
  end

  def test_valid_12_digit_coordination_number
    personnummer = Personnummer.parse("198507699802")
    assert_equal true, personnummer.coordination_number?
    assert_equal 1985, personnummer.year
    assert_equal 7, personnummer.month
    assert_equal 9, personnummer.day
    assert_equal Date.civil(1985, 7, 9), personnummer.birthday
    assert_equal 980, personnummer.sequence_number
    assert_equal 2, personnummer.control_digit

    assert_equal "850769-9802", personnummer.to_s
    assert_equal "850769-9802", personnummer.to_s(10)
    assert_equal "19850769-9802", personnummer.to_s(12)
  end

  def test_valid_10_digit_personnummer
    personnummer = Personnummer.parse("8507099805")
    assert_equal false, personnummer.coordination_number?
    assert_equal 1985, personnummer.year
    assert_equal 7, personnummer.month
    assert_equal 9, personnummer.day
    assert_equal Date.civil(1985, 7, 9), personnummer.birthday
    assert_equal 980, personnummer.sequence_number
    assert_equal 5, personnummer.control_digit

    assert_equal "850709-9805", personnummer.to_s
    assert_equal "850709-9805", personnummer.to_s(10)
    assert_equal "19850709-9805", personnummer.to_s(12)
  end

  def test_valid_10_digit_coordination_number
    personnummer = Personnummer.parse("8507699802")
    assert_equal true, personnummer.coordination_number?
    assert_equal 1985, personnummer.year
    assert_equal 7, personnummer.month
    assert_equal 9, personnummer.day
    assert_equal Date.civil(1985, 7, 9), personnummer.birthday
    assert_equal 980, personnummer.sequence_number
    assert_equal 2, personnummer.control_digit

    assert_equal "850769-9802", personnummer.to_s
    assert_equal "850769-9802", personnummer.to_s(10)
    assert_equal "19850769-9802", personnummer.to_s(12)
  end

  def test_valid_10_digit_with_century_indicator
    personnummer = Personnummer.parse("850709+9805")
    assert_equal false, personnummer.coordination_number?
    assert_equal 1885, personnummer.year
    assert_equal 7, personnummer.month
    assert_equal 9, personnummer.day
    assert_equal Date.civil(1885, 7, 9), personnummer.birthday
    assert_equal 980, personnummer.sequence_number
    assert_equal 5, personnummer.control_digit

    assert_equal "850709+9805", personnummer.to_s
    assert_equal "850709+9805", personnummer.to_s(10)
    assert_equal "18850709-9805", personnummer.to_s(12)
  end

  def test_century_guessing
    now = Time.new(2010, 10, 10)

    # If the date has not passed yet in this century, guess last century.
    assert_equal 1912, Personnummer.parse("121212-2442", now).year
    assert_equal 1910, Personnummer.parse("101011-5283", now).year
    assert_equal 2009, Personnummer.parse("090909-9640", now).year
    assert_equal 1989, Personnummer.parse("890909-7761", now).year

    # Today counts as "passed".
    assert_equal 2010, Personnummer.parse("101010-3289", now).year

    # The "+" separator means >= 100 years, so don't guess the wrong century
    assert_equal 1911, Personnummer.parse("111111-4425", now).year
    assert_equal 1811, Personnummer.parse("111111+4425", now).year

    assert_equal 1910, Personnummer.parse("100101+7969", now).year
    assert_equal 1909, Personnummer.parse("090909+9640", now).year
  end

  def test_validation_of_control_digits
    assert Personnummer.valid?("198507099805")
    assert !Personnummer.valid?("198507099804")
    assert !Personnummer.valid?("198507099806")
    assert_parse_error("198507099806") do |error|
      assert error.checksum?
      assert_equal :checksum, error.kind
    end

    assert Personnummer.valid?("198507099813")
    assert !Personnummer.valid?("198507099812")
    assert !Personnummer.valid?("198507099814")
    assert_parse_error("198507099814") do |error|
      assert error.checksum?
      assert_equal :checksum, error.kind
    end

    # Separator does not matter
    assert Personnummer.valid?("850709-9813")
    assert Personnummer.valid?("850709+9813")
    assert !Personnummer.valid?("850709-9812")
    assert !Personnummer.valid?("850709-9814")
    assert_parse_error("850709-9814") do |error|
      assert error.checksum?
      assert_equal :checksum, error.kind
    end

    # Century does not matter when checking control digit
    assert Personnummer.valid?("19850709-9813")
    assert Personnummer.valid?("18850709-9813")
    assert Personnummer.valid?("17850709-9813")
    assert Personnummer.valid?("850709+9813")

    # Missing the control digit is not valid
    assert !Personnummer.valid?("850709-981")
    assert !Personnummer.valid?("850709981")
    assert !Personnummer.valid?("10850709981")
    assert_parse_error("108507099818") do |error|
      assert_equal :checksum, error.kind
      assert error.checksum?
    end
  end

  def test_invalid_personnummer_or_wrong_types
    [
      nil,
      [],
      {},
      false,
      true,
      0,
      188507099813
    ].each do |bad_value|
      assert !Personnummer.valid?(bad_value)
      assert_raises ArgumentError do
        Personnummer.parse(bad_value)
      end
    end

    assert_parse_error("17850709=9813") { |error| assert_equal(:invalid_format, error.kind) }
    assert_parse_error("112233-4455") { |error| assert_equal(:checksum, error.kind) }
    assert_parse_error("19112233-4455") { |error| assert_equal(:checksum, error.kind) }
    assert_parse_error("20112233-4455") { |error| assert_equal(:checksum, error.kind) }
    assert_parse_error("9999999999") { |error| assert_equal(:invalid_date, error.kind) }
    assert_parse_error("199999999999") { |error| assert_equal(:invalid_date, error.kind) }
    assert_parse_error("199909193776") { |error| assert_equal(:checksum, error.kind) }
    assert_parse_error("Just a string") { |error| assert_equal(:invalid_format, error.kind) }
  end

  def test_age
    pin = Personnummer.parse("900707-9925")

    # On their birth day and the day after
    assert_equal 0, pin.age(Time.utc(1990, 7, 7))
    assert_equal 0, pin.age(Time.utc(1990, 7, 8))

    # 6 months old
    assert_equal 0, pin.age(Time.utc(1991, 1, 7))

    # Around their 1st birthday
    assert_equal 0, pin.age(Time.utc(1991, 7, 6))
    assert_equal 1, pin.age(Time.utc(1991, 7, 7))
    assert_equal 1, pin.age(Time.utc(1991, 7, 8))

    # Much later or much earlier
    assert_equal 120, pin.age(Time.utc(2110, 12, 31))
    assert_equal 0, pin.age(Time.utc(1910, 12, 31))
  end

  def test_male?
    assert Personnummer.parse("19121212+1212").male?
    assert Personnummer.parse("198507099813").male?
    assert Personnummer.parse("198507699810").male?

    assert !Personnummer.parse("196411139808").male?
    assert !Personnummer.parse("198507099805").male?
    assert !Personnummer.parse("198507699802").male?
  end

  def test_female?
    assert Personnummer.parse("196411139808").female?
    assert Personnummer.parse("198507099805").female?
    assert Personnummer.parse("198507699802").female?

    assert !Personnummer.parse("19121212+1212").female?
    assert !Personnummer.parse("198507099813").female?
    assert !Personnummer.parse("198507699810").female?
  end

  def test_to_s_length
    pin = Personnummer.parse("900707-9925")

    assert_raises(ArgumentError) { pin.to_s(9) }
    assert_raises(ArgumentError) { pin.to_s(11) }
    assert_raises(ArgumentError) { pin.to_s(13) }
    assert_raises(ArgumentError) { pin.to_s(0) }
    assert_raises(ArgumentError) { pin.to_s(nil) }
  end

  def test_to_s_different_times
    pin = Personnummer.parse("900707-9925")

    assert_equal "900707-9925", pin.to_s(10)
    assert_equal "900707-9925", pin.to_s(10, Time.now)
    assert_equal "900707+9925", pin.to_s(10, Time.new(2090, 7, 7))
    assert_equal "19900707-9925", pin.to_s(12, Time.new(2090, 7, 7))
  end
end
