#==============================================================================
# ■ Advanced AI Conditions
# Ver 1.0b
#------------------------------------------------------------------------------
# Author: Archeia
#------------------------------------------------------------------------------
# March 01, 2015    - Fixed "Ally" targeting. 
# November 21, 2012 - Started and Finished Script.
#==============================================================================

$imported = {} if $imported.nil?
$imported['ARC-AdvAIConditions'] = true

=begin
#------------------------------------------------------------------------------
#  ▼ INTRODUCTION
#------------------------------------------------------------------------------

This script allows the developper to exert better control on how the AI
handles the enemies' action patterns. Script configuration is almost entirely
made via noteboxes and no RGSS3 knowledge is required to use it.

#------------------------------------------------------------------------------
#  ▼ INSTRUCTIONS
#------------------------------------------------------------------------------

PART 1: DEFAULT AI CONFIGURATION

- TGR settings

TGR determine the frequency a target will be chosen during random targeting
rolls. The configuration module below allows you to set how damage and
healing affects TGR to make a character more threatening to the eyes of
the AI.

- Skill settings

Every skill can be given default AI *targeting* conditions all enemies will use.
To do it, you have to create an "AI block" in the skill's notebox.

Notetags explanation:

<ai_conditions>
Explanation: You always start the block with this one.

target_hpgt: n
Explanation: The target HP must be greater or equal to n%.

target_hplt: n
Explanation: The target HP must be lesser or equal to n%.

target_states: n, n...
Explanation: The target must have the specified states already inflicted.

target_states_not: n, n...
Explanation: The target must NOT have the specified states already inflicted.

only_if_target
Explanation: If no suitable target is found, the skill won't be used AT ALL.

</ai_conditions>
Explanation: You always end the block with this one.

PART 2: ENEMY AI CONFIGURATION

On top on a default AI, you can setup individual AI conditions for every
different enemy. In case of conflict with the default targeting AI, these
settings will take precedence.

All these settings make use of the enemy's notebox.

NATE: the term "action index" refers to the order of the action pattern
you enter for enemies in the database. For instance, if your list is like this:

Attack
Fire II
Poison

Attack will be index 1, Fire II will be index 2 and Poison index 3. And so on.

Notetags explanation:

<ai_conditions: n, n...>
Explanation: One way of starting an AI block. n must be an action index and
if you put more than one (separated by comma), the conditions will be applied
to each of them.

<ai_conditions: n, n...> use_id
Explanation: Same as above, but instead of the action index, the skill ID will
be used. n must be a valid skill ID in this case.

switches: n, n...
Condition: designated switches are ON.

variables: x, y, x, y...
Condition: the variables x have the value y.

states: n, n...
Condition: acting enemy is under the every of the designated states.

hpgt: n
Condition: acting enemy has hp greater or equal than n%.

hplt: n
Condition: acting enemy has hp lesser or equal than n%.

mpgt: n
Condition: acting enemy has mp greater or equal than n%.

mplt: n
Condition: acting enemy has mp lesser or equal than n%.

party_level: n
Condition: party level is greater than n.

turns_order: a+bx
Condition: it's exactly like in the database condition for turns.

target_hpgt: n
Condition: The target HP must be greater or equal to n%.

target_hplt: n
Condition: The target HP must be lesser or equal to n%.

target_states: n, n...
Condition: The target must have the specified states already inflicted.

target_states_not: n, n...
Condition: The target must NOT have the specified states already inflicted.

only_if_target
Condition: If no suitable target is found, the skill won't be used AT ALL.

</ai_conditions> 
Explanation: You must end the block with this one.

- Creating Turn Patterns

Turn patterns is a special AI setting which completely replace an action
pattern with another one at the designated turns. During a turn pattern, the
"normal" actions (the ones you entered into the database) won't be taken into
consideration, ever.

You need to create another block to make a Turn Pattern.

<turn_pattern: a+bx>
Used to define the pattern. a is the first turn and b the number of turns after
the first.

skill: a, b
a is the skill id and b the rating.

</turn_pattern>
End the pattern.

NOTE 1: You can put as many skill tags as you want.
NOTE 2: In order to assign conditions to a skill inside a turn pattern, you
have to create a new AI block with that skill's ID.

- Absolute Rating

The absolute rating is a special rating you assign to an action during
databasing your enemy. An action with this rating will take absolute
priority, ignoring all others (even higher ones) provided it can be used.

If you have several actions with an absolute rating, one will be chosen
randomly.

=end

#===========================================================================
# ■ Configuration
#===========================================================================

module ARC
  
  # Actions with this rating will always be selected and ignore the others.
  ABSOLUTE_RATING = 10
  
  # Offensive action: TGR increase per 1% of the enemy's max HP.
  TGR_DAMAGE_RATE = 1.0
  
  # TGR increase per kill.
  TGR_KILL_RATE = 2.5
  
  # TGR increase per healing action.
  TGR_HEAL_RATE = 0.4
  
  # %TGR decrease upon death.
  TGR_DEATH_RATE = 100
  
#===========================================================================
# ■ Notetags definition
#===========================================================================

  module REGEXP
    AI_CONDITIONS_ON = /<ai_conditions:[ ]*(\d+(?:\s*,\s*\d+)*)>/i
    AI_CONDITIONS_OFF = /<\/ai_conditions>/
    AI_SWITCHES = /switches:[ ]*(\d+(?:\s*,\s*\d+)*)/i
    AI_VARIABLES = /variables:[ ]*(\d+(?:\s*,\s*\d+)*)/i
    AI_STATES = /[^target_]states:[ ]*(\d+(?:\s*,\s*\d+)*)/i
    AI_HPGT = /[^target_]hpgt:[ ]*(\d+)/i
    AI_HPLT = /[^target_]hplt:[ ]*(\d+)/i
    AI_MPGT = /mpgt:[ ]*(\d+)/i
    AI_MPLT = /mplt:[ ]*(\d+)/i
    AI_TURNS = /turn_order:[ ]*(\d+)[+](\d+)x/i
    AI_PARTYLV = /party_level:[ ]*(\d+)/i
    AI_TURN_PATTERN_ON = /<turn_pattern:[ ]*(\d+)[+](\d+)x>/i
    AI_TURN_PATTERN_OFF = /<\/turn_pattern>/
    AI_TURN_PATTERN_SKILL = /skill:[ ]*(\d+(?:\s*,\s*\d+)*)/i
    AI_TARGET_HPGT = /target_hpgt:[ ]*(\d+)/i
    AI_TARGET_HPLT = /target_hplt:[ ]*(\d+)/i
    AI_TARGET_STATES = /target_states:[ ]*(\d+(?:\s*,\s*\d+)*)/i
    AI_TARGET_STATES_NOT = /target_states_not:[ ]*(\d+(?:\s*,\s*\d+)*)/i
    AI_TARGET_TRG = /target_tgr:[ ]*(\d+)/i
    AI_TARGET_NEEDED = /only_if_target/i
    AI_CONDITIONS_ON_SKILL = /<ai_conditions>/i
  end
  
end

#===========================================================================
# ■ DataManager
#===========================================================================

module DataManager  
  #--------------------------------------------------------------------------
  # ● Loads the database
  #--------------------------------------------------------------------------
  class << self; alias_method(:arc_advai_dm_ld, :load_database); end
  def self.load_database
    arc_advai_dm_ld
    $data_enemies.each do |enn|
      next if enn.nil?
      enn.load_advai_notetags
    end
    $data_skills.each do |sk|
      next if sk.nil?
      sk.load_advai_notetags
    end
  end
end

#===========================================================================
# ■ RPG::Enemy
#===========================================================================

class RPG::Enemy < RPG::BaseItem
  #--------------------------------------------------------------------------
  # ● Public instance variables
  #--------------------------------------------------------------------------
  attr_reader     :tagged_actions
  attr_reader     :t_patterns
  #--------------------------------------------------------------------------
  # ● Loads the note tags
  #--------------------------------------------------------------------------
  def load_advai_notetags
    # Store the standard action conditions
    @current_indexes = []
    @tagged_actions = []
    # Store the turn patterns
    @t_patterns = {}
    # Read the notetags
    @note.split(/[\r\n]+/).each do |line|
      case line
      # Starter
      when ARC::REGEXP::AI_CONDITIONS_ON
        @current_indexes.clear
        @enable_ai_tags = true
        @temp_conditions = {}
        $1.scan(/\d+/).each do |i| 
          @current_indexes.push(i.to_i)
        end
        if (line =~ /use_id/i) != nil
          @temp_conditions[:use_id] = true
        end
      # Switches
      when ARC::REGEXP::AI_SWITCHES
        if @enable_ai_tags
          @temp_conditions[:switches] = []
          $1.scan(/\d+/).each {|i| @temp_conditions[:switches].push(i.to_i)}
        end
      # Variables
      when ARC::REGEXP::AI_VARIABLES
        if @enable_ai_tags
          @temp_conditions[:variables] = []
          $1.scan(/\d+/).each {|i| @temp_conditions[:variables].push(i.to_i)}
        end
      # States
      when ARC::REGEXP::AI_STATES
        if @enable_ai_tags
          @temp_conditions[:states] = []
          $1.scan(/\d+/).each {|i| @temp_conditions[:states].push(i.to_i)}
        end
      # Party level
      when ARC::REGEXP::AI_PARTYLV
        if @enable_ai_tags
          @temp_conditions[:partylv] = $1.to_i
        end
      # HP Greater than
      when ARC::REGEXP::AI_HPGT
        if @enable_ai_tags
          @temp_conditions[:hpgt] = $1.to_i
        end
      # HP Lesser than
      when ARC::REGEXP::AI_HPLT
        if @enable_ai_tags
          @temp_conditions[:hplt] = $1.to_i
        end
      # MP Greater than
      when ARC::REGEXP::AI_MPGT
        if @enable_ai_tags
          @temp_conditions[:mpgt] = $1.to_i
        end
      # MP Lesser than
      when ARC::REGEXP::AI_MPLT
        if @enable_ai_tags
          @temp_conditions[:mplt] = $1.to_i
        end
      # Turns
      when ARC::REGEXP::AI_TURNS
        if @enable_ai_tags
          @temp_conditions[:turns] = [$1.to_i, $2.to_i]
        end
      # Target HP Greater than
      when ARC::REGEXP::AI_TARGET_HPGT
        if @enable_ai_tags
          @temp_conditions[:t_hpgt] = $1.to_i
        end
      # Target HP Lesser than
      when ARC::REGEXP::AI_TARGET_HPLT
        if @enable_ai_tags
          @temp_conditions[:t_hplt] = $1.to_i
        end
      # Target under states
      when ARC::REGEXP::AI_TARGET_STATES
        if @enable_ai_tags
          @temp_conditions[:t_states] = []
          $1.scan(/\d+/).each {|i| @temp_conditions[:t_states].push(i.to_i)}
        end
      # Target not under states
      when ARC::REGEXP::AI_TARGET_STATES_NOT
        if @enable_ai_tags
          @temp_conditions[:t_states_not] = []
          $1.scan(/\d+/).each {|i| @temp_conditions[:t_states_not].push(i.to_i)}
        end
      # Target conditions must absolutely be fullfilled
      when ARC::REGEXP::AI_TARGET_NEEDED
        if @enable_ai_tags
          @temp_conditions[:t_absoluteneed] = true
        end
      # End
      when ARC::REGEXP::AI_CONDITIONS_OFF
        @enable_ai_tags = false
        @current_indexes.each {|i| @tagged_actions[i] = @temp_conditions.dup}
        @temp_conditions = nil
      # Turn patterns on
      when ARC::REGEXP::AI_TURN_PATTERN_ON
        @current_indexes.clear
        @current_indexes.push($1.to_i, $2.to_i)
        @pat_index = @current_indexes.dup
        @enable_pattern_tags = true
        @t_patterns[@pat_index] = []
      # Skills and ratings
      when ARC::REGEXP::AI_TURN_PATTERN_SKILL
        if @enable_pattern_tags
          skill_data = []
          $1.scan(/\d+/).each {|i| skill_data.push(i.to_i)}
          @t_patterns[@pat_index].push(skill_data)
        end
      # Turn patterns off
      when ARC::REGEXP::AI_TURN_PATTERN_OFF
        @enable_pattern_tags = false
      end
    end
  end
end

#===========================================================================
# ■ RPG::Skill
#===========================================================================

class RPG::Skill < RPG::UsableItem
  #--------------------------------------------------------------------------
  # ● Public instance variables
  #--------------------------------------------------------------------------
  attr_reader     :target_conditions
  #--------------------------------------------------------------------------
  # ● Loads the note tags
  #--------------------------------------------------------------------------
  def load_advai_notetags
    # Store the targeting conditions
    @target_conditions = {}
    # Read the notetags
    @note.split(/[\r\n]+/).each do |line|
      case line
      # Starter
      when ARC::REGEXP::AI_CONDITIONS_ON_SKILL
        @enable_ai_tags = true
      # Target HP Greater than
      when ARC::REGEXP::AI_TARGET_HPGT
        if @enable_ai_tags
          @target_conditions[:t_hpgt] = $1.to_i
        end
      # Target HP Lesser than
      when ARC::REGEXP::AI_TARGET_HPLT
        if @enable_ai_tags
          @target_conditions[:t_hplt] = $1.to_i
        end
      # Target under states
      when ARC::REGEXP::AI_TARGET_STATES
        if @enable_ai_tags
          @target_conditions[:t_states] = []
          $1.scan(/\d+/).each {|i| @target_conditions[:t_states].push(i.to_i)}
        end
      # Target not under states
      when ARC::REGEXP::AI_TARGET_STATES_NOT
        if @enable_ai_tags
          @target_conditions[:t_states_not] = []
          $1.scan(/\d+/).each {|i| @target_conditions[:t_states_not].push(i.to_i)}
        end
      # Target conditions must absolutely be fullfilled
      when ARC::REGEXP::AI_TARGET_NEEDED
        if @enable_ai_tags
          @target_conditions[:t_absoluteneed] = true
        end
      # End
      when ARC::REGEXP::AI_CONDITIONS_OFF
        @enable_ai_tags = false
      end
    end
  end
end

#===========================================================================
# ■ Game_Enemy
#===========================================================================

class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # ● Determine if the conditions for a battle action are met
  #--------------------------------------------------------------------------
  alias_method(:arc_advai_ge_cm?, :conditions_met?)
  def conditions_met?(action)
    if enemy.actions.index(action) != nil
      ind = enemy.actions.index(action) + 1
    else
      ind = 999
    end
    if enemy.tagged_actions[ind] != nil
      return advanced_ai_conditions_met?(action, enemy.tagged_actions[ind])
    elsif enemy.tagged_actions[action.skill_id] != nil &&
    enemy.tagged_actions[action.skill_id][:use_id]
      return advanced_ai_conditions_met?(action,
      enemy.tagged_actions[action.skill_id])
    end
    return false if valid_target_unavailable?(action, nil)
    return arc_advai_ge_cm?(action)
  end
  #--------------------------------------------------------------------------
  # ● Determine if the advanced conditions are met
  #--------------------------------------------------------------------------
  def advanced_ai_conditions_met?(action, conditions)
    # Check for switches conditions
    sws = conditions[:switches] if conditions.keys.include?(:switches)
    if !sws.nil? && !sws.empty?
      sws.each do |i|
        unless conditions_met_switch?(i, false)
          return false
        end
      end
    end
    # Check for variables conditions
    sws = nil
    sws = conditions[:variables] if conditions.keys.include?(:variables)
    if !sws.nil? && !sws.empty?
      sws.each_index do |i|
        next if i % 2 != 0
        unless $game_variables[sws[i]] >= sws[i+1]
          return false
        end
      end
    end
    # Check for states
    sws = nil
    sws = conditions[:states] if conditions.keys.include?(:states)
    if !sws.nil? && !sws.empty?
      sws.each do |i|
        unless conditions_met_state?(i, false)
          return false
        end
      end
    end
    # Check for party level
    sws = nil
    sws = conditions[:partylv] if conditions.keys.include?(:partylv)
    if !sws.nil?
      return false unless conditions_met_party_level?(sws, false)
    end
    # Check for HP >= than
    sws = nil
    sws = conditions[:hpgt] if conditions.keys.include?(:hpgt)
    if !sws.nil?
      return false unless (hp_rate >= (sws / 100.0))
    end
    # Check for HP <= than
    sws = nil
    sws = conditions[:hplt] if conditions.keys.include?(:hplt)
    if !sws.nil?
      return false unless (hp_rate <= (sws / 100.0))
    end
    # Check for MP >= than
    sws = nil
    sws = conditions[:mpgt] if conditions.keys.include?(:mpgt)
    if !sws.nil?
      return false unless (mp_rate >= (sws / 100.0))
    end
    # Check for MP <= than
    sws = nil
    sws = conditions[:mplt] if conditions.keys.include?(:mplt)
    if !sws.nil?
      return false unless (mp_rate <= (sws / 100.0))
    end
    # Check for turns
    sws = nil
    sws = conditions[:turns] if conditions.keys.include?(:turns)
    if !sws.nil? && !sws.empty?
      sws.each_index do |i|
        next if i % 2 != 0
        unless conditions_met_turns?(sws[i], sws[i+1])
          return false
        end
      end
    end
    # Fails if the AI needs a particular kind of target and it isn't here
    return false if valid_target_unavailable?(action, conditions)
    # Conditions met!
    true
  end
  #--------------------------------------------------------------------------
  # ● Select an action
  #--------------------------------------------------------------------------
  def make_actions
    super
    return if @actions.empty?
    action_list = enemy.actions.select {|a| action_valid?(a) }
    # Process turn patterns
    unless enemy.t_patterns.keys.empty?
      if turn_patterns_ok?
        action_list = make_turn_patterns_list.select {|a| action_valid?(a)}
      end
    end
    # End Process turn patterns
    return if action_list.empty?
    # Process absolute rating
    absolute_list = action_list.reject {|a| a.rating != ARC::ABSOLUTE_RATING}
    unless absolute_list.empty?
      @actions.each do |action|
        action.set_enemy_action(absolute_list[rand(absolute_list.size)])
      end
      return
    end
    # Normal method end
    rating_max = action_list.collect {|a| a.rating }.max
    rating_zero = rating_max - 3
    action_list.reject! {|a| a.rating <= rating_zero }
    @actions.each do |action|
      action.set_enemy_action(select_enemy_action(action_list, rating_zero))
    end
  end
  #--------------------------------------------------------------------------
  # ● Determine if a turn pattern is applicable this time
  #--------------------------------------------------------------------------
  def turn_patterns_ok?
    #puts enemy.t_patterns
    enemy.t_patterns.each_key do |key|
      if conditions_met_turns?(key[0], key[1])
        @tpattern = enemy.t_patterns[key]
        return true
      end
    end
    false
  end
  #--------------------------------------------------------------------------
  # ● Select an action list based on the turn patterns tags
  #--------------------------------------------------------------------------
  def make_turn_patterns_list
    new_list = []
    data = @tpattern
    data.each_index do |i|
      new_list[i] = RPG::Enemy::Action.new
      new_list[i].skill_id = data[i][0]
      new_list[i].rating = data[i][1]
    end
    new_list
  end
  #--------------------------------------------------------------------------
  # ● Determine if no target suits the AI selection
  #--------------------------------------------------------------------------
  def valid_target_unavailable?(action, conditions)
    if action.skill_id > 0 &&
    $data_skills[action.skill_id].target_conditions[:t_absoluteneed] == false
      return false
    end
    return false if conditions != nil && conditions[:t_absoluteneed] == false
    if action.skill_id > 0 &&
    $data_skills[action.skill_id].target_conditions[:t_absoluteneed] == false
      return false
    end
    test_action = Game_Action.new(self, false)
    test_action.set_enemy_action(action)
    return true if test_action.make_targets.nil?
    false
  end
end

#==============================================================================
# ■ Game_Action
#==============================================================================

class Game_Action
  #--------------------------------------------------------------------------
  # ● Public instance variables
  #--------------------------------------------------------------------------
  attr_accessor   :t_conditions
  #--------------------------------------------------------------------------
  # ● Clears the last action
  #--------------------------------------------------------------------------
  alias_method(:arc_advai_ga_clear, :clear)
  def clear
    arc_advai_ga_clear
    @t_conditions = {}
  end
  #--------------------------------------------------------------------------
  # ● Saves the selected action
  #--------------------------------------------------------------------------
  alias_method(:arc_advai_ga_sea, :set_enemy_action)
  def set_enemy_action(action)
    arc_advai_ga_sea(action)
    write_target_conditions(action)
  end
  #--------------------------------------------------------------------------
  # ● Saves the selected action targeting conditions
  #--------------------------------------------------------------------------
  def write_target_conditions(action)
    if action
      if @subject.is_a?(Game_Enemy)
        if @subject.enemy.actions.index(action) != nil
          ind = @subject.enemy.actions.index(action) + 1
        else
          ind = 999
        end
        if @subject.enemy.tagged_actions[ind] != nil
          cont = @subject.enemy.tagged_actions[ind]
        elsif @subject.enemy.tagged_actions[action.skill_id] != nil &&
        @subject.enemy.tagged_actions[action.skill_id][:use_id]
          cont = @subject.enemy.tagged_actions[action.skill_id]
        elsif action.skill_id > 0  &&
        !$data_skills[action.skill_id].target_conditions.keys.empty?
          cont = $data_skills[action.skill_id].target_conditions
        end
        if cont != nil
          cont.each_key do |key|
            if key.to_s.include?('t_')
              @t_conditions[key] = cont[key]
            end
          end
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● Selects a hostile target
  #--------------------------------------------------------------------------
  alias_method(:arc_advai_ga_tfo, :targets_for_opponents)
  def targets_for_opponents
    unless @t_conditions.keys.empty?
      return targets_for_opponents_advai
    end
    arc_advai_ga_tfo
  end
  #--------------------------------------------------------------------------
  # ● Selects a hostile target
  #--------------------------------------------------------------------------
  alias_method(:arc_advai_ga_tff, :targets_for_friends)
  def targets_for_friends
    unless @t_conditions.keys.empty?
      return targets_for_friends_advai
    end
    arc_advai_ga_tff
  end
  #--------------------------------------------------------------------------
  # ● Selects a hostile target (special conditions)
  #--------------------------------------------------------------------------
  def targets_for_opponents_advai
    if item.for_random?
      Array.new(item.number_of_targets) { opponents_unit.random_target }
    elsif item.for_one?
      num = 1 + (attack? ? subject.atk_times_add.to_i : 0)
      if @target_index < 0
        # Lists the opponents
        pool = opponents_unit.alive_members.dup
        # HP greater of equal than
        if @t_conditions[:t_hpgt] != nil
          pool.reject! {|a| (a.hp_rate >= (@t_conditions[:t_hpgt] / 100.0))}
        end
        # HP lesser of equal than
        if @t_conditions[:t_hplt] != nil
          pool.reject! {|a| (a.hp_rate <= (@t_conditions[:t_hplt] / 100.0))}
        end
        # States present
        if @t_conditions[:t_states] != nil
          @t_conditions[:t_states].each do |i|
            pool.reject! {|a| !a.state?(i)}
          end
        end
        # States not present
        if @t_conditions[:t_states_not] != nil
          @t_conditions[:t_states_not].each do |i|
            pool.reject! {|a| a.state?(i)}
          end
        end
        if pool.empty? && !@t_conditions[:t_absoluteneed]
          [opponents_unit.random_target] * num
        elsif pool.empty?
          nil
        else
          [pool[rand(pool.size)]] * num
        end
      else
        [opponents_unit.smooth_target(@target_index)] * num
      end
    else
      opponents_unit.alive_members
    end
  end
  #--------------------------------------------------------------------------
  # ● Selects a friendly target (special conditions)
  #--------------------------------------------------------------------------
  def targets_for_friends_advai
    if item.for_user?
      [subject]
    elsif item.for_dead_friend?
      if item.for_one?
        [friends_unit.smooth_dead_target(@target_index)]
      else
        friends_unit.dead_members
      end
    elsif item.for_friend?
      if item.for_one?
        num = 1 + (attack? ? subject.atk_times_add.to_i : 0)
        # Lists the opponents
        pool = friends_unit.alive_members.dup
        # HP greater of equal than
        if @t_conditions[:t_hpgt] != nil
          pool.reject! {|a| (a.hp_rate >= (@t_conditions[:t_hpgt] / 100.0))}
        end
        # HP lesser of equal than
        if @t_conditions[:t_hplt] != nil
          pool.reject! {|a| (a.hp_rate <= (@t_conditions[:t_hplt] / 100.0))}
        end
        # States present
        if @t_conditions[:t_states] != nil
          @t_conditions[:t_states].each do |i|
            pool.reject! {|a| !a.state?(i)}
          end
        end
        # States not present
        if @t_conditions[:t_states_not] != nil
          @t_conditions[:t_states_not].each do |i|
            pool.reject! {|a| a.state?(i)}
          end
        end
        if pool.empty? && !@t_conditions[:t_absoluteneed]
          [opponents_unit.random_target] * num
        elsif pool.empty?
          nil
        else
          [friends_unit.random_target] * num
        end
      else
        [friends_unit.smooth_target(@target_index)] * num
      end
      else
        friends_unit.alive_members
      end
    end
end
#==============================================================================
# ■ Game_Battler
#==============================================================================

class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● Calculates damage inflicted
  #--------------------------------------------------------------------------
  alias_method(:arc_advai_gb_mdv, :make_damage_value)
  def make_damage_value(user, item)
    arc_advai_gb_mdv(user, item)
    update_tgr(user)
  end
  #--------------------------------------------------------------------------
  # ● Updates the tgr value
  #--------------------------------------------------------------------------
  def update_tgr(user)
    if self.is_a?(Game_Enemy) && user.is_a?(Game_Actor)
      user.action_tgr += ARC::TGR_DAMAGE_RATE * hp_rate if @result.hp_damage > 0
      if @result.hp_damage >= self.hp
        user.action_tgr += ARC::TGR_KILL_RATE
      end
    elsif self.is_a?(Game_Actor) && user.is_a?(Game_Actor)
      user.action_tgr += ARC::TGR_HEAL_RATE if @result.hp_damage < 0
    elsif self.is_a?(Game_Actor)
      if @result.hp_damage >= hp
        @action_tgr -= @action_tgr * ARC::TGR_DEATH_RATE / 100.0
      end
    end
  end
end

#==============================================================================
# ■ Game_Actor
#==============================================================================

class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # ● Public instance variables
  #--------------------------------------------------------------------------
  attr_accessor     :action_tgr
  #--------------------------------------------------------------------------
  # ● Actor setup
  #--------------------------------------------------------------------------
  alias_method(:arc_advai_ga_setup, :setup)
  def setup(actor_id)
    arc_advai_ga_setup(actor_id)
    @action_tgr = 0.0
  end
  #--------------------------------------------------------------------------
  # ● Determine the TaRget Rate
  #--------------------------------------------------------------------------
  alias_method(:arc_advai_ga_tgr, :tgr)
  def tgr
    orig = arc_advai_ga_tgr
    orig.nil? ? @action_tgr : orig + @action_tgr
  end
end
