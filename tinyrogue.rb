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

  def interaction
    raise "entity #{self} needs interactions"
  end

  def default_action state
    raise "entity #{self} needs movement pattern"
  end

  def identifier
    self.class.to_s.downcase.to_sym
  end

  def make_happen action, coords
    self.send action, coords
  end

  def step state
    next_coords = default_action state
    object_moving_into = state.entity_in next_coords
    action = interaction[object_moving_into]

    raise "No action on #{self.class} for #{object_moving_into}" if action.nil?

    make_happen action, next_coords
  end

end

class Rat < Entity
  def sprite
    "r"
  end

  def interaction
    {
      hero:  :attack,
      wall:  :stand_still,
      floor: :move,
    }
  end

  def default_action state
    move_towards state.hero
  end

  def move coords
    self.pos = coords
  end

  def move_towards other
    direction = other.pos - self.pos
    self.pos + direction.normalize.snap_to_grid
  end

  def attack coords
  end
end

class Hero < Entity
  attr_accessor :input_action
  def initialize pos
    @pos = pos

    @input_action = nil
  end

  def sprite
    "@"
  end

  def interaction
    {
      rat:   :attack,
      wall:  :stand_still,
      floor: :move,
    }
  end

  def default_action state
    raise "step taken without user input" if input_action.nil?
    self.send(input_action)
  end

  def move coords
    self.pos = coords
  end

  def attack coords
  end

  def left;  pos + Vec.new(-1,  0); end
  def right; pos + Vec.new( 1,  0); end
  def up;    pos + Vec.new( 0, -1); end
  def down;  pos + Vec.new( 0,  1); end

  def upleft;     pos + Vec.new(-1, -1); end
  def upright;    pos + Vec.new( 1, -1); end
  def downleft;   pos + Vec.new(-1,  1); end
  def downright;  pos + Vec.new( 1,  1); end
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
      entity.step self
    end
  end

  def entity_in coords
    maybe_entities = entities.select do |entity|
      entity.pos == coords
    end

    raise "More than one entity on a tile" unless maybe_entities.count == 0

    if maybe_entities.empty?
      :floor
    else
      maybe_entity = maybe_entities.first
      maybe_entity.identifier
    end
  end

  def left;   hero.input_action = :left; end
  def right;  hero.input_action = :right; end
  def up;     hero.input_action = :up; end
  def down;   hero.input_action = :down; end

  def upleft;    hero.input_action = :upleft; end
  def upright;   hero.input_action = :upright; end
  def downleft;  hero.input_action = :downleft; end
  def downright; hero.input_action = :downright; end
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
    state.upleft    if input == "y"
    state.upright   if input == "u"
    state.downleft  if input == "b"
    state.downright if input == "n"

    state.rest if input == "z"

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
