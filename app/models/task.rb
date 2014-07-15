#encoding: utf-8

class Task < ActiveRecord::Base

  belongs_to :user
  belongs_to :watcher, class_name: 'User'

  belongs_to :phase

  has_many :deadlines

  validates_presence_of :id, :title

  default_scope do
    where("user_id is not null and phase_id in (#{Phase.active_phases})").order("user_id, id")
  end


  def to_pretty_s
    buf = []

    buf << (blocked ? '(Заблокирована) ' : '')
    buf << title
    buf << ', '
    buf << localized_phase
    buf << ' c '
    buf << localized_date
    buf << '.'

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
    deadlines.sort.map { |d| d.deadline.strftime("%Y-%m-%d") }.join(', ')
  end

end
