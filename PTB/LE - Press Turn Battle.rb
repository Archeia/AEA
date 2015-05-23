#==============================================================================
# 
# ▼ Luna Engine - Battle Mechanism
# -- Type: Press Turn Battle (SMT: Nocturne)
# -- Last Updated: 04/01/2015
# -- Level: Normal
# -- Requires: n/a
# -- Made by: Yami
# -- Edited by: Archeia and Fomar0153
#==============================================================================

$imported = {} if $imported.nil?
$imported["YES-BattlePTBN"] = true

#==============================================================================
# ▼ Updates
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# 2015.01.04 - Fixed if paralyzed, that character still has a turn.
#              Added new turn functions.
# 2012.11.01 - Bugfix for a major crash.
# 2012.08.02 - Bugfix for Magic Reflection.
# 2012.07.30 - Bugfix for Large Party.
# 2012.07.09 - Started Script.
# 2012.07.07 - Started Script.
# 
#==============================================================================
# ▼ Introduction
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# This script provides battle mechanism Press Turn Battle (PTB). This PTB based
# from Shin Megami Tensei: Nocturne battle.
#
#==============================================================================
# ▼ Instructions
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# To install this script, open up your script editor and copy/paste this script
# to an open slot below ▼ Materials/素材 but above ▼ Main. Remember to save.
#
# To change Battle Mechanism to PTB, use have to change DEFAULT_BATTLE_TYPE
# in Battle Control to :ptbn or use script call ingame:
#    BattleControl.change_btype(:ptbn)
#
#==============================================================================
# ▼ Compatibility
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# This script is made strictly for RPG Maker VX Ace. It is highly unlikely that
# it will run with RPG Maker VX without adjusting.
# This script may not be compatible with other battle scripts. It is highly
# recommended putting this script above all other battle scripts, except YEA - 
# Ace Battle Engine and other scripts that Author recommends putting above this.
# 
#==============================================================================

module YES
  module PTBN
    
    #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
    # - Mechanism Settings -
    #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
    # These settings are adjusted for the threshold mechanism which related
    # to battlers' actions and turn counting.
    #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
    # The Pass skill must set to use on The User
    # For half turn skill, use <ptb half>
    # For instant skill, use with Yanfly's instant cast 
    # For Beast Eye: <ptb gain: n>
    #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
    MECHANISM_SETTINGS = { # Start.
      :default_ptb    =>  1, # Turns per battler by default.
      #---
      :lose_evade     =>  0,
      :lose_miss      =>  0,
      :lose_strong    =>  0,
      :lose_immunity  =>  1,
      :lose_absorb    =>  99,
      :lose_reflect   =>  99,
    } # End.
    
  end # PTBN
end # YES

#==============================================================================
# ▼ Editting anything past this point may potentially result in causing
# computer damage, incontinence, explosion of user's head, coma, death, and/or
# halitosis so edit at your own risk.
#==============================================================================

#==============================================================================
# ■ Regular Expression
#==============================================================================

module YES
  module REGEXP
  module BATTLER
    
    PTB_ACTIONS = /<(?:PTB_ACTIONS|ptb actions):[ ](\d+)?>/i
    PTB_PASS  = /<(?:PTB_PASS|ptb pass)>/i
    PTB_HALF  = /<(?:PTB_PASS|ptb half)>/i
    PTB_INSTANT = /<(?:PTB_INSTANT|ptb instant)>/i
    PTB_GAIN = /<(?:PTB_GAIN|ptb gain):[ ](\d+)>/i
    
  end # BATTLER
  end # REGEXP
end # YES

#==============================================================================
# ■ DataManager
#==============================================================================

module DataManager
  
  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_battleptbn load_database; end
  def self.load_database
    load_database_battleptbn
    load_notetags_battleptbn
  end
  
  #--------------------------------------------------------------------------
  # new method: load_notetags_battleptbn
  #--------------------------------------------------------------------------
  def self.load_notetags_battleptbn
    groups = [$data_actors, $data_enemies, $data_skills, $data_items]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.load_notetags_battleptbn
      end
    end
  end
  
end # DataManager

#==============================================================================
# ■ RPG::BaseItem
#==============================================================================

class RPG::BaseItem
  
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_accessor :ptbn_actions
  attr_accessor :ptbn_pass
  attr_accessor :ptbn_half
  attr_accessor :ptbn_instant
  attr_accessor :ptbn_gain
  
  #--------------------------------------------------------------------------
  # common cache: load_notetags_battleptbn
  #--------------------------------------------------------------------------
  def load_notetags_battleptbn
    @ptbn_pass = false
    @ptbn_half = false
    @ptbn_instant = false
    @ptbn_gain = 0
    #---
    self.note.split(/[\r\n]+/).each { |line|
      case line
      #---
      when YES::REGEXP::BATTLER::PTB_ACTIONS
        @ptbn_actions = Array.new($1.to_i, 1)
      when YES::REGEXP::BATTLER::PTB_PASS
        @ptbn_pass = true
      when YES::REGEXP::BATTLER::PTB_HALF
        @ptbn_half = true
      when YES::REGEXP::BATTLER::PTB_INSTANT
        @ptbn_instant = true
      when YES::REGEXP::BATTLER::PTB_GAIN
        @ptbn_gain = $1.to_i
      end
    } # self.note.split
    #---
    @ptbn_actions = Array.new(YES::PTBN::MECHANISM_SETTINGS[:default_ptb], 1) if @ptbn_actions.nil?
  end
  
end # RPG::BaseItem

#==============================================================================
# ■ BattleControl
#==============================================================================

module BattleControl
    
  #--------------------------------------------------------------------------
  # Party's Actions
  # Action State: 0 - Used, 1 - Full Action, 2 - Half Action
  #--------------------------------------------------------------------------
    @ptbn_actions = Array.new()

  #--------------------------------------------------------------------------
  # alias method: setup_battle
  #--------------------------------------------------------------------------
  class <<self; alias ptbn_setup_battle setup_battle; end
  def self.setup_battle
    ptbn_setup_battle
    setup_ptbn if battle_type == :ptbn
  end
  
  #--------------------------------------------------------------------------
  # alias method: turn_end?
  #--------------------------------------------------------------------------
  class <<self; alias ptbn_turn_end? turn_end?; end
  def self.turn_end?
    return ptbn_turn_end? unless battle_type == :ptbn
    return turn_end_ptbn? if battle_type == :ptbn
  end
  
  #--------------------------------------------------------------------------
  # alias method: turn_end
  #--------------------------------------------------------------------------
  class <<self; alias ptbn_turn_end turn_end; end
  def self.turn_end
    ptbn_turn_end unless battle_type == :ptbn
    turn_end_ptbn if battle_type == :ptbn
  end
  
  #--------------------------------------------------------------------------
  # new method: turn_end_ptbn?
  #--------------------------------------------------------------------------
  def self.turn_end_ptbn?
    condition = ptbn_all_used
    if @ptbn_order == :party
      condition = condition || $game_party.ye_movable_members.size == 0
    elsif @ptbn_order == :troop
      condition = condition || $game_troop.ye_movable_members.size == 0
    else
      return false
    end    
    return condition
  end
  
  #--------------------------------------------------------------------------
  # new method: turn_end_ptbn
  #--------------------------------------------------------------------------
  def self.turn_end_ptbn
    @ptbn_actions.clear
    @ptbn_order = @ptbn_order == :party ? :troop : :party
    ptbn_calculate_actions
  end
  
  #--------------------------------------------------------------------------
  # new method: setup_ptbn
  #--------------------------------------------------------------------------
  def self.setup_ptbn
    @ptbn_order = nil
    @battlers = []
    #---
    ptbn_init_order
  end
  
  #--------------------------------------------------------------------------
  # new method: ptbn_init_order
  #--------------------------------------------------------------------------
  def self.ptbn_init_order
    party_agi = $game_party.ye_alive_members.inject(0) { |i, b| i += b.agi }
    troop_agi = $game_troop.ye_alive_members.inject(0) { |i, b| i += b.agi }
    #---
    if party_agi > troop_agi
      @ptbn_order = :party
    elsif party_agi < troop_agi
      @ptbn_order = :troop
    else
      @ptbn_order = rand(2) < 1 ? :party : :troop
    end
    #---
    @ptbn_order = :party if BattleManager.encounter_flag == 1
    @ptbn_order = :troop if BattleManager.encounter_flag == 2
    #---
    ptbn_calculate_actions
  end
  
  #--------------------------------------------------------------------------
  # new method: ptbn_calculate_actions
  #--------------------------------------------------------------------------
  def self.ptbn_calculate_actions
    if @ptbn_order == :party
      @ptbn_actions = $game_party.ptbn_actions
      @battlers = $game_party.battle_members.dup
    elsif @ptbn_order == :troop
      @ptbn_actions = $game_troop.ptbn_actions
      @battlers = $game_troop.members.dup
    else
      ptbn_init_order
    end
    #---
    ptbn_sort_battlers
  end
  
  #--------------------------------------------------------------------------
  # new method: ptbn_sort_battlers
  #--------------------------------------------------------------------------
  def self.ptbn_sort_battlers
    @battlers.sort! { |a,b| b.agi <=> a.agi }
  end
  
  #--------------------------------------------------------------------------
  # new method: ptbn_evaluate_action
  # Result State:
  # 0 - Normal, 1 - Rewarded, 4 - Evade, 5 - Miss, 2 - Strong, 6 - Absorb
  # 7 - Reflect, 8 - half turn, 9 - instant, 3 - Immunity
  #--------------------------------------------------------------------------
  def self.ptbn_evaluate_action(state)
    return if state == 9
    case state
    when 10..99
      @ptbn_actions.each_index { |i| if @ptbn_actions[i] > 0; @ptbn_actions[i] = 0; break; end }
      (state - 10).times {
        changed = false
        @ptbn_actions.each_with_index { |s,i|
          next unless s < 1
          @ptbn_actions[i] = 2
          changed = true
          break
        }
        @ptbn_actions.insert(0, 2) unless changed
      }
    when 1
      if ptbn_all_rewarded
        @ptbn_actions.each_index { |i| if @ptbn_actions[i] > 0; @ptbn_actions[i] = 0; break; end }
      else
        @ptbn_actions.each_index { |i| if @ptbn_actions[i] == 1; @ptbn_actions[i] = 2; break; end }
      end
    when 0
      @ptbn_actions.each_index { |i| if @ptbn_actions[i] > 0; @ptbn_actions[i] = 0; break; end }
    when 8
      @ptbn_actions.each_index { |i| 
        if @ptbn_actions[i] == 2
          @ptbn_actions[i] = 0
          break
        elsif @ptbn_actions[i] == 1
          @ptbn_actions[i] = 2
          break
        end
      }
    else
      i = 1
      case state
      when 4
        i += YES::PTBN::MECHANISM_SETTINGS[:lose_evade]
      when 5
        i += YES::PTBN::MECHANISM_SETTINGS[:lose_miss]
      when 2
        i += YES::PTBN::MECHANISM_SETTINGS[:lose_strong]
      when 6
        i += YES::PTBN::MECHANISM_SETTINGS[:lose_absorb]
      when 7
        i += YES::PTBN::MECHANISM_SETTINGS[:lose_reflect]
      when 3
        i += YES::PTBN::MECHANISM_SETTINGS[:lose_immunity]
      end
      j = 0
      @ptbn_actions.each_index { |id| 
        if @ptbn_actions[id] > 0
          @ptbn_actions[id] = 0 
          j += 1
        end 
        break if j >= i
      }
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: ptbn_all_rewarded
  #--------------------------------------------------------------------------
  def self.ptbn_all_rewarded
    result = true
    @ptbn_actions.each { |i| if i == 1; result = false; break; end }
    result
  end
  
  #--------------------------------------------------------------------------
  # new method: ptbn_all_used
  #--------------------------------------------------------------------------
  def self.ptbn_all_used
    result = true
    @ptbn_actions.each { |i| if i > 0; result = false; break; end }
    result
  end
  
  #--------------------------------------------------------------------------
  # new method: ptbn_order
  #--------------------------------------------------------------------------
  def self.ptbn_order
    @ptbn_order
  end
  
  #--------------------------------------------------------------------------
  # new method: ptbn_actions
  #--------------------------------------------------------------------------
  def self.ptbn_actions
    @ptbn_actions
  end
  
  #--------------------------------------------------------------------------
  # new method: ptbn_index
  #--------------------------------------------------------------------------
  def self.ptbn_index(actor)
    @battlers.index(actor) + 1
  end
  
  #--------------------------------------------------------------------------
  # new method: ptbn_clear_actions
  #--------------------------------------------------------------------------
  def self.ptbn_clear_actions
    @ptbn_actions.each_index { |i| @ptbn_actions[i] = 0 }
  end
  
  #--------------------------------------------------------------------------
  # new method: ptbn_sort_battlers
  #--------------------------------------------------------------------------
  def self.ptbn_get_battler
    loop do
      battler = @battlers.shift
      @battlers.push(battler)
      @cur_battler = battler
      return nil if self.turn_end?
      next unless battler.movable?
      return battler
    end
  end
  
end # BattleControl

#==============================================================================
# ■ BattleManager
#==============================================================================

module BattleManager
  
  #--------------------------------------------------------------------------
  # alias method: turn_start
  #--------------------------------------------------------------------------
  class <<self; alias ptbn_turn_start turn_start; end
  def self.turn_start
    ptbn_turn_start unless BattleControl.battle_type == :ptbn
    turn_start_ptbn if BattleControl.battle_type == :ptbn
  end
  
  #--------------------------------------------------------------------------
  # alias method: turn_end
  #--------------------------------------------------------------------------
  class <<self; alias ptbn_turn_end turn_end; end
  def self.turn_end
    ptbn_turn_end unless BattleControl.battle_type == :ptbn
    turn_end_ptbn if BattleControl.battle_type == :ptbn
  end
  
  #--------------------------------------------------------------------------
  # alias method: on_encounter
  #--------------------------------------------------------------------------
  class <<self; alias ptbn_on_encounter on_encounter; end
  def self.on_encounter
    ptbn_on_encounter
    BattleControl.ptbn_init_order if BattleControl.battle_type == :ptbn
  end
  
  #--------------------------------------------------------------------------
  # new method: turn_start_ptbn
  #--------------------------------------------------------------------------
  def self.turn_start_ptbn
    @phase = :turn
    clear_actor
  end
  
  #--------------------------------------------------------------------------
  # new method: turn_end_ptbn
  #--------------------------------------------------------------------------
  def self.turn_end_ptbn
    @phase = :turn_end
    @preemptive = false
    @surprise = false
    $game_troop.increase_turn
  end
  
end # BattleManager

#==============================================================================
# ■ Game_ActionResult
#==============================================================================

class Game_ActionResult
  
  #--------------------------------------------------------------------------
  # Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader :item
  
  #--------------------------------------------------------------------------
  # alias method: make_damage
  #--------------------------------------------------------------------------
  alias ptbn_make_damage make_damage
  def make_damage(value, item)
    ptbn_make_damage(value, item)
    @item = item
  end
  
end # Game_ActionResult

#==============================================================================
# ■ Game_Unit
#==============================================================================

class Game_Unit
  
  #--------------------------------------------------------------------------
  # new method: ptbn_actions
  #--------------------------------------------------------------------------
  def ptbn_actions
    ye_alive_members.inject([]) { |r,b| r += b.ptbn_actions }
  end
  
end # Game_Unit

#==============================================================================
# ■ Game_Battler
#==============================================================================

class Game_Battler < Game_BattlerBase
  
  #--------------------------------------------------------------------------
  # Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :ptbn_state
  
  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias ptbn_initialize initialize
  def initialize
    ptbn_initialize
    @ptbn_state = 0
  end 
  
  #--------------------------------------------------------------------------
  # new method: ptbn_actions
  #--------------------------------------------------------------------------
  def ptbn_actions
    if actor?
      return actor.ptbn_actions
    else
      return enemy.ptbn_actions
    end
  end
  
  #--------------------------------------------------------------------------
  # alias method: item_apply
  #--------------------------------------------------------------------------
  alias ptbn_item_apply item_apply
  def item_apply(user, item)
    ptbn_item_apply(user, item)
    return unless user
    return unless SceneManager.scene_is?(Scene_Battle)
    last_state = user.ptbn_state
    user.ptbn_state = 0
    if item.ptbn_instant
      user.ptbn_state = 9
    elsif item.ptbn_pass || item.ptbn_half
      user.ptbn_state = 8
    elsif item.ptbn_gain > 0
      user.ptbn_state = item.ptbn_gain + 10
    end
    return if item.damage.none? || item.ptbn_pass || item.ptbn_instant
    if @result.missed
      user.ptbn_state = 5
    elsif @result.evaded
      user.ptbn_state = 4
    elsif @result.critical
      user.ptbn_state = 1
    elsif user.magic_reflection
      user.ptbn_state = 7
    elsif item_element_rate(user, @result.item) > 1
      user.ptbn_state = 1
    elsif item_element_rate(user, @result.item) == 0
      user.ptbn_state = 3
    elsif item_element_rate(user, @result.item) < 1 && item_element_rate(user, @result.item) > 0
      user.ptbn_state = 2
    elsif item_element_rate(user, @result.item) < 0
      user.ptbn_state = 6
    end
    user.ptbn_state = [last_state, user.ptbn_state].max if last_state < 8
  end
  
end # Game_Battler

#==============================================================================
# ■ Game_Actor
#==============================================================================

class Game_Actor < Game_Battler
  
  #--------------------------------------------------------------------------
  # alias method: input
  #--------------------------------------------------------------------------
  alias ptbn_input input
  def input
    if BattleControl.battle_type == :ptbn
      if @actions[@action_input_index] == nil
        @actions[@action_input_index] = Game_Action.new(self)
      end
    end
    return ptbn_input
  end
  
end # Game_Actor

#==============================================================================
# ■ Window_ActorCommand
#==============================================================================

class Window_ActorCommand < Window_Command
  
  #--------------------------------------------------------------------------
  # alias method: process_dir6
  #--------------------------------------------------------------------------
  if $imported["YEA-BattleEngine"]
  alias ptbn_process_dir6 process_dir6
  def process_dir6
    return if BattleControl.battle_type == :ptbn
    ptbn_process_dir6
  end
  end
  
end # Window_ActorCommand

#==============================================================================
# ■ Scene_Battle
#==============================================================================

class Scene_Battle < Scene_Base
  
  #--------------------------------------------------------------------------
  # alias method: process_condition
  #--------------------------------------------------------------------------
  alias ptbn_process_condition process_condition
  def process_condition
    return ptbn_process_condition unless BattleControl.battle_type == :ptbn
    return process_condition_ptbn if BattleControl.battle_type == :ptbn
  end
  
  #--------------------------------------------------------------------------
  # alias method: process_in_turn
  #--------------------------------------------------------------------------
  alias ptbn_process_in_turn process_in_turn
  def process_in_turn
    ptbn_process_in_turn unless BattleControl.battle_type == :ptbn
    process_in_turn_ptbn if BattleControl.battle_type == :ptbn
  end
  
  #--------------------------------------------------------------------------
  # alias method: update_info_viewport
  #--------------------------------------------------------------------------
  alias ptbn_update_info_viewport update_info_viewport
  def update_info_viewport
    ptbn_update_info_viewport unless BattleControl.battle_type == :ptbn
    update_info_viewport_ptbn if BattleControl.battle_type == :ptbn
  end
  
  #--------------------------------------------------------------------------
  # alias method: next_command
  #--------------------------------------------------------------------------
  alias ptbn_next_command next_command
  def next_command
    ptbn_next_command unless BattleControl.battle_type == :ptbn
    next_command_ptbn if BattleControl.battle_type == :ptbn
  end
  
  #--------------------------------------------------------------------------
  # alias method: prior_command
  #--------------------------------------------------------------------------
  alias ptbn_prior_command prior_command
  def prior_command
    ptbn_prior_command unless BattleControl.battle_type == :ptbn
    prior_command_ptbn if BattleControl.battle_type == :ptbn
  end
  
  #--------------------------------------------------------------------------
  # alias method: command_fight
  #--------------------------------------------------------------------------
  alias ptbn_command_fight command_fight
  def command_fight
    ptbn_command_fight unless BattleControl.battle_type == :ptbn
    command_fight_ptbn if BattleControl.battle_type == :ptbn
  end
  
  #--------------------------------------------------------------------------
  # alias method: command_escape
  #--------------------------------------------------------------------------
  alias ptbn_command_escape command_escape
  def command_escape
    ptbn_command_escape unless BattleControl.battle_type == :ptbn
    command_escape_ptbn if BattleControl.battle_type == :ptbn
  end
  
  #--------------------------------------------------------------------------
  # alias method: use_item
  #--------------------------------------------------------------------------
  alias ptbn_use_item use_item
  def use_item
    ptbn_use_item
    BattleControl.ptbn_evaluate_action(@subject.ptbn_state) if BattleControl.battle_type == :ptbn
    @ptbn_turn_gauge.refresh if $imported["YES-PTBNGauge"] && @subject.ptbn_state >= 10
    @subject.ptbn_state = 0
  end
  
  #--------------------------------------------------------------------------
  # new method: process_condition_ptbn
  #--------------------------------------------------------------------------
  def process_condition_ptbn
    inputting = @actor_command_window.active || @skill_window.active ||
      @item_window.active || @actor_window.active || @enemy_window.active
    inputting = inputting || @summon_window.active if $imported["YES-GuardianSummon"]
    return !inputting
  end
  
  #--------------------------------------------------------------------------
  # new method: process_in_turn_ptbn
  #--------------------------------------------------------------------------
  def process_in_turn_ptbn
    if @status_window.close?
      @status_window.open
    end
    @actor_command_window.close
    @status_window.unselect
    return if @subject
    #---
    @ptbn_status_window.refresh
    battler = BattleControl.ptbn_get_battler
    return unless battler
    battler.make_actions
    @subject = battler
    #---
    if @subject.inputable? and battler.is_a?(Game_Actor)
      @actor_command_window.setup(@subject)
      BattleManager.set_actor(battler)
      @status_window.select(BattleManager.actor.index)
    end
    @status_window.refresh
  end
  
  #--------------------------------------------------------------------------
  # new method: update_info_viewport_ptbn
  #--------------------------------------------------------------------------
  def update_info_viewport_ptbn
    move_info_viewport(0)   if @party_command_window.active
    move_info_viewport(128) if @actor_command_window.active
    move_info_viewport(64)  if BattleManager.in_turn? && process_condition
  end
  
  #--------------------------------------------------------------------------
  # new method: next_command_ptbn
  #--------------------------------------------------------------------------
  def next_command_ptbn
    @status_window.show
    @actor_command_window.show
    @status_aid_window.hide if $imported["YEA-BattleEngine"]
  end
  
  #--------------------------------------------------------------------------
  # new method: prior_command_ptbn
  #--------------------------------------------------------------------------
  def prior_command_ptbn
    $imported["YEA-BattleEngine"] ? redraw_current_status : @status_window.refresh
    if @subject && @subject.actor?
      @backup_subject = @subject
    end
    command_fight_ptbn
    #start_party_command_selection
  end
  
  #--------------------------------------------------------------------------
  # new method: command_fight_ptbn
  #--------------------------------------------------------------------------
  def command_fight_ptbn
    turn_start
    if @backup_subject
      @subject = @backup_subject
      @actor_command_window.setup(@subject)
      BattleManager.set_actor(@subject)
      @status_window.select(BattleManager.actor.index)
      @backup_subject = nil
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: command_escape_ptbn
  #--------------------------------------------------------------------------
  def command_escape_ptbn
    unless BattleManager.process_escape
      BattleControl.ptbn_clear_actions
      turn_start 
    end
  end
  
  #--------------------------------------------------------------------------
  # alias method: turn_end
  #--------------------------------------------------------------------------
  alias ptbn_turn_end turn_end
  def turn_end
    ptbn_turn_end
    return unless BattleControl.battle_type == :ptbn
    @party_command_window.deactivate
    @ptbn_turn_gauge.refresh if $imported["YES-PTBNGauge"]
  end
  
  def on_skill_ok
    @skill = @skill_window.item
    BattleManager.actor.input.set_skill(@skill.id)
    BattleManager.actor.last_skill.object = @skill
    if !@skill.need_selection? || @skill.ptbn_pass
      @skill_window.hide
      next_command
    elsif @skill.for_opponent?
      select_enemy_selection
    else
      select_actor_selection
    end
  end
  
end # Scene_Battle

#==============================================================================
# 
# ▼ End of File
# 
#==============================================================================