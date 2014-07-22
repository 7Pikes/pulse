class Calendar
  require 'date'

  MD = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze


  def initialize(year = Time.now.year, month = Time.now.month)
    @year = year
    @month = month.to_i

    raise "Year is out of range" unless @year > 2000 and @year < 2050
    raise "Month is out of range" unless @month > 0 and @month < 13
  end


  def mdays
    @mdays ||= ((@month == 2 and Date.gregorian_leap? @year) ? 29 : MD[@month - 1])
  end


  def start_wday
    @start_wday ||= Time.mktime(@year, @month, 01).wday
  end


  def at_position(index = 1)
    mday = index - start_wday + 1

    return nil if mday < 1 or mday > mdays

    mday
  end


  def sizes
    ind = 1

    40.times do
      break if at_position(ind).to_i == mdays
      ind += 1
    end

    # columns per rows
    [7, (ind / 7) + (ind % 7 == 0 ? 0 : 1)]
  end


  def period(subject = nil)
    case subject
    when :start
      Time.mktime(@year, @month, 1).strftime("%Y-%m-%d")
    when :end
      Time.mktime(@year, @month, mdays).strftime("%Y-%m-%d")
    else
      [
        Time.mktime(@year, @month, 1).strftime("%Y-%m-%d"),
        Time.mktime(@year, @month, mdays).strftime("%Y-%m-%d")
      ]
    end
  end

end
