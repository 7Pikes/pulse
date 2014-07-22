#encoding: utf-8

class Calendar
  MD = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze


  def initialize(year, month)
    year ||= Time.now.year
    month ||= Time.now.month

    @year = year.to_i
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


  def offset(step = 1)

    if step >= 0

      if @month + step > 12
        nm = step - (12 - @month)
        ny = @year + 1
      else
        nm = step + @month
        ny = @year
      end

    else

      step *= -1

      if @month - step < 1
        nm = 12 - step + @month
        ny = @year - 1
      else
        nm = @month - step
        ny = @year
      end

    end

    current_month = !!(nm == Time.now.month.to_i and ny == Time.now.year.to_i)

    {
      year: ny,
      month: nm,
      label: (current_month ? 'Этот месяц' : Time.mktime(ny, nm, 1).strftime("%m/%y"))
    }
  end

end
