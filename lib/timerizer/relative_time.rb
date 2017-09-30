# Represents a relative amount of time. For example, '`5 days`', '`4 years`', and '`5 years, 4 hours, 3 minutes, 2 seconds`' are all RelativeTimes.
class RelativeTime
  UNITS = {
    seconds: {seconds: 1},
    minutes: {seconds: 60},
    hours: {seconds: 60 * 60},
    days: {seconds: 24 * 60 * 60},
    weeks: {seconds: 7 * 24 * 60 * 60},
    months: {months: 1},
    years: {months: 12},
    decades: {months: 12 * 10},
    centuries: {months: 12 * 100},
    millennia: {months: 12 * 1000}
  }

  UNIT_PLURALS = {
    second: :seconds,
    minute: :minutes,
    hour: :hours,
    day: :days,
    week: :weeks,
    month: :months,
    year: :years,
    decade: :decades,
    century: :centuries,
    millennium: :millennia
  }

  NORMALIZATION_METHODS = {
    standard: {
      months: { seconds: 30 * 24 * 60 * 60 },
      years: { seconds: 365 * 24 * 60 * 60 }
    },
    minimum: {
      months: { seconds: 28 * 24 * 60 * 60 },
      years: { seconds: 365 * 24 * 60 * 60 }
    },
    maximum: {
      months: { seconds: 31 * 24 * 60 * 60 },
      years: { seconds: 366 * 24 * 60 * 60 }
    }
  }

  @@units = {
    second: :seconds,
    minute: :minutes,
    hour: :hours,
    day: :days,
    week: :weeks,
    month: :months,
    year: :years,
    decade: :decades,
    century: :centuries,
    millennium: :millennia
  }

  @@in_seconds = {
    second: 1,
    minute: 60,
    hour: 3600,
    day: 86400,
    week: 604800
  }

  @@in_months = {
    month: 1,
    year: 12,
    decade: 120,
    century: 1200,
    millennium: 12000
  }

  # Average amount of time in a given unit. Used internally within the {#average} and {#unaverage} methods.
  @@average_seconds = {
    month: 2629746,
    year: 31556952
  }

  # Default syntax formats that can be used with #to_s
  # @see #to_s
  SYNTAXES = {
    micro: {
      units: {
        seconds: 's',
        minutes: 'm',
        hours: 'h',
        days: 'd',
        weeks: 'w',
        months: 'mn',
        years: 'y',
      },
      separator: '',
      delimiter: ' ',
      count: 1
    },
    short: {
      units: {
        seconds: 'sec',
        minutes: 'min',
        hours: 'hr',
        days: 'd',
        weeks: 'wk',
        months: 'mn',
        years: 'yr',
        centuries: 'ct',
        millennia: 'ml'
      },
      separator: '',
      delimiter: ' ',
      count: 2
    },
    long: {
      units: {
        seconds: ['second', 'seconds'],
        minutes: ['minute', 'minutes'],
        hours: ['hour', 'hours'],
        days: ['day', 'days'],
        weeks: ['week', 'weeks'],
        months: ['month', 'months'],
        years: ['year', 'years'],
        centuries: ['century', 'centuries'],
        millennia: ['millenium', 'millennia'],
      }
    }
  }

  # All potential units. Key is the unit name, and the value is its plural form.
  def self.units
    @@units
  end

  # Unit values in seconds. If a unit is not present in this hash, it is assumed to be in the {@@in_months} hash.
  def self.units_in_seconds
    @@in_seconds
  end

  # Unit values in months. If a unit is not present in this hash, it is assumed to be in the {@@in_seconds} hash.
  def self.units_in_months
    @@in_months
  end

  # Initialize a new instance of RelativeTime.
  def initialize(units = {})
    @seconds = 0
    @months = 0

    units.each do |unit, n|
      unit_info = self.class.resolve_unit(unit)
      @seconds += n * unit_info.fetch(:seconds, 0)
      @months += n * unit_info.fetch(:months, 0)
    end
  end

  # Compares two RelativeTimes to determine if they are equal
  # @param [RelativeTime] time The RelativeTime to compare
  # @return [Boolean] True if both RelativeTimes are equal
  # @note Be weary of rounding; this method compares both RelativeTimes' base units
  def ==(time)
    if time.is_a?(RelativeTime)
      @seconds == time.get(:seconds) && @months == time.get(:months)
    else
      false
    end
  end

  # Return the number of base units in a RelativeTime.
  # @param [Symbol] unit The unit to return, either :seconds or :months
  # @return [Integer] The requested unit count
  # @raise [ArgumentError] Unit requested was not :seconds or :months
  def get(unit)
    if unit == :seconds
      @seconds
    elsif unit == :months
      @months
    else
      raise ArgumentError
    end
  end

  # Determines the time between RelativeTime and the given time.
  # @param [Time] time The initial time.
  # @return [Time] The difference between the current RelativeTime and the given time
  # @example 5 hours before January 1st, 2000 at noon
  #   5.minutes.before(Time.new(2000, 1, 1, 12, 00, 00))
  #     => 2000-01-01 11:55:00 -0800
  # @see #ago
  # @see #after
  # @see #from_now
  def before(time)
    # TODO: This method should be refactored to negate `self`, then use `#after`
    time = time.to_time

    prev_day = time.mday
    prev_month = time.month
    prev_year = time.year

    units = self.to_units(:years, :months, :days, :seconds)

    date_in_month = self.class.build_date(
      prev_year - units[:years],
      prev_month - units[:months],
      prev_day
    )
    date = date_in_month - units[:days]

    Time.new(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.min,
      time.sec
    ) - units[:seconds]
  end

  # Return the time between the RelativeTime and the current time.
  # @return [Time] The difference between the current RelativeTime and Time#now
  # @see #before
  def ago
    self.before(Time.now)
  end

  # Return the time after the given time according to the current RelativeTime.
  # @param [Time] time The starting time
  # @return [Time] The time after the current RelativeTime and the given time
  # @see #before
  def after(time)
    time = time.to_time

    prev_day = time.mday
    prev_month = time.month
    prev_year = time.year

    units = self.to_units(:years, :months, :days, :seconds)

    date_in_month = self.class.build_date(
      prev_year + units[:years],
      prev_month + units[:months],
      prev_day
    )
    date = date_in_month + units[:days]

    Time.new(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.min,
      time.sec
    ) + units[:seconds]
  end

  # Return the time after the current time and the RelativeTime.
  # @return [Time] The time after the current time
  def from_now
    self.after(Time.now)
  end

  @@units.each do |unit, plural|
    in_method = "in_#{plural}"
    count_method = plural
    superior_unit = @@units.keys.index(unit) + 1

    if @@in_seconds.has_key?(unit)
      define_method(in_method) do
        self.normalize.get(:seconds) / @@in_seconds[unit]
      end
    elsif @@in_months.has_key?(unit)
      define_method(in_method) do
        self.denormalize.get(:months) / @@in_months[unit]
      end
    end

    in_superior = "in_#{@@units.values[superior_unit]}"
    count_superior = @@units.keys[superior_unit]

    define_method(count_method) do
      time = self.send(in_method)
      if @@units.length > superior_unit
        time -= self.send(in_superior).send(count_superior).send(in_method)
      end
      time
    end
  end

  def to_unit(unit)
    unit_details = self.class.resolve_unit(unit)

    if unit_details.has_key?(:seconds)
      seconds = self.normalize.get(:seconds)
      seconds / unit_details.fetch(:seconds)
    elsif unit_details.has_key?(:months)
      months = self.denormalize.get(:months)
      months / unit_details.fetch(:months)
    else
      raise "Unit should have key :seconds or :months"
    end
  end

  def to_units(*units)
    sorted_units = self.class.sort_units(units).reverse

    _, parts = sorted_units.reduce([self, {}]) do |(remainder, parts), unit|
      part = remainder.to_unit(unit)
      new_remainder = remainder - RelativeTime.new(unit => part)

      [new_remainder, parts.merge(unit => part)]
    end

    parts
  end

  def normalize(method: :standard)
    normalized_units = NORMALIZATION_METHODS.fetch(method).reverse_each

    normalized = 0.seconds
    remainder = self

    initial = [0.seconds, self]
    result = normalized_units.reduce(initial) do |result, (unit, normal)|
      normalized, remainder = result

      seconds_per_unit = normal.fetch(:seconds)
      unit_part = remainder.send(:to_unit_part, unit)

      new_normalized = normalized + (unit_part * seconds_per_unit).seconds
      new_remainder = remainder - RelativeTime.new(unit => unit_part)
      [new_normalized, new_remainder]
    end

    normalized, remainder = result
    normalized + remainder
  end

  def denormalize(method: :standard)
    normalized_units = NORMALIZATION_METHODS.fetch(method).reverse_each

    denormalized = 0.seconds
    remainder = self

    initial = [0.seconds, self]
    result = normalized_units.reduce(initial) do |result, (unit, normal)|
      denormalized, remainder = result

      seconds_per_unit = normal.fetch(:seconds)
      remainder_seconds = remainder.get(:seconds)

      num_unit = remainder_seconds / seconds_per_unit
      num_seconds_denormalized = num_unit * seconds_per_unit

      # TODO: Refactor to avoid calling `#send`
      denormalized += RelativeTime.new(unit => num_unit)
      remainder -= num_seconds_denormalized.seconds

      [denormalized, remainder]
    end

    denormalized, remainder = result
    denormalized + remainder
  end

  # Add two {RelativeTime}s together.
  # @raise ArgumentError Argument isn't a {RelativeTime}
  # @see #-
  def +(time)
    raise ArgumentError unless time.is_a?(RelativeTime)
    RelativeTime.new(
      seconds: @seconds + time.get(:seconds),
      months: @months + time.get(:months)
    )
  end

  # Find the difference between two {RelativeTime}s.
  # @raise ArgumentError Argument isn't a {RelativeTime}
  # @see #+
  def -(time)
    raise ArgumentError unless time.is_a?(RelativeTime)
    RelativeTime.new(
      seconds: @seconds - time.get(:seconds),
      months: @months - time.get(:months)
    )
  end

  # Converts {RelativeTime} to {WallClock}
  # @return [WallClock] {RelativeTime} as {WallClock}
  # @example
  #   (17.hours 30.minutes).to_wall
  #     # => 5:30:00 PM
  def to_wall
    raise WallClock::TimeOutOfBoundsError if @months > 0
    WallClock.new(second: @seconds)
  end

  # Convert {RelativeTime} to a human-readable format.
  def to_s(format = :long, options = nil)
    syntax =
      case format
      when Symbol
        SYNTAXES.fetch(format)
      when Hash
        format
      else
        raise ArgumentError, "Expected #{format.inspect} to be a Symbol or Hash"
      end

    syntax = syntax.merge(options || {})

    if syntax[:count].nil? || syntax[:count] == :all
      count = @@units.count
    else
      count = syntax[:count]
    end

    syntax_units = syntax.fetch(:units)
    units = self.to_units(*syntax_units.keys).select {|unit, n| n > 0}

    separator = syntax[:separator] || ' '
    delimiter = syntax[:delimiter] || ', '
    units.take(count).map do |unit, n|
      unit_label = syntax_units.fetch(unit)

      singular, plural =
        case unit_label
        when Array
          unit_label
        else
          [unit_label, unit_label]
        end

        unit_name =
          if n == 1
            singular
          else
            plural || singular
          end

        [n, unit_name].join(separator)
    end.join(syntax[:delimiter] || ', ')
  end

  private

  # This method is like `#to_unit`, except it does not perform normalization
  # first. Put another way, this method is essentially the same as `#to_unit`
  # except it does not normalize the value first. It is similar to `#get` except
  # that it can be used with non-primitive units as well.
  #
  # @example
  # (1.year 1.month 365.days).to_unit_part(:month)
  # # => 13
  # # Returns 13 because that is the number of months contained exactly within
  # # the sepcified `RelativeTime`. Since "days" cannot be translated to an
  # # exact number of months, they *are not* factored into the result at all.
  #
  # (25.months).to_unit_part(:year)
  # # => 2
  # # Returns 2 becasue that is the number of months contained exactly within
  # # the specified `RelativeTime`. Since "years" is essentially an alias
  # # for "12 months", months *are* factored into the result.
  def to_unit_part(unit)
    unit_details = self.class.resolve_unit(unit)

    if unit_details.has_key?(:seconds)
      seconds = self.get(:seconds)
      seconds / unit_details.fetch(:seconds)
    elsif unit_details.has_key?(:months)
      months = self.get(:months)
      months / unit_details.fetch(:months)
    else
      raise "Unit should have key :seconds or :months"
    end
  end

  def self.normalize_unit(unit)
    if UNITS.has_key?(unit)
      unit
    elsif UNIT_PLURALS.has_key?(unit)
      UNIT_PLURALS.fetch(unit)
    else
      raise ArgumentError, "Unknown unit: #{unit.inspect}"
    end
  end

  def self.resolve_unit(unit)
    normalized_unit = self.normalize_unit(unit)
    UNITS.fetch(normalized_unit)
  end

  def self.sort_units(units)
    units.sort_by do |unit|
      index = UNITS.find_index {|u, _| u == self.normalize_unit(unit)}
      index or raise ArgumentError, "Unknown unit: #{unit.inspect}"
    end
  end

  def self.mod_div(x, divisor)
    modulo = x % divisor
    [modulo, (x - modulo).to_i / divisor]
  end

  def self.month_carry(month)
    month_offset, year_carry = self.mod_div(month - 1, 12)
    [month_offset + 1, year_carry]
  end

  # Create a date from a given year, month, and date. If the month is not in
  # the range 1..12, then the month will "wrap around", adjusting the given
  # year accordingly (so a year of 2017 and a month of 0 corresponds with
  # 12/2016, a year of 2017 and a month of 13 correpsonds with 1/2018, and so
  # on). If the given day is out of range of the given month, then the
  # date will be nudged back to the last day of the month.
  def self.build_date(year, month, day)
    new_month, year_carry = self.month_carry(month)
    new_year = year + year_carry

    if Date.valid_date?(new_year, new_month, day)
      Date.new(new_year, new_month, day)
    else
      Date.new(new_year, new_month, -1)
    end
  end
end
