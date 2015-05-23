#==============================================================================
# ■ Luna Engine: PTB Patch I
#==============================================================================
# Fixes something, I forgot. Probably reflect.
#==============================================================================

#==============================================================================
# ■ Game_Battler
#==============================================================================

class Game_Battler < Game_BattlerBase

  #--------------------------------------------------------------------------
  # alias method: item_apply
  #--------------------------------------------------------------------------
  alias ptbn_patch_item_apply item_apply
  def item_apply(user, item)
    ptbn_patch_item_apply(user, item)
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