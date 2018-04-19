require "spec_helper"

RSpec.describe Timerizer::Duration do
  describe "#new" do
    it "constructs a new `Duration` from a hash of units" do
      duration = Timerizer::Duration.new
      expect(duration.get(:seconds)).to eq(0)
      expect(duration.get(:months)).to eq(0)

      duration = Timerizer::Duration.new(seconds: 10)
      expect(duration.get(:seconds)).to eq(10)
      expect(duration.get(:months)).to eq(0)

      duration = Timerizer::Duration.new(second: 10, minute: 20, hours: 30)
      expect(duration.get(:seconds)).to eq(10 + (20 * 60) + (30 * 60 * 60))
      expect(duration.get(:months)).to eq(0)

      duration = Timerizer::Duration.new(seconds: 10, months: 20)
      expect(duration.get(:seconds)).to eq(10)
      expect(duration.get(:months)).to eq(20)

      duration = Timerizer::Duration.new(hours: 1, days: 2, year: 10)
      expect(duration.get(:seconds)).to eq((60 * 60) + (2 * 24 * 60 * 60))
      expect(duration.get(:months)).to eq(10 * 12)
    end
  end

  describe "#before" do
    let(:time) { Time.new(2000, 1, 1, 3, 45, 00) }
    let(:end_of_march) { Time.new(2000, 3, 31, 3, 45, 00) }

    it "returns the time before the given duration" do
      expect(5.minutes.before(time)).to eq(Time.new(2000, 1, 1, 3, 40, 00))
      expect(5.months.before(time)).to eq(Time.new(1999, 8, 1, 3, 45, 00))
      expect(65.months.before(time)).to eq(Time.new(1994, 8, 1, 3, 45, 00))

      expect(
        (60.minutes 12.months).before(time)
      ).to eq(Time.new(1999, 1, 1, 2, 45, 00))

      expect(
        1.month.before(end_of_march)
      ).to eq(Time.new(2000, 2, 29, 3, 45, 00))

      expect(
        (1.year 1.month 1.week 1.day 1.hour 1.minute 1.second).before(time)
        # 2000, 1, 1, 3, 45, 00
        # 1999, 1, 1, 3, 45, 00
        # 1998, 12, 1, 3, 45, 00
        # 1998, 11, 25, 3, 45, 00
        # 1998, 11, 24, 3, 45, 00
        # 1998, 11, 24, 2, 45, 00
        # 1998, 11, 24, 2, 44, 00
        # 1998, 11, 24, 2, 43, 59
      ).to eq(Time.new(1998, 11, 23, 2, 43, 59))

      expect(
        (1.year 1.month 1.week 1.day 1.hour 1.minute 1.second)
          .before(end_of_march)
        # 2000, 3, 31, 3, 45, 00
        # 1999, 3, 31, 3, 45, 00
        # 1999, 2, 28, 3, 45, 00
        # 1999, 2, 21, 3, 45, 00
        # 1999, 2, 20, 3, 45, 00
        # 1999, 2, 20, 2, 45, 00
        # 1999, 2, 20, 2, 44, 00
        # 1999, 2, 20, 2, 43, 59
      ).to eq(Time.new(1999, 2, 20, 2, 43, 59))
    end
  end

  describe "#after" do
    let(:time) { Time.new(2000, 1, 1, 3, 45, 00) }
    let(:end_of_january) { Time.new(2000, 1, 31, 3, 45, 00) }

    it "retruns the time after the given duration" do
      expect(5.minutes.after(time)).to eq(Time.new(2000, 1, 1, 3, 50, 00))
      expect(5.months.after(time)).to eq(Time.new(2000, 6, 1, 3, 45, 00))
      expect(65.months.after(time)).to eq(Time.new(2005, 6, 1, 3, 45, 00))

      expect(
        (60.minutes 12.months).after(time)
      ).to eq(Time.new(2001, 1, 1, 4, 45, 00))

      expect(
        1.month.after(end_of_january)
      ).to eq(Time.new(2000, 2, 29, 3, 45, 00))

      expect(
        (1.year 1.month 1.week 1.day 1.hour 1.minute 1.second).after(time)
        # 2000, 1, 1, 3, 45, 00
        # 2001, 1, 1, 3, 45, 00
        # 2001, 2, 1, 3, 45, 00
        # 2001, 2, 8, 3, 45, 00
        # 2001, 2, 9, 3, 45, 00
        # 2001, 2, 9, 4, 45, 00
        # 2001, 2, 9, 4, 46, 00
        # 2001, 2, 9, 4, 46, 01
      ).to eq(Time.new(2001, 2, 9, 4, 46, 01))

      expect(
        (1.year 1.month 1.week 1.day 1.hour 1.minute 1.second)
          .after(end_of_january)
        # 2000, 1, 31, 3, 45, 00
        # 2001, 1, 31, 3, 45, 00
        # 2001, 2, 28, 3, 45, 00
        # 2001, 3, 7,  3, 45, 00
        # 2001, 3, 8,  3, 45, 00
        # 2001, 3, 8,  4, 45, 00
        # 2001, 3, 8,  4, 46, 00
        # 2001, 3, 8,  4, 46, 01
      ).to eq(Time.new(2001, 3, 8,  4, 46, 01))
    end
  end

  describe "#to_wall" do
    it "returns an equivalent `WallClock` time" do
      expect(
        (5.hours 30.minutes).to_wall
      ).to eq(Timerizer::WallClock.new(5, 30))
    end

    it "raises an error for times beyond 24 hours" do
      expect do
        1.day.to_wall
      end.to raise_error Timerizer::WallClock::TimeOutOfBoundsError

      expect do
        217.hours.to_wall
      end.to raise_error Timerizer::WallClock::TimeOutOfBoundsError

      expect do
        (1.month 3.seconds).to_wall
      end.to raise_error Timerizer::WallClock::TimeOutOfBoundsError
    end
  end

  describe "#rounded_s" do
    it "converts all units into a string" do
      expect(
        (1.hour 3.minutes 4.seconds).rounded_s
      ).to eq("1 hour, 3 minutes")

      expect(
        (1.year 3.months 4.days).rounded_s(:long)
      ).to eq("1 year, 3 months")
    end
  end

  describe "#to_s" do
    it "converts all units into a string" do
      expect(
        (1.hour 3.minutes 4.seconds).to_s
      ).to eq("1 hour, 3 minutes, 4 seconds")

      expect(
        (1.year 3.months 4.days).to_s(:long)
      ).to eq("1 year, 3 months, 4 days")

      expect(
        (1000.years).to_s(:long)
      ).to eq("1000 years")

      expect(0.seconds.to_s).to eq("0 seconds")
      expect(0.minutes.to_s).to eq("0 seconds")
      expect(0.months.to_s).to eq("0 seconds")
      expect(0.years.to_s).to eq("0 seconds")
    end

    it "normalizes the string by default" do
      expect(30.days.to_s).to eq("1 month")
      expect((365 + 30 + 1).days.to_s).to eq("1 year, 1 month, 1 day")
    end

    it "converts units into a micro format" do
      expect(
        (1.hour 3.minutes 4.seconds).to_s(:micro)
      ).to eq("1h")

      expect(
        (1.year 3.months 4.days).to_s(:micro)
      ).to eq("1y")
    end

    it "converts units into a medium format" do
      expect(
        (1.hour 3.minutes 4.seconds).to_s(:short)
      ).to eq("1hr 3min")

      expect(
        (1.year 3.months 4.days).to_s(:short)
      ).to eq("1yr 3mo")
    end

    it "converts units using a user-defined format" do
      expect(
        (1.hour 3.minutes 4.seconds).to_s(
          units: {
            seconds: "second(s)",
            minutes: "minute(s)",
            hours: "hour(s)"
          },
          separator: ' ',
          delimiter: ' / '
        )
      ).to eq("1 hour(s) / 3 minute(s) / 4 second(s)")
    end

    it "uses user-defined options to override default format options" do
      expect(8.days.to_s(separator: "_")).to eq("1_week, 1_day")
      expect(8.days.to_s(separator: "_", delimiter: " ")).to eq("1_week 1_day")
      expect(8.days.to_s(:micro, count: :all)).to eq("1w 1d")
    end
  end

  describe "unit conversions" do
    it "converts any `Duration` to seconds" do
      expect(1.second.to_seconds).to eq(1)
      expect((10.minutes 3.seconds).to_seconds).to eq((10 * 60) + 3)
      expect((1.hour 4.minutes).to_seconds).to eq((60 * 60) + (4 * 60))
      expect(3.days.to_seconds).to eq(3 * 24 * 60 * 60)
      expect(2.weeks.to_seconds).to eq(2 * 7 * 24 * 60 * 60)

      expect(1.month.to_seconds).to eq(30 * 24 * 60 * 60)
      expect(1.year.to_seconds).to eq(365 * 24 * 60 * 60)
      expect((1.year 1.second).to_seconds).to eq((365 * 24 * 60 * 60) + 1)
    end

    it "converts any `Duration` to any second-based unit" do
      expect(1.minute.to_minutes).to eq(1)
      expect((10.hours 3.minutes).to_minutes).to eq((10 * 60) + 3)
      expect(2.days.to_hours).to eq(2 * 24)
      expect(3.days.to_days).to eq(3)
      expect(2.weeks.to_weeks).to eq(2)

      expect(1.month.to_days).to eq(30)
      expect(1.year.to_days).to eq(365)
    end

    it "converts any `Duration` to months" do
      expect(1.month.to_months).to eq(1)
      expect(366.days.to_months).to eq(12)
      expect(10.years.to_months).to eq(120)
      expect((366.days 1.month).to_months).to eq(13)
    end

    it "converts any `Duration` to any month-based unit" do
      expect(1.year.to_years).to eq(1)
      expect(732.days.to_years).to eq(2)
      expect(500.years.to_centuries).to eq(5)
      expect((3_660.days 12.month).to_years).to eq(11)
    end

    it "truncates any partial units that cannot be represented exactly" do
      expect(1.second.to_minutes).to eq(0)
      expect((3.days 2.seconds).to_minutes).to eq(3 * 24 * 60)
      expect((367.days).to_years).to eq(1)
    end

    it "defines conversions for all units" do
      Timerizer::Duration::UNIT_ALIASES.each do |unit_name, _|
        duration = Timerizer::Duration::new(unit_name => 1)
        expect(duration.send("to_#{unit_name}")).to eq(1)
      end
    end
  end

  describe "#to_unit" do
    it "converts a `Duration` to seconds" do
      expect(1.second.to_unit(:second)).to eq(1)
      expect((10.minutes 3.seconds).to_unit(:second)).to eq((10 * 60) + 3)
      expect((1.hour 4.minutes).to_unit(:second)).to eq((60 * 60) + (4 * 60))
      expect(3.days.to_unit(:seconds)).to eq(3 * 24 * 60 * 60)
      expect(2.weeks.to_unit(:seconds)).to eq(2 * 7 * 24 * 60 * 60)

      expect(1.month.to_unit(:second)).to eq(30 * 24 * 60 * 60)
      expect(1.year.to_unit(:second)).to eq(365 * 24 * 60 * 60)
      expect((1.year 1.second).to_unit(:second)).to eq((365 * 24 * 60 * 60) + 1)
    end

    it "converts a negative `Duration` to seconds" do
      expect((-1.second).to_unit(:second)).to eq(-1)
      expect((-(10.minutes 3.seconds)).to_unit(:second)).to eq(-(10 * 60) - 3)
      expect(((-10).minutes + 3.seconds).to_unit(:second)).to eq(-(10 * 60) + 3)
      expect((-3.days).to_unit(:seconds)).to eq(-3 * 24 * 60 * 60)
      expect((-2).weeks.to_unit(:seconds)).to eq(-2 * 7 * 24 * 60 * 60)

      expect((-1).month.to_unit(:second)).to eq(-30 * 24 * 60 * 60)
      expect((-1).year.to_unit(:second)).to eq(-365 * 24 * 60 * 60)

      expect(
        -(1.year 1.second).to_unit(:second)
      ).to eq(-(365 * 24 * 60 * 60) - 1)

      expect(
        ((-1).year + 1.second).to_unit(:second)
      ).to eq(-(365 * 24 * 60 * 60) + 1)
    end

    it "converts a `Duration` to any second-based unit" do
      expect(1.minute.to_unit(:minute)).to eq(1)
      expect((10.hours 3.minutes).to_unit(:minutes)).to eq((10 * 60) + 3)
      expect(2.days.to_unit(:hour)).to eq(2 * 24)
      expect(3.days.to_unit(:day)).to eq(3)
      expect(2.weeks.to_unit(:week)).to eq(2)

      expect(1.month.to_unit(:days)).to eq(30)
      expect(1.year.to_unit(:days)).to eq(365)
      expect((1.year 3.months).to_unit(:days)).to eq(365 + (3 * 30))
    end

    it "converts a negative `Duration` to any second-based unit" do
      expect((-1).minute.to_unit(:minute)).to eq(-1)
      expect((-(10.hours 3.minutes)).to_unit(:minutes)).to eq(-(10 * 60) - 3)
      expect((-2).days.to_unit(:hour)).to eq(-2 * 24)
      expect((-3).days.to_unit(:day)).to eq(-3)
      expect((-2).weeks.to_unit(:week)).to eq(-2)

      expect((-1).month.to_unit(:days)).to eq(-30)
      expect((-1).year.to_unit(:days)).to eq(-365)
      expect((-(1.year 3.months)).to_unit(:days)).to eq(-365 - (3 * 30))
      expect(
        ((-1.year) + 3.months).to_unit(:days)
      ).to eq(-9 * 30)
    end

    it "converts any `Duration` to months" do
      expect(1.month.to_unit(:month)).to eq(1)
      expect(366.days.to_unit(:month)).to eq(12)
      expect(10.years.to_unit(:months)).to eq(120)
      expect((366.days 1.month).to_unit(:months)).to eq(13)
    end

    it "converts any `Duration` to any month-based unit" do
      expect(1.year.to_unit(:year)).to eq(1)
      expect(732.days.to_unit(:years)).to eq(2)
      expect(500.years.to_unit(:centuries)).to eq(5)
      expect((3_660.days 12.month).to_unit(:years)).to eq(11)
    end

    it "truncates any partial units that cannot be represented exactly" do
      expect(1.second.to_unit(:minute)).to eq(0)
      expect((3.days 2.seconds).to_unit(:minutes)).to eq(3 * 24 * 60)
      expect((367.days).to_unit(:years)).to eq(1)
    end
  end

  describe "#to_units" do
    it "breaks down a `Duration` into multiple pieces" do
      expect(365.days.to_units(:hours)).to eq(hours: 365 * 24)
      expect(180.days.to_units(:weeks, :days)).to eq(weeks: 25, days: 5)

      expect(
        90.minutes.to_units(:days, :hours, :minutes, :seconds)
      ).to eq(days: 0, hours: 1, minutes: 30, seconds: 0)

      expect(
        (2.years 14.months).to_units(:years, :hours)
      ).to eq(years: 3, hours: 1_440)
    end

    it "can break down a negative `Duration`" do
      expect(-365.days.to_units(:hours)).to eq(hours: -365 * 24)
      expect(-180.days.to_units(:weeks, :days)).to eq(weeks: -25, days: -5)

      expect(
        -90.minutes.to_units(:days, :hours, :minutes, :seconds)
      ).to eq(days: 0, hours: -1, minutes: -30, seconds: 0)

      expect(
        (-2.years -14.months).to_units(:years, :hours)
      ).to eq(years: -3, hours: -2 * 30 * 24)

      expect(
        (-14.months + 1.day).to_units(:years, :hours)
      ).to eq(years: -1, hours: (-2 * 30 * 24) + 24)
    end

    it "returns a hash that has the same keys as the passed-in unit names" do
      # Note that we mix singular and plural forms, and that the returned
      # hash matches the pluralization for each given unit.
      expect(
        0.seconds.to_units(:second, :minutes, :hour, :days)
      ).to eq(second: 0, minutes: 0, hour: 0, days: 0)
    end
  end

  describe "#normalize" do
    it "approxmiates month-based units as second-based units" do
      expect(1.month.normalize.get(:seconds)).to eq(30 * 24 * 60 * 60)

      expect(
        11.months.normalize.get(:seconds)
      ).to eq(11 * 30 * 24 * 60 * 60)

      expect(
        14.months.normalize.get(:seconds)
      ).to eq((365 * 24 * 60 * 60) + (2 * 30 * 24 * 60 * 60))

      expect(
        (25.months 366.days).normalize.get(:seconds)
      ).to eq((3 * 365 * 24 * 60 * 60) + (30 * 24 * 60 * 60) + (24 * 60 * 60))
    end

    it "can normalize negative `Duration`s" do
      expect((-1).month.normalize.get(:seconds)).to eq(-30 * 24 * 60 * 60)

      expect(
        (-11).months.normalize.get(:seconds)
      ).to eq(-11 * 30 * 24 * 60 * 60)

      expect(
        (-14).months.normalize.get(:seconds)
      ).to eq(-(365 * 24 * 60 * 60) - (2 * 30 * 24 * 60 * 60))

      expect(
        (-(25.months 366.days)).normalize.get(:seconds)
      ).to eq(-(3 * 365 * 24 * 60 * 60) - (30 * 24 * 60 * 60) - (24 * 60 * 60))

      expect(
        (-25.months + 366.days).normalize.get(:seconds)
        # equivalent to -2 years - 1 month + 1 year + 1 day, which simplifies to
        # -1 year - 1 month + 1 day
      ).to eq(-(365 * 24 * 60 * 60) - (30 * 24 * 60 * 60) + (24 * 60 * 60))
    end

    it "can normalize using different normalization methods" do
      expect(
        1.month.normalize(method: :minimum).get(:seconds)
      ).to eq(28 * 24 * 60 * 60)

      expect(
        1.month.normalize(method: :maximum).get(:seconds)
      ).to eq(31 * 24 * 60 * 60)

      expect(
        1.year.normalize(method: :minimum).get(:seconds)
      ).to eq(365 * 24 * 60 * 60)

      expect(
        1.year.normalize(method: :maximum).get(:seconds)
      ).to eq(366 * 24 * 60 * 60)
    end
  end

  describe "#denormalize" do
    it "approximates second-based units as month-based units" do
      expect(30.days.denormalize.to_unit(:months)).to eq(1)

      expect(
        (1.month 100.days).denormalize.to_units(:months, :days)
      ).to eq(months: 4, days: 10)

      expect(
        (2.years 366.days).denormalize.to_units(:years, :days)
      ).to eq(years: 3, days: 1)
    end

    it "can denormalize negative `Duration`s" do
      expect((-30.days).denormalize.to_unit(:months)).to eq(-1)

      expect(
        (-(1.month 100.days)).denormalize.to_units(:months, :days)
      ).to eq(months: -4, days: -10)

      expect(
        (-(2.years 366.days)).denormalize.to_units(:years, :days)
      ).to eq(years: -3, days: -1)

      expect(
        # equivalent to -2 years + 1 year + 1 day, which simplifies to
        # -1 year + 1 day
        ((-2).years + 366.days).denormalize.to_units(:years, :days)
      ).to eq(years: -1, days: 1)
    end

    it "can denormalize using different normalization methods" do
      expect(
        32.days.denormalize(method: :minimum).to_units(:months, :days)
      ).to eq(months: 1, days: 4)

      expect(
        32.days.denormalize(method: :maximum).to_units(:months, :days)
      ).to eq(months: 1, days: 1)

      expect(
        367.days.denormalize(method: :minimum).to_units(:years, :days)
      ).to eq(years: 1, days: 2)

      expect(
        367.days.denormalize(method: :maximum).to_units(:years, :days)
      ).to eq(years: 1, days: 1)
    end
  end

  describe "#-@" do
    it "negates the `Duration`" do
      expect(-(10.seconds)).to eq((-10).seconds)
      expect(-(10.years)).to eq((-10).years)
      expect(-(10.years 10.seconds)).to eq((-10).seconds - 10.years)
    end
  end

  describe "#+" do
    it "can add together durations" do
      expect(1.day + 2.weeks).to eq(15.days)

      expect(
        (1.day + 1.month).to_units(:days, :months)
      ).to eq(days: 1, months: 1)
    end

    it "can add a time to a duration" do
      expect(1.day + Time.new(2000, 1, 1)).to eq(Time.new(2000, 1, 2))
      expect(1.day + 1.month + Time.new(2000, 1, 1)).to eq(Time.new(2000, 2, 2))
    end

    it "can add zero to a duration" do
      expect(1.day + 0).to eq(1.day)
      expect(1.month + 0).to eq(1.month)
      expect(1.day + 1.month + 0).to eq(1.day 1.month)
    end
  end

  describe "#-" do
    it "can find the difference between two durations" do
      expect(2.weeks - 1.day).to eq(13.days)

      expect(
        (1.month - 1.day).to_units(:days, :months)
      ).to eq(days: -1, months: 1)
    end

    it "can subtract zero from a duration" do
      expect(1.day - 0).to eq(1.day)
      expect(1.month - 0).to eq(1.month)
      expect(1.day + 1.month - 0).to eq(1.day 1.month)
    end
  end

  describe "#*" do
    it "can multiply a duration by a scalar" do
      expect(1.day * 4).to eq(4.days)
      expect((1.day 1.month) * 4).to eq(4.days 4.months)
      expect((1.day 1.month) * 0).to eq(0.seconds)
    end
  end

  describe "#/" do
    it "can divide a duration by a scalar" do
      expect(4.days / 2).to eq(2.days)
      expect((8.days 8.months) / 2).to eq(4.days 4.months)
      expect(1.second / 2).to eq(0.seconds)
    end
  end

  it "can be compared against other `Duration`s" do
    expect(1.second).not_to eq(1)

    expect(1.second).to eq(1.second)
    expect(1.minute).to eq(1.minute)
    expect(1.minute).to be < 1.hour

    expect(1.minute).to eq(60.seconds)
    expect(1.week).to eq(7.days)
    expect(12.months).to eq(1.year)
    expect(13.months).to be > 1.year

    expect(1.month).to eq(30.days)
    expect(30.days).to eq(1.month)

    expect(365.days).to eq(1.year)
    expect(366.days).to be > 1.year
  end
end
