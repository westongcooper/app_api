module Time_params
  def self.minutes(min)
    min*60
  end
  def self.good
    {
    first_name: 'Weston',
    last_name: 'Cooper',
    start_time: "#{Time.now + minutes(5)}",
    end_time: "#{Time.now + minutes(10)}"
    }
  end
  def self.good2
    {
    first_name: 'Weston',
    last_name: 'Cooper',
    start_time: "#{Time.now + minutes(1)}",
    end_time: "#{Time.now + minutes(4)}"
    }
  end
  def self.overlap
    {
    first_name: 'Weston',
    last_name: 'Cooper',
    start_time: "#{Time.now + minutes(2)}",
    end_time: "#{Time.now + minutes(7)}"
    }
  end
  def self.old
    {
    first_name: 'Weston',
    last_name: 'Cooper',
    start_time: "#{Time.now + minutes(-10)}",
    end_time: "#{Time.now + minutes(-5)}"
    }
  end
  def self.update
    {
    first_name: 'new',
    last_name: 'name',
    }
  end
end