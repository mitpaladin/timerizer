require 'date'

class RelativeTime
  @@in_seconds = {
      :second => 1,
      :minute => 60,
      :hour => 3600,
      :day => 86400,
      :week => 604800
  }

  @@in_months = {
    :month => 1,
    :year => 12,
    :decade => 120,
    :century => 1200,
    :millenium => 12000
  }

  @@average_seconds = {
    :month => 2628000,
    :year => 31540000
  }

  def initialize(count = 0, unit = :second)
    @seconds = 0
    @months = 0

    if(@@in_seconds.has_key?(unit))
      @seconds = count * @@in_seconds.fetch(unit)
    elsif(@@in_months.has_key?(unit))
      @months = count * @@in_months.fetch(unit)
    end
  end

  def before(time)
    time = time.to_time - @seconds

    new_month = time.month - @months
    new_year = time.year
    while new_month < 1
      new_month += 12
      new_year -= 1
    end
    if(Date.valid_date?(new_year, new_month, time.day))
      new_day = time.day
    else
      new_day = Date.days_in_month(new_month)
    end

    new_time = Time.new(
      new_year, new_month, time.day,
      time.hour, time.min, time.sec
    )
    Time.at(new_time.to_i, time.nsec/1000)
  end

  def ago
    self.before(Time.now)
  end

  def after(time)
    time = time.to_time + @seconds

    new_year = time.year
    new_month = time.month + @months
    while new_month > 12
      new_year += 1
      new_month -= 12
    end
    if(Date.valid_date?(new_year, new_month, time.day))
      new_day = time.day
    else
      new_month += 1
      new_day = 1
    end


    new_time = Time.new(
      new_year, new_month, time.day,
      time.hour, time.min, time.sec
    )
    Time.at(new_time.to_i, time.nsec/1000.0)
  end

  def from_now
    self.after(Time.now)
  end

  [@@in_months, @@in_seconds].each do |units|
    units.keys.each_with_index do |unit, index|
      in_method = "in_#{unit}s"
      count_method = "#{unit}s"
      superior_unit = units.keys[index+1]

      define_method(in_method) do
        count = self.instance_variable_get("@#{units.keys[0]}s")
        count / units[unit]
      end

      define_method(count_method) do
        in_superior = "in_#{superior_unit}s"

        time = self.send(in_method)
        puts units.length > index+1
        if(units.length > index+1)
          time -= self.send(in_superior).send(superior_unit).send(in_method)
        end
        time
      end
    end
  end

  def average!
    years = self.in_years
    months = self.in_months - years.years.in_months
    @seconds += (
      (@@average_seconds[:month] * months) +
      (@@average_seconds[:year] * years)
    )
    @months = 0
  end

  def to_s
    times = {}

    [@@in_months, @@in_seconds].each do |hash|
      hash.each do |unit, value|
        time = self.respond_to?("#{unit}s") ? self.send("#{unit}s") : 0
        times[unit] = time if time > 0
      end
    end

    times.map do |unit, time|
      "#{time} #{unit}#{'s' if time > 1}"
    end.reverse.join(', ')
  end
end

class Time
  add = instance_method(:+)
  define_method(:+) do |time|
    if(time.class == RelativeTime)
      time.after(self)
    else
      add.bind(self).(time)
    end
  end

  subtract = instance_method(:-)
  define_method(:-) do |time|
    if(time.class == RelativeTime)
      time.before(self)
    else
      subtract.bind(self).(time)
    end
  end

  def to_date
    Date.new(self.year, self.month, self.day)
  end

  def to_time
    self
  end
end

class Date
  def days_in_month
    days_in_feb = (not self.leap?) ? 28 : 29
    number_of_days = [
      31,  days_in_feb,  31,  30,  31,  30,
      31,  31,           30,  31,  30,  31
    ]

    number_of_days.fetch(self.month - 1)
  end

  def to_date
    self
  end
end

class Fixnum
  [:@@in_seconds, :@@in_months].each do |units|
    units = RelativeTime.class_variable_get(units)
    units.keys.each do |unit|
      define_method(unit) do
        RelativeTime.new(self, unit)
      end
      
      alias_method("#{unit}s", unit)
    end
  end
end
