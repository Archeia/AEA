#==============================================================================
# ■ Luna Engine: PTB Pass Command Fix
#==============================================================================
# Put this below Yanfly Engine Ace - Battle Command List
#==============================================================================

class Scene_Battle < Scene_Base
  
  def command_use_skill
    @skill = $data_skills[@actor_command_window.current_ext]
    BattleManager.actor.input.set_skill(@skill.id)
    BattleManager.actor.last_skill.object = @skill
    status_redraw_target(BattleManager.actor)
    if $imported["YEA-BattleEngine"]
      $game_temp.battle_aid = @skill
      if @skill.for_opponent?
        select_enemy_selection
      elsif @skill.for_friend? && !@skill.ptbn_pass
        select_actor_selection
      else
        next_command
        $game_temp.battle_aid = nil
      end
    else
      if !@skill.need_selection? || @skill.ptbn_pass
        next_command
      elsif @skill.for_opponent?
        select_enemy_selection
      else
        select_actor_selection
      end
    end
  end
  
end