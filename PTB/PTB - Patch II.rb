#==============================================================================
# ■ PTB Patch and Add-Ons
#==============================================================================
# This script fixes the paralysis state and you can still retain a turn.
# 
# Notetagging a weapon or an armour with <PTB_ACTIONS: 3> for example
# it will take the highest value of them as the base amount of turns for that
# actor.
# 
# To add or take away from base:
# <addptbs 1>
# <addptbs -4>
#
# For skill costs
# <ptbs_cost 2>
#==============================================================================

#==============================================================================
# ■ DataManager
#==============================================================================

module DataManager
  
  #--------------------------------------------------------------------------
  # new method: load_notetags_battleptbn
  #--------------------------------------------------------------------------
  def self.load_notetags_battleptbn
    groups = [$data_actors, $data_enemies, $data_skills, $data_items, $data_weapons, $data_armors]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.load_notetags_battleptbn
      end
    end
  end
  
end # DataManager


#==============================================================================
# ■ Game_Battler
#==============================================================================

class Game_Battler < Game_BattlerBase
  
  #--------------------------------------------------------------------------
  # new method: ptbn_actions
  #--------------------------------------------------------------------------
  def ptbn_actions
    return [] if !movable?
    if actor?
      return actor.ptbn_actions
    else
      return enemy.ptbn_actions
    end
  end
  
  #--------------------------------------------------------------------------
  # new method: skill_conditions_met?
  #--------------------------------------------------------------------------
  def skill_conditions_met?(skill)
    return super(skill) && (BattleControl.ptbn_actions.clone - [0]).length >= skill.ptbn_cost
  end
  
  #--------------------------------------------------------------------------
  # alias method: item_apply
  #--------------------------------------------------------------------------
  def item_apply(user, item)
    ptbn_item_apply(user, item)
    return unless user
    return unless SceneManager.scene_is?(Scene_Battle)
    BattleControl.additonal_cost(item.ptbn_cost)
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
  # new method: ptbn_actions
  #--------------------------------------------------------------------------
  def ptbn_actions
    return [] if !movable?
    base = actor.ptbn_actions
    add = 0
    for equip in @equips
      next if equip.object == nil
      base = equip.object.ptbn_actions if equip.object.ptbn_actions.length > base.length
      add += equip.object.addptbs
    end
    if add >= 0
      return base + Array.new(add, 1)
    else
      if base.length <= add * -1
        return []
      else
        return Array.new(base.length + add, 1)
      end
    end
  end
  
end # Game_Actor

#==============================================================================
# ■ Fomar you messed up the formating
#==============================================================================

class RPG::EquipItem
  def addptbs
    if @addptbs.nil?
      if @note =~ /<addptbs (.*)>/i
        @addptbs = $1.to_i
      else
        @addptbs = 0
      end
    end
    @addptbs
  end
end

class RPG::UsableItem
  def ptbn_cost
    if @ptbn_cost.nil?
      if @note =~ /<ptbs_cost (.*)>/i
        @ptbn_cost = $1.to_i
      else
        @ptbn_cost = 1
      end
    end
    @ptbn_cost
  end
end

#==============================================================================
# ■ BattleControl
#==============================================================================

module BattleControl
  
  #--------------------------------------------------------------------------
  # new method: ptbn_evaluate_action
  # Result State:
  # 0 - Normal, 1 - Rewarded, 4 - Evade, 5 - Miss, 2 - Strong, 6 - Absorb
  # 7 - Reflect, 8 - half turn, 9 - instant, 3 - Immunity
  #--------------------------------------------------------------------------
  def self.additonal_cost(cost)
    cost -= 1
    return if cost == 0
    @ptbn_actions.each_index { |i| if @ptbn_actions[i] > 0; @ptbn_actions[i] = 0; cost -= 1; break if cost == 0; end }
  end
  
end