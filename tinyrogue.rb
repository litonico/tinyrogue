require 'io/console'
require './vec'

BACKGROUND_MAP = <<-MAP
........
........
........
........
........
MAP

class Term
  MAP_WIDTH = 8
  TRAILING_NEWLINE = 1

  attr_reader :state

  def initialize state
    @state = state

    puts "hjkl to move, q to quit"
  end

  def draw
    clear

    entity_map = String.new BACKGROUND_MAP
    state.entities.each do |entity|
      entity_pos = entity.pos
      entity_coord = entity_pos.x + entity_pos.y*(MAP_WIDTH+TRAILING_NEWLINE)
      entity_map[entity_coord] = entity.sprite
    end

    puts entity_map
  end

  def clear
    print "\x1b[2J\x1b[1;1H"
  end
end

class Entity
  attr_accessor :pos
  def initialize pos
    @pos = pos
  end

  def step hero
    raise "unnamed entity needs movement pattern"
  end
end

class Rat < Entity
  def sprite
    "r"
  end

  def step hero
    move_towards hero
  end

  def move_towards other
    direction = other.pos - self.pos
    self.pos += direction.normalize.snap_to_grid
  end
end

class Hero < Entity
  def sprite
    "@"
  end

  def step hero
    # Hero takes input directly
  end

  def left;  pos.x -= 1; end
  def right; pos.x += 1; end
  def up;    pos.y -= 1; end
  def down;  pos.y += 1; end

  def upleft;     pos.x -= 1; pos.y -= 1; end
  def upright;    pos.x += 1; pos.y -= 1; end
  def downleft;   pos.x -= 1; pos.y += 1; end
  def downright;  pos.x -= 1; pos.y += 1; end
end

class GameState
  attr_reader :entities, :hero

  def initialize
    @entities = []
    @entities << Rat.new(Vec.new(0,0))
    @hero = Hero.new Vec.new(3,2)
    @entities << @hero
  end

  def step
    entities.each do |entity|
      entity.step hero
    end
  end

  def left
    hero.left
  end

  def right
    hero.right
  end

  def up
    hero.up
  end

  def down
    hero.down
  end
end

class KeyboardUI
  attr_reader :state

  def initialize state
    @state = state
  end

  def handle_input
    input = get_input

    state.left  if input == "h"
    state.down  if input == "j"
    state.up    if input == "k"
    state.right if input == "l"

    exit() if input == "q"
  end

  def get_input
    STDIN.getch
  end
end

class Game
  attr_reader :state, :display, :ui
  def initialize state, display, ui
    @state = state.new
    @display = display.new @state
    @ui = ui.new @state
  end

  def run
    loop do
      ui.handle_input
      state.step
      display.draw
    end
  end
end

game = Game.new GameState, Term, KeyboardUI
game.run
