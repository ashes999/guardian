=begin
#==============================================================================#
                         ***Quasi Core v1.01***
 
  Common methods that Quasi scripts will use
  -Small changes to default scripts
#==============================================================================#
#   Change Log
#------------------------------------------------------------------------------
3/16/14 - Version 1.01
-Added New Method
 Quasi::circle(center x, center y, radius, angle)
 # angle ranged from 0 to 2PI (PI = 180, 2PI = 360)
 # Used to move a sprite around in a circle
 # Returns an array [x, y]
 
-Sprite
 # New methods: 
 #  quasi_flash(color,duration,repeat?)
 #   -changes into new color then back to orginal
 #  quasi_color(color,duration)
 #   -changes color to new color within duration
 
-Updated Methods
 Quasi::sprite_efx
 # Added :color, :flash, :expand, :wave(Reworked)
 # Renamed variables
 
 Quasi::sprite_efx_trans
 # Added: :flash, :slide
 # Renamed variables

3/7/14 - Version 1.0
-Released

#------------------------------------------------------------------------------
 
New methods in module
 Quasi::odd?(value)
 # returns if value is odd or even
 
 Quasi::slope(x1,y1,x2,y2,speed)
 #  - Can be used for moving sprites around on a slope
 # returns [slopeX, slopeY]
  - Quasi::normalize (Special thanks to Resource Dragon)
 #   Part of slope.  Normalizes the slope.
   
 Quasi::find_exp(x, nth)
 # Def: y = x^(nth)   <=>  y = nth√x
 # Returns y
 
 
# Following can be called in Window_Base/Scene_Base without 'Quasi::' prefix
 Quasi::sprite_efx_trans(sprite, settings)
 # settings = :zoom, :zoom2, :spin, :fade
 #     :zoom  - zooms the sprite at start, then zooms out to default zoom.
 #     :zoom2 - is for images that are already zoomed and need to be zoomed out
 Quasi::sprite_efx(sprite, settings)
 # settings = :spin, :slidehorz, :slidevert, :slidedia, :wave, :color (incomplete)
 Quasi::draw_qsprite(sprite, symbol, frames, index)
 # symbol = :horz or :vert
 # Splits sprite into X frames either horz or vert.
 # Then moves location to the set index
 
#==============================================================================#
                          Changes to Default Scripts:
#==============================================================================#
Game_Event
ATTR
  attr_reader  :event            # Can grab event name,x,y,id
 
Game_Interpreter
NEW METHODS
 New Variable method.
 Makes variable into an array
 And methods to grab the arrays values.
 ** This aren't to be used as normal variables!
     Only use them with the methods below!
     Unless you know what you are doing.
 
  array(vari,ar,value)
  # Converts $data_variables into an array.
  # Ex
  #  script call: array(1,0,100); array(1,1,50); array(1,2,'string')
  #  would make variable 1 into an array with [100,50,'string']
 
  array_value(vari,ar)
  # Grabs value for selected index.
  # Using the array from first Ex.
  #   script call: array_value(1,0)
  #    returns 100
  #   script call: array(1,2)
  #    returns 'string'
 
  show_array(vari)
  # Shows the whole array.
  # Using the array from first Ex.
  #  script call: show_array(1)
  #   returns [100,50,'string']
 
Window_Base
ALIAS
  alias convert_escape_characters
 
NEW METHODS
  convert_quasi_characters
  # New codes for message box
  #  \VA[variable,index]
  #    - Displays the variable array in message
  #    - Using the earlier Ex from converting a variable to an array
  #       \VA[1,2] would be replaced with 'string'
 
Game_party
NEW METHODS
  lowest_level
  # Returns the lowest lvl in party
 
  who_level(value)
  # Returns the actor/s whose level is equal to the set value
  #  - If multiple actors, it returns an array
 
  avg_level
  # Grabs the average level of party
 
  # param =
  # 0   => mhp
  # 1   => mmp
  # 2   => atk
  # 3   => def
  # 4   => mat
  # 5   => mdf
  # 6   => agi
  # 7   => luk
 
  lowest_param(param)
  # Returns lowest param value from party
 
  highest_param(param)
  # Returns highest param value from party
 
  avg_param(param)
  # Grabs the average value of param of party
 
  who_param(value,x)
  # Returns the actor/s whose param is equal to the set value
  #  - If multiple actors, it returns an array
 
class Game_CharacterBase
NEW METHODS
 fade_in(x)
 # fades in character by x speed
 fade_out(x)
 # fades out character by x speed
 fade?
 # checks if character is fading in/out is complete.
=end
 
$imported = {} if $imported.nil?
$imported["Quasi_Core"] = 1.01
$quasi = {} if $quasi.nil?
module Quasi
  # Set True/False to display Msg Popup Boxes
  SHOW_MSG    = true
 
 
  def self.version(req, script)
    if req > $imported["Quasi_Core"]
      @quasi_update = true
      quasi_msg(script)
    end
  end
 
  def self.quasi_msg(script)
    return unless SHOW_MSG
    if !@quasi_update.nil?
      txt = "[#{script}] Needs a newer version of [Quasi Engine]\n"
      txt += "In order to run."
      msgbox(sprintf(txt))
      $quasi[script] = true
    end
  end
 
  # Just a simple math formula I like to use
  # returns false if number input is even
  # returns true if number input is odd
  def self.odd?(value)
    value += 2 if value == 0
    odd = value % 2
    return true if odd != 0
    return false
  end
 
  # Slope Formula
  # returns in an array [x, y]
  def self.slope(xf,xi,yf,yi,speed=2)
    array = [xf-xi,yf-yi]
    dir  = normalize(array[0],array[1])
    slopex = dir[0] * speed
    slopey = dir[1] * speed
    return [slopex, slopey]
  end
  
  def self.circle(cx, cy, rad, angle)
    x = cx + Math.sin(angle)*rad
    y = cy + Math.cos(angle)*rad
    return [x, y]
  end
 
  # Normalize a Slope
  # returns in an array [x, y]
  # ** Thanks to Resource Dragon **
  def self.normalize(x,y)
    distance = Math.sqrt(x * x + y * y).to_f
    return [x / distance, y / distance]
  end
 
  # Used as a replacement for NthRoot
  # Ex: find y in 100 = y^5
  # Def: y = 100^(1/5)
  # Returns: y = 2.511886432
  # Which is the same as:
  #      y = 5√100
  def self.find_exp(x,nth)
    x = x.to_f
    nth = nth.to_f
    exp = x**(1/nth)
    return exp
  end
 
  # Openning transition effects
   def self.sprite_efx_trans(sprite,settings)
    return if settings.nil?
    return if sprite.nil?
    case settings[1]
    when :zoom
      if sprite.zoom_x > settings[2].to_f/100
        sprite.zoom_x -= settings[3].to_f/100
        sprite.zoom_y -= settings[3].to_f/100
      else
        @qtefx = false
      end
    when :zoom2
      if sprite.zoom_x > 1.0
        sprite.zoom_x -= settings[3].to_f/100
        sprite.zoom_y -= settings[3].to_f/100
      else
        @qtefx = false
      end
    when :spin
      if sprite.angle < settings[2]
        sprite.angle += settings[3]
      else
        @qtefx = false
      end
    when :fade
      if @qtefx
        @qtefx = sprite.opacity < 255 ? true : false
        sprite.opacity += settings[3]
      end
    when :flash
      @qtefxd = {} if @qtefxd.nil?
      @qtefxd[sprite] = 0 if @qtefxd[sprite].nil?
      if settings[2] > @qtefxd[sprite]
        if @qtefxfl.nil?
          alpha = settings[3][3].nil? ? 255  : settings[3][3]
          color = Color.new(settings[3][0],settings[3][1],settings[3][2],alpha)
          sprite.flash(color,settings[2])
          @qtefxfl = true
        end
        sprite.update
        @qtefxd[sprite] += 1
      else
        @qtefx = false
      end
    when :slide
      case settings[2]
      when :horz
        @qtefxx = settings[3][0].to_f/settings[3][1].to_f if @qtefxx.nil?
        @qtefxnx = sprite.x if @qtefxnx.nil?
        if !(settings[3][0]-1..settings[3][0]+1).include?(@qtefxnx)
          @qtefxnx += settings[3][2] ? @qtefxx*-1 : @qtefxx
          sprite.x = @qtefxnx
        else
          @qtefx = false
          @qtefxx = nil
          @qtefxnx = nil
        end
      when :vert
        @qtefxy = settings[3][0].to_f/settings[3][1].to_f if @qtefxy.nil?
        @qtefxny = sprite.y if @qtefxny.nil?
        if !(settings[3][0]-1..settings[3][0]+1).include?(@qtefxny)
          @qtefxny += settings[3][2] ? @qtefxy*-1 : @qtefxy
          sprite.y = @qtefxny
        else
          @qtefx = false
          @qtefxy = nil
          @qtefxny = nil
        end
      end
    else
      # If no settings[1] was found it waits 60 frames
      @qtefxw = 0 if @qtefxw.nil?
      @qtefxw += 1 if @qtefxw < 60
      @qtefx = false if @qtefxw >= 60
    end
  end
  
  def self.efx?
    return @qtefx
  end
  
  def self.efx=(efx)
    @qtefx=efx
  end
 
  # settings[efx, speed/dur, str1, str2]
  def self.sprite_efx(sprite,settings)
    return if settings.nil?
    return if sprite.nil?
    case settings[0]
    when :spin
      sprite.angle += settings[1][1].to_f / settings[1][0]
    when :slidehorz
      sprite.ox += settings[1][1].to_f / settings[1][0]
    when :slidevert
      sprite.oy += settings[1][1].to_f / settings[1][0]
    when :slidedia
      sprite.ox += settings[1][1].to_f / settings[1][0]
      sprite.oy += settings[1][2].to_f / settings[1][0]
    when :wave
      @qefxw = {} if @qefxw.nil?
      if @qefxw[sprite].nil?
        sprite.wave_amp = settings[1][0]
        sprite.wave_length = settings[1][1]
        sprite.wave_speed = settings[1][2]
        @qefxw[sprite] = true
      end  
      sprite.update
    when :frame
      @qefxfi = 0 if @qefxfi.nil?
      @qefxfw = 0 if @qefxfw.nil?
      if @qefxfw < settings[1][0]
        @qefxfw += 1
      else
        @qefxfi += 1
        @qefxfi = 0 if @qefxfi > (settings[1][2]-1)
        @qefxfw = 0
      end
      draw_qsprite(sprite, settings[1][1], settings[1][2], @qefxfi)
      sprite.opacity = 255 if sprite.opacity != 255
    when :color
      alpha = settings[1][1][3].nil? ? 255 : settings[1][1][3]
      color = Color.new(settings[1][1][0],settings[1][1][1],settings[1][1][2],alpha)
      sprite.quasi_flash(color,settings[1][0],settings[1][2])
      sprite.update
    when :flash
      @qefxfld = {} if @qefxfld.nil?
      @qefxfld[sprite] = 0 if @qefxfld[sprite].nil?
      @qefxfl = {} if @qefxfl.nil?
      if settings[1][0] > @qefxfld[sprite]
        if !@qefxfl[sprite]
          alpha = settings[1][4].nil? ? 255 : settings[1][4]
          color = Color.new(settings[1][1],settings[1][2],settings[1][3],alpha) if !settings[1][1].nil?
          color = nil if settings[1][1].nil?
          sprite.flash(color,settings[1][0])
          @qefxfl[sprite] = true
        end
        sprite.update
        @qefxfld[sprite] += 1
      else
        @qefxfl[sprite] = nil
        @qefxfld[sprite] = 0
      end
    when :expand
      zx = settings[1][1]
      zy = settings[1][2]
      
      spx = (settings[1][1]/settings[1][0])
      spy = (settings[1][2]/settings[1][0])
      
      spx = zx < 1.0 ? spx * -1 : spx
      spy = zy < 1.0 ? spy * -1 : spy
      
      if !@qefxzi
        sprite.zoom_x += spx if sprite.zoom_x.round(2) != zx
        sprite.zoom_y += spy if sprite.zoom_y.round(2) != zy
        @qefxzi = true if sprite.zoom_x.round(2) == zx and sprite.zoom_y.round(2) == zy
      else
        sprite.zoom_x -= spx if sprite.zoom_x.round(2) != 1.0
        sprite.zoom_y -= spy if sprite.zoom_y.round(2) != 1.0
        @qefxzi = false if sprite.zoom_x.round(2) == 1.0 and sprite.zoom_y.round(2) == 1.0
      end
    end
  end
 
  # Splits a sprite into frames
  # * For animted sprite purposes
  def self.draw_qsprite(sprite, symbol, frames, index)
    return if sprite.nil?
    return if sprite.bitmap.nil?
    w = sprite.bitmap.width
    h = sprite.bitmap.height
    x = 0
    y = 0
    case symbol
    when :vert
      h = sprite.bitmap.height / frames
      y = h * index
    when :horz
      w = sprite.bitmap.width / frames
      x = w * index
    end
     sprite.src_rect.set(x,y,w,h)
  end
end
 
#==============================================================================
# Some new methods for existing class
#==============================================================================
 
#==============================================================================
# ** Game_Event
#------------------------------------------------------------------------------
#  This class handles events. Functions include event page switching via
# condition determinants and running parallel process events. Used within the
# Game_Map class.
#==============================================================================
 
class Game_Event < Game_Character
    attr_reader   :event                # Grab Event
end
 
 
#==============================================================================
# ** Game_Interpreter
#------------------------------------------------------------------------------
#  An interpreter for executing event commands. This class is used within the
# Game_Map, Game_Troop, and Game_Event classes.
#==============================================================================
 
class Game_Interpreter
  #--------------------------------------------------------------------------
  # * New Method
  #    Makes Variables into an Array.
  #--------------------------------------------------------------------------
  def array(variable_id, array_index, value)
    begin
      $game_variables[variable_id] = Array.new if !$game_variables[variable_id].is_a?(Array)
      $game_variables[variable_id][array_index] = value
    rescue
      $game_variables[variable_id][array_index] = "?Error?"
    end
  end
 
  #--------------------------------------------------------------------------
  # * New Method
  #    Grab the value from the Variable Array
  #--------------------------------------------------------------------------
  def array_value(variable_id, array_index)
    return unless $game_variables[variable_id].is_a?(Array)
    return $game_variables[variable_id][array_index]
  end
 
  #--------------------------------------------------------------------------
  # * New Method
  #    Show all Values from Array
  #--------------------------------------------------------------------------
  def show_array(variable_id)
    return unless $game_variables[variable_id].is_a?(Array)
    return $game_variables[variable_id]
  end
end
 
#==============================================================================
# ** Window_Base
#------------------------------------------------------------------------------
#  This is a super class of all windows within the game.
#==============================================================================
 
class Window_Base < Window
  alias quasi_escape_characters convert_escape_characters
  #--------------------------------------------------------------------------
  # * Preconvert Control Characters
  #    As a rule, replace only what will be changed into text strings before
  #    starting actual drawing. The character "\" is replaced with the escape
  #    character (\e).
  #--------------------------------------------------------------------------
  def convert_escape_characters(text)
    convert_quasi_characters(quasi_escape_characters(text))
  end
 
  #--------------------------------------------------------------------------
  # * New Control Character
  #    Displays an Array with \VA[x,y]
  #--------------------------------------------------------------------------
  def convert_quasi_characters(text)
    text.gsub!(/\eVA\[(\d+),(\d+)\]/i) { $game_variables[$1.to_i][$2.to_i]}
    return text
  end
 
  def sprite_efx_trans(sprite,settings)
    Quasi.sprite_efx_trans(sprite, settings)
    @qtefx = Quasi.efx?
  end
 
  def sprite_efx(sprite,settings)
    Quasi.sprite_efx(sprite, settings)
  end
 
  def draw_qsprite(sprite, symbol, frames, index)
    Quasi.draw_qsprite(sprite, symbol, frames, index)
  end
end
 
#==============================================================================
# ** Scene_Base
#------------------------------------------------------------------------------
#  This is a super class of all scenes within the game.
#==============================================================================
 
class Scene_Base
  def sprite_efx_trans(sprite,settings)
    Quasi.sprite_efx_trans(sprite, settings)
    @qtefx = Quasi.efx?
  end
 
  # settings[efx, speed, str1, str2]
  def sprite_efx(sprite,settings)
    Quasi.sprite_efx(sprite, settings)
  end
 
  def draw_qsprite(sprite, symbol, frames, index)
    Quasi.draw_qsprite(sprite, symbol, frames, index)
  end
end
 
#==============================================================================
# ** Game_Party
#------------------------------------------------------------------------------
#  This class handles parties. Information such as gold and items is included.
# Instances of this class are referenced by $game_party.
#==============================================================================
 
class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # * Get Lowest Level of Party Members
  #--------------------------------------------------------------------------
  def lowest_level
    lv = members.collect {|actor| actor.level }.min
  end
  #--------------------------------------------------------------------------
  # * Get Who the Level belongs too
  # ** If multiple have the same level, it returns an array with both
  #--------------------------------------------------------------------------
  def who_level(value)
    who = []
    members.each do |mem|
      next unless mem.level == value
      who.push(mem.name)
    end
    return if who.empty?
    return who[0] if who.size == 1
    return who
  end
  #--------------------------------------------------------------------------
  # * Get Average Level of Party Members
  #--------------------------------------------------------------------------
  def avg_level
    avg = 0
    members.each {|actor| avg += actor.level}
    avg /= members.size
    return avg
  end
  #--------------------------------------------------------------------------
  # * Get Lowest Value of param of Party Members
  #--------------------------------------------------------------------------
  def lowest_param(x)
    param = members.collect {|actor| actor.param(x) }.min
  end
  #--------------------------------------------------------------------------
  # * Get Highest Value of param of Party Members
  #--------------------------------------------------------------------------
  def highest_param(x)
    param = members.collect {|actor| actor.param(x) }.max
  end
  #--------------------------------------------------------------------------
  # * Get Average Value of param of Party Members
  #--------------------------------------------------------------------------
  def avg_param(x)
    avg = 0
    members.each {|actor| avg += actor.param(x)}
    avg /= members.size
    return avg
  end
  #--------------------------------------------------------------------------
  # * Get Who the param belongs too
  #--------------------------------------------------------------------------
  def who_param(value, x)
    who = []
    members.each do |mem|
      next unless mem.param(x) == value
      who.push(mem.name)
    end
    return if who.empty?
    return who[0] if who.size == 1
    return who
  end
end
 
 
#==============================================================================
# ** Game_CharacterBase
#------------------------------------------------------------------------------
#  This base class handles characters. It retains basic information, such as
# coordinates and graphics, shared by all characters.
#==============================================================================
 
class Game_CharacterBase
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor   :opacity                  # opacity level
 
  def fade_in(x)
    if @opacity < 255
      @opacity += x
      @fade = false
    else
      @fade = true
    end
  end
 
  def fade_out(x)
    if @opacity > 0
      @opacity -= x
      @fade = false
    else
      @fade = true
    end
  end
 
  def fade?
    return @fade
  end
end

class Sprite
  def quasi_flash(nc,duration,repeat=false)
    return if @qrep == false
    @old = self.color.clone if @old.nil?
    
    if @qcolor.nil?
      a = self.color.alpha
      a += nc.alpha/duration.to_f if a != nc.alpha
      self.color = Color.new(nc.red,nc.green,nc.blue,a)
      @qcolor = true if self.color == nc
    else
      a = self.color.alpha
      a -= nc.alpha/duration.to_f if a != @old.alpha
      self.color = Color.new(nc.red,nc.green,nc.blue,a)
      @qrep = repeat if self.color.alpha == @old.alpha
      @qcolor = nil if self.color.alpha == @old.alpha and @qrep
    end
  end
  
  def quasi_color(nc,duration)
    @old = self.color.clone if @old.nil?
    if @qcolor.nil?
      nc = nc.nil? ? Color.new(0,0,0,0) : nc
      r = self.color.red
      g = self.color.green
      b = self.color.blue
      a = nc.alpha
      
      rn = (nc.red - @old.red)/duration.to_f
      gn = (nc.green - @old.green)/duration.to_f
      bn = (nc.blue - @old.blue)/duration.to_f
      
      r += rn if r != nc.red
      g += gn if g != nc.green
      b += bn if b != nc.blue
      
      self.color = Color.new(r,g,b,a)
      @qcolor = true if self.color == nc
    end
  end
end