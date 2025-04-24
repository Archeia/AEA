#==============================================================================
# ■ Call Common Event Command
# Ver 1.0
#------------------------------------------------------------------------------
# Author: Archeia
#------------------------------------------------------------------------------
# April 25, 2025    -  Initial Release
#==============================================================================

module OpinionMenu
  MENU_NAME = "Opinion"       # Name shown in the menu
  COMMON_EVENT_ID = 2         # Common Event ID to call
end

#------------------------------------------------------------------------------
# * Add command to the menu command window
#------------------------------------------------------------------------------
class Window_MenuCommand < Window_Command
  alias add_opinion_command add_original_commands
  def add_original_commands
    add_opinion_command
    add_command(OpinionMenu::MENU_NAME, :opinion)
  end
end

#------------------------------------------------------------------------------
# * Add handler for the new command in Scene_Menu
#------------------------------------------------------------------------------
class Scene_Menu < Scene_MenuBase
  alias opinion_command_window create_command_window
  def create_command_window
    opinion_command_window
    @command_window.set_handler(:opinion, method(:command_opinion))
  end

  def command_opinion
    $game_temp.reserve_common_event(OpinionMenu::COMMON_EVENT_ID)
    SceneManager.call(Scene_Map)
  end
end
