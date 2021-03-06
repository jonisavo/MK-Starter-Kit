Font.default_outline = false
Font.default_name = "Fire Red"
Font.default_size = 36

class Sprite
  def draw_text(*args)
    # {x:, y: , text:, color:, ...}
    args.each_with_index do |arg, idx|
      x = arg[:x] || 0
      y = arg[:y] || 0
      text = arg[:text]
      color = arg[:color] || Color::WHITE
      shadow_color = arg[:shadow_color]
      outline_color = arg[:outline_color]
      alignment = arg[:alignment] || :left
      small = arg[:small] || false
      validate x => Integer,
          y => Integer,
          text => String,
          color => Color,
          shadow_color => [NilClass, Color],
          outline_color => [NilClass, Color],
          alignment => [Symbol, Integer, String],
          small => Boolean
      y -= 8
      fontname = self.bitmap.font.name
      if small
        self.bitmap.font.name += " Small"
      end
      if shadow_color && outline_color
        if args.size > 1
          raise "Cannot draw text with both a shadow and an outline (draw operation #{i})."
        else
          raise "Cannot draw text with both a shadow and an outline."
        end
      end
      text_size = self.bitmap.text_size(text)
      x -= text_size.width if [:RIGHT, :right, "right", "RIGHT"].include?(alignment)
      x -= text_size.width / 2 if [:CENTER, :center, "center", "CENTER"].include?(alignment)
      if shadow_color
        self.bitmap.font.color = shadow_color
        self.bitmap.draw_text(x + 2, y, text_size.width, text_size.height, text)
        self.bitmap.draw_text(x, y + 2, text_size.width, text_size.height, text)
        self.bitmap.draw_text(x + 2, y + 2, text_size.width, text_size.height, text)
      end
      if outline_color
        self.bitmap.font.color = outline_color
        self.bitmap.draw_text(x + 2, y + 2, text_size.width, text_size.height, text)
        self.bitmap.draw_text(x + 2, y - 2, text_size.width, text_size.height, text)
        self.bitmap.draw_text(x + 2, y, text_size.width, text_size.height, text)
        self.bitmap.draw_text(x - 2, y + 2, text_size.width, text_size.height, text)
        self.bitmap.draw_text(x - 2, y - 2, text_size.width, text_size.height, text)
        self.bitmap.draw_text(x - 2, y, text_size.width, text_size.height, text)
        self.bitmap.draw_text(x, y + 2, text_size.width, text_size.height, text)
        self.bitmap.draw_text(x, y - 2, text_size.width, text_size.height, text)
      end
      self.bitmap.font.color = color
      self.bitmap.draw_text(x, y, text_size.width, text_size.height, text)
      self.bitmap.font.name = fontname
    end
  end

  def text_size(text, small = false)
    fontname = self.bitmap.font.name
    if small
      self.bitmap.font.name += " Small"
    end
    size = self.bitmap.text_size(text)
    self.bitmap.font.name = fontname
    return size
  end

  def set_bitmap(*args)
    if args[0].is_a?(Bitmap)
      self.bitmap = args[0]
    else
      self.bitmap = Bitmap.new(*args)
    end
  end

  alias old_sprite_update update
  def update
    raise RGSSError, "disposed sprite" if disposed?
    old_sprite_update
  end
end
