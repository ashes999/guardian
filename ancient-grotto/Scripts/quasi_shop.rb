# Source: http://www.rpgmakervxace.net/topic/22434-quasi-shops/

#==============================================================================#
# ** Quasi Shop v 1.1
#------------------------------------------------------------------------------
# This script generates shops with random items.  Items probability chance can
# be modified with note tags.  Default probability chance is to get set below.
#==============================================================================#
if !$imported["Quasi_Core"].nil?
Quasi.version(1.0,"Quasi_Shop")
if !$quasi["Quasi_Shop"]
  
module Quasi
  module Shop
#==============================================================================#
#                          **Instructions**
#==============================================================================#
# Step 1. Create shops.
#  Change/edit/add values to this hash below.
#     shop_number     => [type, [probability factors]],
#   - shop_number is the value we will use when we open the shop 
#     (should never be the same)
#   - type determains what type of items that shop will sell.
#     Type of shops: 
#      :items         => items only
#      :wep           => weapons only
#      :arm           => armor only
#      :wepnitem      => weapons and items only
#      :armnitem      => armor and items only
#      :wepnarm       => weapons and armor only
#      :all           => items, weapons and armor
#   - probability factors is optional.  These factors can increase the chance
#     of certain items appearing in the shop.
#     Probability Factors:
#      :level         => Probability increases as Avg. Party lvl gets closer to
#                      the item's level rate.
#      ":paramX"      => Needs "" around it! X is equal to the param.  Probability
#                      increases as Avg. Param X gets closer to item's Param X rate.
#                       - 0 = Max Hp
#                       - 1 = Max Mp
#                       - 2 = Atk
#                       - 3 = Def
#                       - 4 = M.Atk
#                       - 5 = M.Def
#                       - 6 = Agi
#                       - 7 = Luk
#      ":variableX"   => Needs "" around it! X is equal to the variable.  Probability
#                      of all items in shop increase by the value the variable equals.
#      ":switchX"     => Needs "" around it! X is equal to the switch.  Probability
#                      of all items in shop increase by SWITCH_RATE (set below).
#  Here's 3 examples of different shops:
#------------------------------------------------------------------------------
    SHOPS          = {
      0            => [:items, [:level]],
      1            => [:wep, [:level]],
      2            => [:arm, [:level]]      
    }
#------------------------------------------------------------------------------
# Step 2. Settings values.
#  These are some constants/ default values.
#------------------------------------------------------------------------------
     # Auto Resets shops with :switch or :variable factors when a switch/variable is changed
    AUTO_RESET     = true
     # Auto Resets shops with :level or :param whenever a character levels up
    AUTO_RESET_LVL = false  # off by default, don't really like this
     # Default item probability rate (Only used if no note tag is set.)
    DEFAULT_RATE   = 10
     # Default item target level (Only used if no note tag is set.)
    DEFAULT_LEVEL  = 50
     # How much to add when Avg.Lvl = Item.Targetlvl
     # More info for this in post/blog.
    LVL_RATE       = 50
     # How much to add when Avg.ParamX = Item.TargetParam
     # More info for this in post/blog.
    PARAM_RATE     = 50
     # Value to add when Switch is on AND shop has ":switchX" factor.
    SWITCH_RATE    = 50
#------------------------------------------------------------------------------
# Step 3. Note Tags!~
#  There's 3 Tags for items/weps/armors
#
#  rate=X         => Where X equals the probability chance for that item to appear.
#                    If item doesn't have this tag, it uses DEFAULT_RATE
#  ratelvl=X      => Where X equals target lvl for that item.
#                    If item doesn't have this tag, it uses DEFAULT_LEVEL
#  rateparam=x0,x1,x2,x3,x4,x5,x6,x7
#                 => ALL values are needed.  It's a bit complicated and messed, sry ):
#                    0-7 = the param value, so x7 = value for LUK 
#  An Example rateparam:
#    rateparam=5000,300,20,50,60,40,21,25
#      Target Params: HP    => 5000
#                     MP    => 300
#                     Atk   => 20
#                     Def   => 50
#                     M.Atk => 60
#                     M.Def => 40
#                     Agi   => 21
#                     Luk   => 25
#                    If rateparam is not set it will use Avg.Param * PARAM_RATE
#                    Which cancles out the other math, and their will be no increase.
#------------------------------------------------------------------------------
# Step 4. Running the Shop
#  To open a shop in game, use a script call:
#   open_shop(shop_number, purchase only?(optional))
#  Shop_number correspondes to the shop_number in the SHOPS hash.
#  purchase only? is either true or false.  It's false by default
# Examples:
#  Open shop 0 with purchase only
#   script call:  open_shop(0, true)
#
#  Open shop 3 without purchase only
#   script call:  open_shop(3)
#
# ** NEW **
#  To reset shops items. (Re-Randomize their stock)
#  Run a script call:
#   reset_shops(mode, x)
#  Mode can be set to
#   :all        => resets all shops (doesn't use x)  *DEFAULT*
#   :level      => resets all shops with :level factor (doesn't use x)
#   :param      => resets all shops with ":paramX" factor (x = param)
#   :variable   => resets all shops with ":variableX" factor (x = variable)
#   :switch     => resets all shops with ":switchX" factor (x = switch)
#   :selected   => resets ONLY x shop
#  Examples:
#   reset_shops  or reset_shops(:all)     => resets all
#   reset_shops(:level)                  => resets all shops with :level factor
#   reset_shops(:switch,5)               => resets all shops with ":switch5" factor
#   reset_shops(:selected,1)             => resets shop 1
#------------------------------------------------------------------------------
# Other Info:
#  To Test an item's probability based on level or param use script call:
#   Quasi::Shop::test_rates(type, id, settings, inc=1, pid = 0)
#  type      => :item, :wep or :armor
#  id        => items id (can be found in database)
#  settings  => :level or :param
#  inc       => how much to inc/decrease per 'test'   (optional, default 1)
#  pid       => Parameter ID, 0 = Max Hp, 1 = Max MP, ect.. (optional, default 0)
#
#  This will generate a list using avg party level/param with the items lvl/param rate.
# Runs 10 times to give 10 outcomes.
#  For an example of this, visit blog or try it out.
#
#==============================================================================#
# By Quasi (http://quasixi.wordpress.com/)
#  - 3/7/14
#==============================================================================#
#   ** Stop! Do not edit anything below, unless you know what you      **
#   ** are doing!                                                      **
#==============================================================================#

    def self.reset_shops(mode=:all, x=0)
      case mode
      when :all
        SHOPS.each do |i|
          $game_system.shop[i[0]] = quasi_products(i[1][0], i[1][1])
        end
      when :level
        SHOPS.each do |i|
          next if i[1][1].nil?
          next unless i[1][1].include?(:level)
          $game_system.shop[i[0]] = quasi_products(i[1][0], i[1][1])
        end
      when :param
        SHOPS.each do |i|
          next if i[1][1].nil?
          next unless i[1][1].any?{|x| x =~ /:param(\d+)/i}
          next if $1.to_i != x
          $game_system.shop[i[0]] = quasi_products(i[1][0], i[1][1])
        end
      when :variable
        SHOPS.each do |i|
          next if i[1][1].nil?
          next unless i[1][1].any?{|x| x =~ /:variable(\d+)/i}
          next if $1.to_i != x
          $game_system.shop[i[0]] = quasi_products(i[1][0], i[1][1])
        end
      when :switch
        SHOPS.each do |i|
          next if i[1][1].nil?
          next unless i[1][1].any?{|x| x =~ /:switch(\d+)/i}
          next if $1.to_i != x
          $game_system.shop[i[0]] = quasi_products(i[1][0], i[1][1])
        end
      when :selected
        $game_system.shop[x] = quasi_products(SHOPS[x][0],SHOPS[x][1])
      end
    end
  
    def self.quasi_products(type, factors)
      goods = []
      until goods != [] do
        case type
        when :items
          items = $data_items
        when :wep
          items = $data_weapons
        when :arm
          items = $data_armors
        when :wepnitem
          items = $data_items + $data_weapons
        when :armnitem
          items = $data_items + $data_armors
        when :wepnarm
          items = $data_weapons + $data_armors
        when :all
          items = $data_items + $data_weapons + $data_armors
        end
      
        items.each do |i|
          next if i.nil?
          if check_rate(i, factors)
            if $data_items.include?(i)
              t = 0
            elsif $data_weapons.include?(i)
              t = 1
            elsif $data_armors.include?(i)
              t = 2
            end
            goods.push([t,i.id,0,0])
          end
        end
      end
      return goods
    end
  
    def self.check_rate(item, factors)
      r = item.rate
      factors = [] if factors.nil?
      if factors.include?(:level)
        r += rate_level(item)
      end
      if factors.any? {|x| x =~ /:param(\d)/i}
        r += rate_param(item, $1.to_i)
      end
      if factors.any? {|x| x =~ /:switch(\d+)/i}
        r += SWITCH_RATE if $game_switches[($1.to_i)]
      end
      if factors.any? {|x| x =~ /:variable(\d+)/i}
        r += $game_variables[($1.to_i)]
      end
      chance = rand(100)
      if chance < r
        return true
      end
      return false
    end
  
    def self.rate_level(item,test=0)
      ilvl = item.ratelvl
      plvl =  $game_party.avg_level + test
      factor = LVL_RATE
      
      exp = Quasi.find_exp(factor, ilvl) # exp = ilvl√factor
      r = exp**plvl
      
      if ilvl < plvl
        r = factor + (plvl-ilvl)/2
      end
      return r
    end
    
    def self.rate_param(item, param,test=0)
      avg = $game_party.avg_param(param) + test
      factor = PARAM_RATE
      pval = item.rateparam[param]
      pval = avg*factor if pval.nil?
      
      exp = Quasi.find_exp(factor, pval)  # exp = pval√factor
      r = exp**avg
      r = factor if pval < avg
      return r
    end
    
    def self.test_rates(type, id, settings, inc=1, pid = 0)
      case type
      when :item
        i = $data_items
      when :arm
        i = $data_armors
      when :wep
        i = $data_weapons
      end
      item = i[id]
      txt = "#{item.name} RateLvl: #{item.ratelvl}\n"
      r = item.rate
      
      case settings
      when :level
        txt += "Avg Player Level: #{$game_party.avg_level} \n\n"
        for i in 0...10
          i *= -inc
          lvl = rate_level(item,i+(5*inc))
          p = $game_party.avg_level
          p += i+5*inc
          txt += "Level: #{p} = #{lvl}\n"
        end
      when :param
        ap = $game_party.avg_param(pid)
        ip = item.rateparam[pid]
        txt += "Avg #{Vocab::param(pid)}:"
        txt += " #{ap} Item Param: #{ip}\n\n"
        for i in 0...10
          i *= -inc
          param = rate_param(item, pid, i+(5*inc))
          p = ap+i+5*inc
          txt += "Param: #{p} = #{param}\n"
        end
      end
      msgbox(sprintf(txt))
    end
  end
end
#==============================================================================
# ** Game_Interpreter
#------------------------------------------------------------------------------
#  An interpreter for executing event commands. This class is used within the
# Game_Map, Game_Troop, and Game_Event classes.
#==============================================================================

class Game_Interpreter
  alias quasi_shop_reset_switches command_121
  alias quasi_shop_reset_variables command_122
  
  #--------------------------------------------------------------------------
  # * Shop Processing
  #--------------------------------------------------------------------------
  def open_shop(index, purchase=false)
    return if $game_party.in_battle
    return if Quasi::Shop::SHOPS[index].nil?
    goods = $game_system.shop[index]
    SceneManager.call(Scene_Shop)
    SceneManager.scene.prepare_q(goods, purchase)
    Fiber.yield
  end
  
  #--------------------------------------------------------------------------
  # * Reset Shops
  # ** Redirects to reset_shop inside quasi module
  #--------------------------------------------------------------------------
  def reset_shops(mode=:all, x=0)
    Quasi::Shop::reset_shops(mode, x)
  end
  
  #--------------------------------------------------------------------------
  # * Control Switches
  #--------------------------------------------------------------------------
  def command_121
    quasi_shop_reset_switches
    return unless Quasi::Shop::AUTO_RESET
    (@params[0]..@params[1]).each do |i|
      reset_shops(:switch,i)
    end
  end
  #--------------------------------------------------------------------------
  # * Control Variables
  #--------------------------------------------------------------------------
  def command_122
    quasi_shop_reset_variables
    return unless Quasi::Shop::AUTO_RESET
    (@params[0]..@params[1]).each do |i|
      reset_shops(:variable, i)
    end
  end
end
#==============================================================================
# ** Scene_Shop
#------------------------------------------------------------------------------
#  This class performs shop screen processing.
#==============================================================================

class Scene_Shop < Scene_MenuBase
  #--------------------------------------------------------------------------
  # * Prepare
  #--------------------------------------------------------------------------
  def prepare_q(goods, purchase_only)
    @goods = goods
    @purchase_only = purchase_only
  end
end

#==============================================================================
# ** Game_System
#------------------------------------------------------------------------------
#  This class handles system data. It saves the disable state of saving and 
# menus. Instances of this class are referenced by $game_system.
#==============================================================================

class Game_System
  alias quasi_shop_init initialize
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :shop           # save forbidden
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    @shop = []
    quasi_shop_init
  end
end
#==============================================================================
# ** Game_Actor
#------------------------------------------------------------------------------
#  This class handles actors. It is used within the Game_Actors class
# ($game_actors) and is also referenced from the Game_Party class ($game_party).
#==============================================================================

class Game_Actor < Game_Battler
  alias quasi_shop_lvl level_up
  #--------------------------------------------------------------------------
  # * Level Up
  #--------------------------------------------------------------------------
  def level_up
    quasi_shop_lvl
    return unless Quasi::Shop::AUTO_RESET_LVL
    p "reset"
    for i in 0..7
      Quasi::Shop::reset_shops(:param,i)
    end
    Quasi::Shop::reset_shops(:level)
  end
end
#==============================================================================
# ** Scene_Title
#------------------------------------------------------------------------------
#  This class performs the title screen processing.
#==============================================================================

class Scene_Title < Scene_Base
  alias quasi_shop_ng command_new_game
  #--------------------------------------------------------------------------
  # * [New Game] Command
  #--------------------------------------------------------------------------
  def command_new_game
    quasi_shop_ng
    Quasi::Shop::reset_shops
  end 
end

#==============================================================================
# ** RPG::BaseItem
#------------------------------------------------------------------------------
# Thanks to Fomar0153 for note tag tutorial
#==============================================================================
class RPG::BaseItem
  def rate
    if @rate.nil?
      if @note =~ /rate=(\d+)/i
        @rate = $1.to_i
      else
        @rate = Quasi::Shop::DEFAULT_RATE
      end
    end
    @rate
  end
  
  def ratelvl
    if @ratelvl.nil?
      if @note =~ /ratelvl=(\d+)/i
        @ratelvl = $1.to_i
      else
        @ratelvl = Quasi::Shop::DEFAULT_LEVEL
      end
    end
    @ratelvl
  end
  
  def rateparam
    if @rateparam.nil?
      if @note =~ /rateparam=(.*)/i
        array = []
        for x in $1.split(",")
          array.push(x.to_i)
        end
        return array
      else
        return []
      end
    end
  end
end

end
else
  msgbox_p "[Quasi_Shop] needs [Quasi_Core] in order to run."
end