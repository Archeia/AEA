#==============================================================================
# ■ Custom Battlelog 
# Ver 1.0
#------------------------------------------------------------------------------
# Have custom text for your battle logs!
#------------------------------------------------------------------------------
# Instructions:
#------------------------------------------------------------------------------
# Go to line 49 and start adding battle log messages!
# <battle log type: CUSTOM>
#
# You can even add stuff like color text (\\c[n]), \n for line break, and conditions like game_switches
# by following how you would do them in Battle Formulas.
# text = user.name + " attacks " + target.name + " with the force of " + "#{$game_switches[6] ? "her" : "his"}" + " fist."
#------------------------------------------------------------------------------
# Author: Dr. Yami
#         Archeia
#------------------------------------------------------------------------------
# April 17, 2015 - Initial Release
#==============================================================================

class Window_BattleLog < Window_Selectable
  
  def custom_text(subject, target, item)
    # initialize - don't touch these
    user     = subject
    hit      = target.result.hit? rescue true
    success  = target.result.success rescue true
    critical = target.result.critical rescue false
    missed   = target.result.missed rescue false
    evaded   = target.result.evaded rescue false
    hp_dam   = target.result.hp_damage rescue 0
    mp_dam   = target.result.mp_damage rescue 0
    tp_dam   = target.result.tp_damage rescue 0
    added_states   = target.result.added_state_objects rescue []
    removed_states = target.result.removed_state_objects rescue []
    text = ""
    type = item.log_type.upcase

    #-------------------------------------------------------------------------------
    # Log Configuration
    #-------------------------------------------------------------------------------
    # Note: Must be REGEXP or the Strings must be in upper case. 
    #-------------------------------------------------------------------------------
    case type
    # ====================================
    # Insert custom Battle log here!
    # ====================================
    when "HEAL" 
      text = user.name + " \\C[10]tends\\C[0] " + target.name + "'s wounds."
    when "TAKEADVANTAGE"
      text = user.name + " \\C[10]takes advantage of\\C[0] " + target.name + "'s emotions\n"
      text = "and steals their money!"
    # ====================================
    # Don't erase this! VVVV
    # ====================================      
    end
    return text
  end
  
end # Window_BattleLog

#-------------------------------------------------------------------------------
# * Core part
#-------------------------------------------------------------------------------

module DataManager
  
  class <<self; alias load_database_cblt load_database; end
  def self.load_database
    load_database_cblt
    load_notetags_cblt
  end
  
  def self.load_notetags_cblt
    $data_skills.each { |obj|
      next if obj.nil?
      obj.load_notetags_cblt
    }
  end
  
end # DataManager

class RPG::BaseItem
  
  attr_reader :log_type

  def load_notetags_cblt
    @log_type = nil
    #---
    self.note.split(/[\r\n]+/).each { |line|
      case line
      when /<battle log type:[ ]*(.*)>/i
        @log_type = $1.upcase
      end
    }
  end
  
end # RPG::BaseItem

class Window_BattleLog < Window_Selectable
  
  def display_custom_text(subject, target, item)
    return unless subject
    return unless item
    return unless item.log_type
    text = custom_text(subject, target, item)
    if text != ""
      add_text(text)
      wait
      cblt_display_action_results(target, item) # Archeia Note: Remove me later
    end
  end
  
  alias cblt_display_use_item display_use_item
  def display_use_item(subject, item)
    return if item.log_type
    cblt_display_use_item(subject, item)
  end
  
  alias cblt_display_action_results display_action_results
  def display_action_results(target, item)
    return if item.log_type
    cblt_display_action_results(target, item)
  end
 
  alias cblt_add_text add_text
  def add_text(text)
    text.split(/[\r\n]+/).each { |line|
      cblt_add_text(line)
    }
  end
  
end # Window_BattleLog

class Scene_Battle < Scene_Base
  
  def apply_item_effects(target, item)
    if $imported["YEA-LunaticObjects"]
      lunatic_object_effect(:prepare, item, @subject, target)
    end
    target.item_apply(@subject, item)
    status_redraw_target(@subject)
    status_redraw_target(target) unless target == @subject
    @log_window.display_action_results(target, item)
    @log_window.display_custom_text(@subject, target, item)
    if $imported["YEA-LunaticObjects"]
      lunatic_object_effect(:during, item, @subject, target)
    end
    perform_collapse_check(target)
  end
  
end # Scene_Battle