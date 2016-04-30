require 'io/console'
require './vec'

BACKGROUND_MAP = <<-MAP
.................
...r.............
.................
.................
.................
.................
.......@.........
.................
MAP

$entity_kinds = []
def parse_map map, gamestate
end

class Term
  MAP_WIDTH = 17
  TRAILING_NEWLINE = 1

  attr_reader :state

  def initialize state
    @state = state

    puts "hjkl to move, q to quit"
  end

  def display_enemy enemy
    "#{enemy.identifier}: #{enemy.health}"
  end

  def hud
    hero = state.hero
    enemies = state.entities - [hero]
    <<-HUD
Health: #{hero.health}
Enemies:
#{enemies.map{ |e| display_enemy e }.join("\n")}
    HUD
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
    puts hud
  end

  def clear
    print "\x1b[2J\x1b[1;1H"
  end
end

class Entity
  attr_reader   :state
  attr_accessor :pos, :health, :attack_power

  def initialize state, pos
    @pos = pos
    @state = state
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
    next_coords = default_action

    if next_coords != pos
      object_moving_into = state.entity_in next_coords
      action = interaction[object_moving_into.identifier]

      if action.nil?
        raise "No action on #{self.identifier} to interact with #{object_moving_into}"
      end

      make_happen action, next_coords
    end
  end

end

class Rat < Entity
  attr_reader :sprite

  def initialize state, pos
    super state, pos

    @health = 20
    @attack_power = 2
    @sprite = "r"
  end

  def interaction
    {
      floor: :move,
      hero:  :attack,
      rat:   :stand_still,
      wall:  :stand_still,
    }
  end

  def default_action
    move_towards state.hero
  end

  def move coords
    self.pos = coords
  end

  def stand_still coords
    coords
  end

  def move_towards other
    direction = other.pos - self.pos
    self.pos + direction.normalize.snap_to_grid
  end

  def attack coords
    state.damage coords, attack_power
  end

  def get_hit damage
    self.health -= damage
  end

  def die
    state.delete_entity self
  end
end

class Floor < Entity
end

class StoneWall < Entity
  def initialize state, pos
    super state, pos

    @health = 1
    @attack_power = 5
    @sprite = "█"

    @input_action = nil
  end
end

class DirtWall < Entity
  def initialize state, pos
    super state, pos

    @health = 1
    @attack_power = 5
    @sprite = "#"

    @input_action = nil
  end
end

class Hero < Entity
  attr_accessor :input_action
  attr_reader :sprite

  def initialize state, pos
    super state, pos

    @health = 40
    @attack_power = 5
    @sprite = "@"

    @input_action = nil
  end

  def interaction
    {
      rat:   :attack,
      wall:  :stand_still,
      floor: :move,
    }
  end

  def default_action
    raise "step taken without user input" if input_action.nil?
    self.send(input_action)
  end

  def move coords
    self.pos = coords
  end

  def attack coords
    state.damage coords, attack_power
  end

  def get_hit damage
    self.health -= damage
  end

  def die
    abort "You died!"
  end

  # Input commands (return a pos)
  def rest; pos; end

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
  attr_reader :entities, :hero, :floor

  def initialize
    @entities = []
    @hero = Hero.new self, Vec.new(3,2)
    @entities << @hero

    @entities << Rat.new(self, Vec.new(0,0))

    @floor = Floor.new self, Vec.new(0,0)
  end

  def delete_entity entity
    entities.delete entity
  end

  def damage coords, damage
    entity = entity_in coords
    entity.get_hit damage
    if entity.health <= 0
      entity.die
    end
  end

  def step
    unless entities[0] == hero
      raise "Hero must be the first entity (in order to move first)"
    end

    entities.each do |entity|
      entity.step self
    end

    world_step
  end

  def world_step
    spawn_enemies
  end

  def spawn_enemies
    if rand < 0.1
      @entities << Rat.new(self, Vec.new(0,0))
    end
  end

  def entity_in coords
    maybe_entities = entities.select do |entity|
      entity.pos == coords
    end

    if maybe_entities.count > 1
      raise "More than one entity on a tile: #{maybe_entities}"
    end

    if maybe_entities.empty?
      floor
    else
      maybe_entities.first
    end
  end

  def left;      hero.input_action = :left; end
  def right;     hero.input_action = :right; end
  def up;        hero.input_action = :up; end
  def down;      hero.input_action = :down; end

  def upleft;    hero.input_action = :upleft; end
  def upright;   hero.input_action = :upright; end
  def downleft;  hero.input_action = :downleft; end
  def downright; hero.input_action = :downright; end

  def rest;      hero.input_action = :rest; end
end

class KeyboardUI
  attr_reader :state

  def initialize state
    @state = state
  end

  def handle_input
    input = get_input

    state.left      if input == "h"
    state.down      if input == "j"
    state.up        if input == "k"
    state.right     if input == "l"
    state.upleft    if input == "y"
    state.upright   if input == "u"
    state.downleft  if input == "b"
    state.downright if input == "n"

    state.rest      if input == "z"

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
