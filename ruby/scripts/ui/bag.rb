class BagUI < BaseUI
  attr_reader :pocket

  def start
    super(path: "bag")
    @suffix = ["_male", "_female"][$trainer.gender]
    @sprites["background"] = Sprite.new(@viewport)
    @sprites["background"].set_bitmap(@path + "background" + @suffix)
    @sprites["bgtext"] = Sprite.new(@viewport)
    @sprites["bgtext"].set_bitmap(Graphics.width, Graphics.height)
    @sprites["bgtext"].z = 1
    @sprites["bag"] = BagSprite.new($trainer.gender, self)
    @sprites["bag"].x = 22
    @sprites["bag"].y = 66
    @sprites["footer"] = SelectableSprite.new(@viewport)
    @sprites["footer"].set_bitmap(@path + "footer")
    @sprites["footer"].y = 224
    @sprites["list"] = Sprite.new(@viewport)
    @sprites["list"].set_bitmap(@path + "item_list")
    @sprites["list"].x = 176
    @sprites["list"].y = 16
    @sprites["text"] = Sprite.new(@viewport)
    @sprites["text"].set_bitmap(288, 190)
    @sprites["text"].x = 176
    @sprites["text"].y = 16
    @sprites["text"].z = 1
    @sprites["icon"] = Sprite.new(@viewport)
    @sprites["icon"].x = 12
    @sprites["icon"].y = 244
    @sprites["icon"].z = 3
    @sprites["arrow_left"] = ArrowSprite.new(:left, @viewport)
    @sprites["arrow_left"].y = 130
    @sprites["arrow_right"] = ArrowSprite.new(:right, @viewport)
    @sprites["arrow_right"].x = 142
    @sprites["arrow_right"].y = 130
    @sprites["arrow_up"] = ArrowSprite.new(:up, @viewport)
    @sprites["arrow_up"].x = 306
    @sprites["arrow_up"].z = 1
    @sprites["arrow_down"] = ArrowSprite.new(:down, @viewport)
    @sprites["arrow_down"].x = 306
    @sprites["arrow_down"].y = 206
    @sprites["selector"] = SelectableSprite.new(@viewport)
    @sprites["selector"].set_bitmap("gfx/misc/choice_arrow")
    @sprites["selector"].x = 180
    @pocket = $trainer.bag.last_pocket
    @items = $trainer.bag.pockets[@pocket]
    if !@items
      @pocket = Trainer::Bag::POCKETS[0]
      @items = $trainer.bag.pockets[@pocket]
    end
    @top_idx = $trainer.bag.indexes[@pocket][:top_idx]
    @list_idx = $trainer.bag.indexes[@pocket][:list_idx]
    @sprites["selector"].y = 8 + 32 * @list_idx
    draw_pocket(false)
    update_sprites
  end

  def pocket_idx
    idx = Trainer::Bag::POCKETS.index(@pocket)
    return idx if idx >= 0
    return 0
  end

  def pocket_name
    return Trainer::Bag::POCKET_NAMES[@pocket] || "?????"
  end

  def draw_list(selection_changed = false)
    @sprites["text"].bitmap.clear
    for i in @top_idx..(@top_idx + 5)
      if @items[i] || @items[i - 1] || i == 0
        if !@items[i]
          name = "CANCEL"
        else
          item = Item.get(@items[i][:item])
          name = item.name
          @sprites["text"].draw_text(
              {x: 222, y: 8 + 32 * (i - @top_idx), text: "x", color: Color::GREYBASE, shadow_color: Color::GREYSHADOW},
              {x: 264, y: 10 + 32 * (i - @top_idx), text: @items[i][:count].to_s, color: Color::GREYBASE, shadow_color: Color::GREYSHADOW,
               small: true, alignment: :right}
          )
        end
        @sprites["text"].draw_text(
          {x: 18, y: 10 + 32 * (i - @top_idx), text: name, color: Color::GREYBASE, shadow_color: Color::GREYSHADOW}
        )
      end
    end
    @sprites["selector"].y = 24 + 32 * @list_idx
    $trainer.bag.indexes[@pocket][:top_idx] = @top_idx
    $trainer.bag.indexes[@pocket][:list_idx] = @list_idx
    @sprites["arrow_up"].visible = @top_idx > 0
    @sprites["arrow_down"].visible = @items.size - @top_idx > 5
    draw_item
    if selection_changed
      Audio.se_play("audio/se/bag_item")
      @sprites["bag"].shake
    end
  end

  def draw_item
    @sprites["bgtext"].bitmap.clear
    @sprites["bgtext"].draw_text(
      {x: 88, y: 24, text: pocket_name, color: Color::LIGHTBASE, shadow_color: Color::LIGHTSHADOW,
       alignment: :center}
    )
    filename = @path + "cancel"
    description = ["CLOSE BAG"]
    if selected_item
      item = Item.get(selected_item[:item])
      filename = "gfx/items/" + item.intname.to_s
      description = MessageWindow.get_formatted_text(@sprites["bgtext"].bitmap, 384, item.description).split("\n")
    end
    description.each_with_index do |txt, i|
      @sprites["bgtext"].draw_text(
        x: 80, y: 236 + 28 * i, text: txt, color: Color::LIGHTBASE, shadow_color: Color::LIGHTSHADOW
      )
    end
    @sprites["icon"].set_bitmap(filename)
  end

  def draw_pocket(selection_changed = true)
    @items = $trainer.bag.pockets[@pocket]
    @top_idx = $trainer.bag.indexes[@pocket][:top_idx]
    @list_idx = $trainer.bag.indexes[@pocket][:list_idx]
    if !selection_changed
      @sprites["bag"].pocket = pocket_idx
    else
      $trainer.bag.last_pocket = Trainer::Bag::POCKETS[pocket_idx]
      @sprites["bgtext"].visible = false
      @sprites["text"].visible = false
      @sprites["icon"].visible = false
      @sprites["selector"].visible = false
      @sprites["arrow_up"].visible = false
      @sprites["arrow_down"].visible = false
      @sprites["arrow_left"].visible = false
      @sprites["arrow_right"].visible = false
      @sprites["bag"].pocket = -1
      @sprites["list"].src_rect.height = 0
      @sprites["list"].src_rect.y = @sprites["list"].bitmap.height
      @sprites["list"].y += @sprites["list"].bitmap.height
      frames = framecount(0.15)
      increment = @sprites["list"].bitmap.height / frames.to_f
      for i in 1..frames
        Graphics.update
        Input.update
        if i == 2
          Audio.se_play("audio/se/bag_pocket")
        end
        if i == (frames / 2.0).round
          @sprites["bag"].pocket = pocket_idx
        end
        height = increment * i
        @sprites["list"].src_rect.height = height
        @sprites["list"].src_rect.y = @sprites["list"].bitmap.height - height
        @sprites["list"].y = 16 + @sprites["list"].bitmap.height - height
      end
      wait(0.15)
      @sprites["bgtext"].visible = true
      @sprites["text"].visible = true
      @sprites["icon"].visible = true
      @sprites["selector"].visible = true
      @sprites["arrow_up"].visible = true
      @sprites["arrow_down"].visible = true
      update_sprites
    end
    draw_list
    @sprites["arrow_left"].visible = pocket_idx > 0
    @sprites["arrow_right"].visible = pocket_idx < Trainer::Bag::POCKETS.size - 1
  end

  def item_idx
    return @top_idx + @list_idx
  end

  def selected_item
    return @items[item_idx]
  end

  def update
    super
    stop if Input.cancel?
    if Input.confirm?
      if item_idx == @items.size # Cancel
        stop
      else
        select_item
      end
    end
    if Input.repeat_down?(0.5, 0.18)
      if @list_idx == 3 && @items.size - item_idx > 2
        @top_idx += 1
        draw_list(true)
      elsif @items.size - item_idx > 0
        @list_idx += 1
        draw_list(true)
      end
    end
    if Input.repeat_up?(0.5, 0.18)
      if @list_idx == 2 && item_idx > 2
        @top_idx -= 1
        draw_list(true)
      elsif item_idx > 0
        @list_idx -= 1
        draw_list(true)
      end
    end
    if Input.left? && pocket_idx > 0
      @pocket = Trainer::Bag::POCKETS[pocket_idx - 1]
      draw_pocket
    end
    if Input.right? && pocket_idx < Trainer::Bag::POCKETS.size - 1
      @pocket = Trainer::Bag::POCKETS[pocket_idx + 1]
      draw_pocket
    end
  end

  def set_footer(selected)
    if selected
      @sprites["footer"].select
      @sprites["footer"].z = 2
      @sprites["selector"].select
      @sprites["arrow_up"].visible = false
      @sprites["arrow_down"].visible = false
      @sprites["arrow_left"].visible = false
      @sprites["arrow_right"].visible = false
    else
      @sprites["footer"].deselect
      @sprites["footer"].z = 0
      @sprites["selector"].deselect
      draw_pocket(false)
    end
  end

  def select_item
    Audio.se_play("audio/se/menu_select")
    set_footer(true)
    item = Item.get(selected_item[:item])
    msgwin = MessageWindow.new(
      x: 80,
      y: 224,
      z: 3,
      width: 256,
      height: 96,
      text: item.name + " is\nselected.",
      viewport: @viewport,
      windowskin: :helper,
      color: Color::GREYBASE,
      shadow_color: Color::GREYSHADOW,
      letter_by_letter: false
    )
    choices = ["USE", "GIVE", "TOSS", "CANCEL"]
    cmdwin = ChoiceWindow.new(
      x: 480,
      ox: :right,
      y: 320,
      oy: :bottom,
      z: 3,
      width: 144,
      choices: choices,
      viewport: @viewport
    )
    loop do
      cmd = cmdwin.get_choice { update_sprites }
      case cmd
      when "USE"

      when "GIVE"
        routine = GiveItemRoutine.new(self)
        stop_item_selection(cmdwin, msgwin)
        routine.start
        routine.stop
        break
      when "TOSS"
        value = 0
        cmdwin.visible = false
        if selected_item[:count] == 1
          value = 1
        else
          msgwin.width = 288
          msgwin.text = "Toss out how many\n" + item.name + "(s)?"
          numwin = NumericChoiceWindow.new(
            x: 368,
            y: 224,
            z: 3,
            max: selected_item[:count],
            viewport: @viewport
          )
          value = numwin.get_choice
          numwin.dispose
        end
        if value > 0
          msgwin.width = 272
          msgwin.text = "Throw away #{value} of this item?"
          confirmwin = ChoiceWindow.new(
            x: 352,
            y: 224,
            z: 3,
            width: 128,
            line_y_space: -4,
            choices: ["YES", "NO"],
            viewport: @viewport
          )
          toss = confirmwin.get_choice == "YES"
          confirmwin.dispose
          if toss
            msgwin.width = 392
            msgwin.show("Threw away #{value}\n" + item.name + "(s).")
            $trainer.bag.remove_item(item, value)
            draw_list
          end
          msgwin.dispose
        end
        break
      when "CANCEL"
        break
      end
    end
    stop_item_selection(cmdwin, msgwin)
  end

  def stop_item_selection(cmdwin, msgwin)
    set_footer(false)
    cmdwin.dispose if !cmdwin.disposed?
    msgwin.dispose if !msgwin.disposed?
  end

  def stop
    if !stopped?
      Audio.se_play("audio/se/menu_select")
    end
    super
  end

  def show_black(mode = nil)
    if mode == :opening || mode == :closing
      super(mode)
    else
      black = Sprite.new(@viewport)
      black.set_bitmap(Graphics.width, Graphics.height)
      black.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color::BLACK)
      black.opacity = 0
      black.z = 99999
      sliding = Sprite.new(@viewport)
      sliding.set_bitmap(Graphics.width, Graphics.height)
      sliding.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color::BLACK)
      sliding.src_rect.height = 0
      sliding.z = 99999
      frames = framecount(0.15)
      increment_opacity = 255.0 / frames
      increment_height = Graphics.height / frames.to_f
      for i in 1..frames
        Graphics.update
        Input.update
        update_sprites
        sliding.src_rect.height = increment_height * i
        black.opacity = increment_opacity * i
      end
      black.dispose
      sliding.dispose
      Graphics.brightness = 0
    end
  end

  def hide_black(mode = nil)
    if mode == :opening || mode == :closing
      super(mode)
    else
      black = Sprite.new(@viewport)
      black.set_bitmap(Graphics.width, Graphics.height)
      black.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color::BLACK)
      black.z = 99999
      sliding = Sprite.new(@viewport)
      sliding.set_bitmap(Graphics.width, Graphics.height)
      sliding.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color::BLACK)
      sliding.z = 99999
      frames = framecount(0.15)
      increment_opacity = 255.0 / frames
      increment_height = Graphics.height / frames.to_f
      Graphics.brightness = 255
      for i in 1..frames
        Graphics.update
        Input.update
        update_sprites
        sliding.src_rect.height = Graphics.height - increment_height * i
        black.opacity = 255 - increment_opacity * i
      end
      black.dispose
      sliding.dispose
    end
  end



  class BagSprite < Sprite
    def initialize(gender, ui)
      @gender = gender
      @ui = ui
      super(@ui.viewport)
      pocket = $trainer.bag.last_pocket
      @suffix = ["_male", "_female"][$trainer.gender]
      self.set_bitmap(@ui.path + "bag" + @suffix)
      self.src_rect.width = self.bitmap.width / (Trainer::Bag::POCKETS.size + 1)
      self.ox = self.bitmap.width / 8
      self.oy = self.bitmap.height / 2
      self.z = 2
      @shadow = Sprite.new(@ui.viewport)
      @shadow.set_bitmap(@ui.path + "bag_shadow")
      @shadow.y = 96
      @shadow.z = 1
      pidx = Trainer::Bag::POCKETS.index(pocket)
      pidx = 0 if pidx < 1
      self.src_rect.x = self.src_rect.width * (pidx + 1)
    end

    def pocket=(value)
      self.src_rect.x = self.src_rect.width * (value + 1)
    end

    def x=(value)
      super(value + self.ox)
      @shadow.x = value
    end

    def y=(value)
      super(value + self.oy)
      @shadow.y = value + 96
    end

    def shake
      @i = 0
      self.angle = -2
    end

    def update
      super
      if @i
        @i += 1
        # One angle change takes 0.064 seconds and it can be interrupted.
        case @i
        when framecount(0.064 * 1)
          self.angle = 0
        when framecount(0.064 * 2)
          self.angle = 2
        when framecount(0.064 * 3)
          self.angle = -6
        when framecount(0.064 * 4)
          self.angle = 0
          @i = nil
        end
      end
    end
  end
end
