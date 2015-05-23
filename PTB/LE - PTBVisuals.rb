#==============================================================================
# 
# ▼ Luna Engine - Press Turn Battle Add-on
# -- Script: Press Turn Gauge
# -- Last Updated: 2012.07.09
# -- Level: Normal
# -- Requires: n/a
# 
#==============================================================================

$imported = {} if $imported.nil?
$imported["YES-PTBNGauge"] = true

#==============================================================================
# ▼ Updates
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# 2012.07.09 - Started and Finished Script.
# 
#==============================================================================
# ▼ Introduction
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# This script provides a visual for Press Turn of PTB.
#
#==============================================================================
# ▼ Instructions
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# To install this script, open up your script editor and copy/paste this script
# to an open slot below YES - Battle PTB but above ▼ Main. Remember to save.
#
#==============================================================================
# ▼ Compatibility
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# This script is made strictly for RPG Maker VX Ace. It is highly unlikely that
# it will run with RPG Maker VX without adjusting.
# This script only works with YES - Battle PTB.
# 
#==============================================================================

module YES
  module PTBN
    
    #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
    # - Turn Gauge Settings -
    #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
    # These settings are adjusted for the Turn Gauge of PTB.
    #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
    TURN_GAUGE = { # Start.
      :x              =>  40,
      :y              =>  12,
    } # End.
    
  end # PTB
end # YES

#==============================================================================
# ▼ Editting anything past this point may potentially result in causing
# computer damage, incontinence, explosion of user's head, coma, death, and/or
# halitosis so edit at your own risk.
#==============================================================================

#==============================================================================
# ■ Cache
#==============================================================================

module Cache
  
  #--------------------------------------------------------------------------
  # new method: ptb
  #--------------------------------------------------------------------------
  def self.ptb(filename)
    begin
      load_bitmap("Graphics/PTB/", filename)
    end
  end
  
end # Cache

#==============================================================================
# ■ YES::PTB
#==============================================================================

module YES
  module PTB
    SPRITE_WIDTH = Cache.ptb("PartyPTB").width
    SPRITE_HEIGHT = Cache.ptb("TroopPTB").height
    RECT = Rect.new(0, 0, SPRITE_WIDTH, SPRITE_HEIGHT)
  end
end

#==============================================================================
# ■ Sprite_PTBN
#==============================================================================

class Sprite_PTBN < Sprite
  
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize(index, party)
    super(nil)
    @index = index
    @party = party
    @count = 0
    self.opacity = 255
    refresh
  end
  
  #--------------------------------------------------------------------------
  # refresh
  #--------------------------------------------------------------------------
  def refresh
    bitmap_name = @party ? "PartyPTB" : "TroopPTB"
    self.bitmap = Cache.ptb(bitmap_name)
    #---
    self.x = YES::PTBN::TURN_GAUGE[:x]
    self.y = YES::PTBN::TURN_GAUGE[:y]
    self.x += (BattleControl.ptbn_actions.size - @index - 1) * YES::PTB::SPRITE_WIDTH
  end
  
  #--------------------------------------------------------------------------
  # update
  #--------------------------------------------------------------------------
  def update
    return if disposed?
    super
    self.opacity -= 24 if @disposing
    self.dispose if self.opacity <= 0
    return if @disposing
    if BattleControl.ptbn_actions[@index] == 0
      @disposing = true
    elsif BattleControl.ptbn_actions[@index] == 2
      @count -= 1
      if @count <= 0;self.flash(Color.new(255,255,255), 24); @count = 48; end
    end
  end
  
  #--------------------------------------------------------------------------
  # disposing
  #--------------------------------------------------------------------------
  def disposing
    @disposing = true
  end
  
end # Sprite_PTBN

#==============================================================================
# ■ Sprite_PTBN
#==============================================================================

class Spriteset_PTBN
  
  #--------------------------------------------------------------------------
  # refresh
  #--------------------------------------------------------------------------
  def refresh
    @sprites ||= []
    #---
    @sprites.each { |sprite| sprite.disposing }
    #---
    party = BattleControl.ptbn_order == :party ? true : false
    BattleControl.ptbn_actions.each_index { |index|
      sprite = Sprite_PTBN.new(index, party)
      @sprites.push(sprite)
    }
  end
  
  #--------------------------------------------------------------------------
  # update
  #--------------------------------------------------------------------------
  def update
    @sprites.each { |sprite| sprite.update if sprite }
  end
  
  #--------------------------------------------------------------------------
  # dispose
  #--------------------------------------------------------------------------
  def dispose
    @sprites.each { |sprite| sprite.dispose if sprite }
  end
  
  #--------------------------------------------------------------------------
  # disposing
  #--------------------------------------------------------------------------
  def disposing
    @sprites.each { |sprite| sprite.opacity -= 24 if sprite && !sprite.disposed? }
  end
  
end # Spriteset_PTBN

#==============================================================================
# ■ Window_BattleStatusPTBN
#==============================================================================

class Window_BattleStatusPTBN < Window_BattleStatus
  
  #--------------------------------------------------------------------------
  # draw_actor_ptbn
  #--------------------------------------------------------------------------
  def draw_actor_ptbn(actor, x, y, width = 112)
    return unless BattleControl.ptbn_order == :party
    change_color(Color.new(255,160,160))
    draw_text(x, y, width, line_height, BattleControl.ptbn_index(actor), 2)
  end
  
  #--------------------------------------------------------------------------
  # draw_item
  #--------------------------------------------------------------------------
  def draw_item(index)
    return unless BattleManager.in_turn?
    return if index.nil?
    clear_item(index)
    actor = $imported["YEA-BattleEngine"] ? battle_members[index] : $game_party.battle_members[index]
    rect = item_rect(index)
    return if actor.nil?
    width = $imported["YEA-BattleEngine"] ? rect.width-8 : 100
    draw_actor_ptbn(actor, rect.x, rect.y, width)
  end
  
end # Window_BattleStatus

#==============================================================================
# ■ Scene_Battle
#==============================================================================

class Scene_Battle < Scene_Base
  
  #--------------------------------------------------------------------------
  # alias method: create_all_windows
  #--------------------------------------------------------------------------
  alias ptbn_create_all_windows create_all_windows
  def create_all_windows
    create_ptbn_order_gauge
    ptbn_create_all_windows
    create_ptbn_status_window
  end
  
  #--------------------------------------------------------------------------
  # new method: create_ptbn_order_gauge
  #--------------------------------------------------------------------------
  def create_ptbn_order_gauge
    return unless BattleControl.battle_type == :ptbn
    @ptbn_turn_gauge = Spriteset_PTBN.new
    @ptbn_turn_gauge.refresh
  end
  
  #--------------------------------------------------------------------------
  # new method: create_ptbn_status_window
  #--------------------------------------------------------------------------
  def create_ptbn_status_window
    return unless BattleControl.battle_type == :ptbn
    @ptbn_status_window = Window_BattleStatusPTBN.new
    @ptbn_status_window.opacity = 0
    @ptbn_status_window.viewport = @info_viewport
  end
  
  #--------------------------------------------------------------------------
  # alias method: update_basic
  #--------------------------------------------------------------------------
  alias ptbn_update_basic update_basic
  def update_basic
    ptbn_update_basic
    return unless BattleControl.battle_type == :ptbn
    if $game_party.all_dead? || $game_troop.all_dead?
      @ptbn_turn_gauge.disposing
    end
    @ptbn_turn_gauge.update
    @ptbn_status_window.x = @status_window.x
    @ptbn_status_window.y = @status_window.y
    @ptbn_status_window.open if @status_window.open?
    @ptbn_status_window.close if @status_window.close?
  end
  
  #--------------------------------------------------------------------------
  # alias method: dispose_spriteset
  #--------------------------------------------------------------------------
  alias ptbn_dispose_spriteset dispose_spriteset
  def dispose_spriteset
    ptbn_dispose_spriteset
    return unless BattleControl.battle_type == :ptbn
    @ptbn_turn_gauge.dispose
  end
  
end # Scene_Battle

#==============================================================================
# 
# ▼ End of File
# 
#==============================================================================