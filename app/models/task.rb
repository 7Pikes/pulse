#encoding: utf-8

class Task < ActiveRecord::Base

  belongs_to :user
  belongs_to :watcher, class_name: 'User'

  belongs_to :phase

  has_many :deadlines

  validates_presence_of :id, :title

  default_scope do
    where("phase_id in (#{Phase.active_phases})").order("user_id, id")
  end


  def to_pretty_s(target = :default)
    buf = []

    if target == :default
      buf << (blocked ? '(Заблокирована) ' : '')
    end
    
    buf << title
    buf << ', '
    buf << localized_phase
    buf << ' c '
    buf << localized_date
    buf << ' - '
    buf << '<a href="' + global_in_context_url + '">Открыть</a>'

    buf.join
  end


  def localized_date
    months = %w(января февраля марта апреля мая июня июля августа сентября октября ноября декабря)
    "#{moved_at.day} #{months[moved_at.month - 1]}"
  end


  def localized_phase    
    result = nil

    if ready_to_pull

      result = case phase.name
      when 'Programming'
        'ждет ревью'
      when 'Reviewing'
        'ждет тестинга'
      when 'Testing'
        'ждет выкатки'
      end

    else

      result = case phase.name
      when 'Programming'
        'в работе'
      when 'Reviewing'
        'ревьювится'
      when 'Testing'
        'тестируется'
      when 'Deploying'
        'выкатывается'
      when 'Validating'
        'проверяется'
      end

    end

    result
  end


  def deadlines_list
    array = deadlines.sort.map { |d| d.deadline.strftime("%Y-%m-%d") }

    return '' unless array.any?

    str = "(#{array.count}): "
    array[0...-1].each { |el| str += "<strike>#{el}</strike>, " }
    str += array[-1]

    str
  end

end
