class Vec
  attr_accessor :x, :y

  def initialize x, y
    @x = x
    @y = y
  end

  def + other
    Vec.new x+other.x, y+other.y
  end

  def - other
    Vec.new x-other.x, y-other.y
  end

  def scale s
    Vec.new x*s, y*s
  end

  def magnitude
    Math.sqrt(x**2+y**2)
  end

  def normalize
    if x == 0 && y == 0
      Vec.new 0,0
    else
      self.scale(1.0/magnitude)
    end
  end

  def snap_to_grid
    Vec.new x.round, y.round
  end
end
