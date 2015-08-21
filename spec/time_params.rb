module Time_params
  def self.minutes(min)
    min*60
  end
  def self.good
    {
    first_name: 'good',
    last_name: 'Cooper',
    start_time: "#{Time.now + minutes(5)}",
    end_time: "#{Time.now + minutes(10)}"
    }
  end
  def self.good2
    {
    first_name: 'goodTwo',
    last_name: 'Cooper',
    start_time: "#{Time.now + minutes(1)}",
    end_time: "#{Time.now + minutes(4)}"
    }
  end
  def self.good3
    {
    first_name: 'goodThree',
    last_name: 'Cooper',
    start_time: "#{Time.now + minutes(10)}",
    end_time: "#{Time.now + minutes(15)}"
    }
  end
  def self.overlap
    {
    first_name: 'overlap',
    last_name: 'Cooper',
    start_time: "#{Time.now + minutes(2)}",
    end_time: "#{Time.now + minutes(7)}"
    }
  end
  def self.old
    {
    first_name: 'old',
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