#==============================================================================
# 
# ▼ Yami Engine Symphony - Battle Control
# -- Last Updated: 2012.11.01
# -- Level: Nothing
# -- Requires: n/a
# 
#==============================================================================

$imported = {} if $imported.nil?
$imported["YES-BattleControl"] = true

#==============================================================================
# ▼ Updates
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# 2012.07.30 - Bugfix for Save and Load.
# 2012.07.30 - Bugfix for Large Party.
# 2012.07.09 - Compatible with: Battle PTB.
# 2012.07.05 - Compatible with: Battle TBB.
# 2012.07.04 - Compatible with: Battle CTB.
# 2012.07.01 - Started and Finished Script.
# 
#==============================================================================
# ▼ Introduction
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# This script controls the Battle flow and manages battle mechanism from Yami
# Engine Symphony. This is requirement for Battle Mechanism of Yami Engine 
# Symphony.
# 
#==============================================================================
# ▼ Instructions
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# To install this script, open up your script editor and copy/paste this script
# to an open slot below ▼ Materials/素材 but above ▼ Main. Remember to save.
#
# To change Battle Type (Battle Mechanism) during gameplay, use this script call
#    BattleControl.change_btype(type)
#
#==============================================================================
# ▼ Compatibility
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# This script is made strictly for RPG Maker VX Ace. It is highly unlikely that
# it will run with RPG Maker VX without adjusting.
# 
#==============================================================================

module YES
  module BattleControl
    
    # Set Default Battle.
    DEFAULT_BATTLE_TYPE = :ptbn
    
  end # BattleControl
end # YES

#==============================================================================
# ▼ Editting anything past this point may potentially result in causing
# computer damage, incontinence, explosion of user's head, coma, death, and/or
# halitosis so edit at your own risk.
#==============================================================================

#==============================================================================
# ■ BattleControl
#==============================================================================

module BattleControl
  
  #--------------------------------------------------------------------------
  # setup
  #--------------------------------------------------------------------------
  def self.setup
    @last_size = 0
    @battlers = []
    filter_battlers
    setup_battle
  end
  
  #--------------------------------------------------------------------------
  # filter_battlers
  #--------------------------------------------------------------------------
  def self.filter_battlers
    @last_size = @battlers.size
    @battlers = $game_party.members + $game_troop.members
    @last_size = @last_size == 0 ? @battlers.size : @last_size
  end
  
  #--------------------------------------------------------------------------
  # setup_battle
  #--------------------------------------------------------------------------
  def self.setup_battle
    # Compatible Method.
  end
  
  #--------------------------------------------------------------------------
  # turn_end?
  #--------------------------------------------------------------------------
  def self.turn_end?
    return true
  end
  
  #--------------------------------------------------------------------------
  # turn_end
  #--------------------------------------------------------------------------
  def self.turn_end
    # Compatible Method.
  end
  
  #--------------------------------------------------------------------------
  # correct_battle_type
  #--------------------------------------------------------------------------
  def self.correct_battle_type(type)
    case type
    when :dtb; return :dtb
    when :ctb; return $imported["YES-BattleCTB"] ? :ctb : :dtb
    when :tbb; return $imported["YES-BattleTBB"] ? :tbb : :dtb
    when :ptbn; return $imported["YES-BattlePTBN"] ? :ptbn : :dtb
    when :atb; return $imported["YES-BattleATB"] ? :atb : :dtb
    else; return :dtb
    end
  end
  
  #--------------------------------------------------------------------------
  # battle_type
  #--------------------------------------------------------------------------
  def self.battle_type
    return $game_system.battle_type
  end
  
  #--------------------------------------------------------------------------
  # change_btype
  #--------------------------------------------------------------------------
  def self.change_btype(type)
    $game_system.battle_type = correct_battle_type(type)
  end
  
end # BattleControl

#==============================================================================
# ■ BattleManager
#==============================================================================

module BattleManager
  
  #--------------------------------------------------------------------------
  # alias method: setup
  #--------------------------------------------------------------------------
  class <<self; alias yes_bc_setup setup; end
  def self.setup(troop_id, can_escape = true, can_lose = false)
    yes_bc_setup(troop_id, can_escape, can_lose)
    BattleControl.setup()
  end
  
  #--------------------------------------------------------------------------
  # new method: encounter_flag
  #--------------------------------------------------------------------------
  def self.encounter_flag
    return 1 if @preemptive
    return 2 if @surprise
    return 0
  end
  
  #--------------------------------------------------------------------------
  # new method: set_actor
  #--------------------------------------------------------------------------
  def self.set_actor(actor)
    @actor_index = actor.index
  end
  
end # BattleManager

#==============================================================================
# ■ Game_System
#==============================================================================

class Game_System
  
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :battle_type

  #--------------------------------------------------------------------------
  # alias method: initialize
  #--------------------------------------------------------------------------
  alias yes_bc_initialize initialize
  def initialize
    yes_bc_initialize
    @battle_type = BattleControl.correct_battle_type(YES::BattleControl::DEFAULT_BATTLE_TYPE)
  end
  
end # Game_System

#==============================================================================
# ■ Game_Actor
#==============================================================================

class Game_Actor < Game_Battler
  
  #--------------------------------------------------------------------------
  # Define method :screen_x
  #--------------------------------------------------------------------------
  unless Game_Actor.instance_methods.include?(:screen_x)
  def screen_x
    return self.index
  end
  end
  
end # Game_Actor

#==============================================================================
# ■ Game_Unit
#==============================================================================

class Game_Unit
  
  #--------------------------------------------------------------------------
  # new method: ye_alive_members
  #--------------------------------------------------------------------------
  def ye_alive_members
    self.is_a?(Game_Party) ? battle_members.select {|member| member.alive? } : members.select {|member| member.alive? }
  end
  
  #--------------------------------------------------------------------------
  # new method: ye_movable_members
  #--------------------------------------------------------------------------
  def ye_movable_members
    self.is_a?(Game_Party) ? battle_members.select {|member| member.movable? } : members.select {|member| member.movable? }
  end
  
end # Game_Unit

#==============================================================================
# ■ Scene_Battle
#==============================================================================

class Scene_Battle < Scene_Base
  
  #--------------------------------------------------------------------------
  # overwrite method: update
  #--------------------------------------------------------------------------
  def update
    super
    if BattleManager.in_turn? && process_condition
      process_in_turn
      process_event
      process_action
    end
    BattleManager.judge_win_loss
  end
  
  #--------------------------------------------------------------------------
  # new method: process_in_turn
  #--------------------------------------------------------------------------
  def process_in_turn
    # Compatible Method.
  end
  
  #--------------------------------------------------------------------------
  # new method: process_condition
  #--------------------------------------------------------------------------
  def process_condition
    return true if BattleControl.battle_type == :dtb
  end
  
  #--------------------------------------------------------------------------
  # overwrite method: process_action
  #--------------------------------------------------------------------------
  def process_action
    return if scene_changing?
    if !@subject || !@subject.current_action
      @subject = BattleManager.next_subject
    end
    unless @subject
      return turn_end if BattleControl.turn_end?
      return
    end
    if @subject.current_action
      @subject.current_action.prepare
      if @subject.current_action.valid?
        @status_window.open
        execute_action
      end
      @subject.remove_current_action
    end
    process_action_end unless @subject.current_action
  end
  
  #--------------------------------------------------------------------------
  # alias method: turn_end
  #--------------------------------------------------------------------------
  alias yes_bc_turn_end turn_end
  def turn_end
    return yes_bc_turn_end if BattleControl.battle_type == :dtb
    return unless BattleControl.turn_end?
    while BattleControl.turn_end?
      BattleControl.turn_end
      yes_bc_turn_end
      #---
      turn_start if BattleControl.battle_type == :ctb
      turn_start if BattleControl.battle_type == :tbb
      turn_start if BattleControl.battle_type == :ptbn
      turn_start if BattleControl.battle_type == :atb
    end
  end
  
end # Scene_Battle

#==============================================================================
# 
# ▼ End of File
# 
#==============================================================================