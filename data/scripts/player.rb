require 'minigl'

include MiniGL

# #initialize(x, y, w, h, img, img_gap = nil, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = nil) ⇒ GameObject

class Player < GameObject

	attr_accessor :bullet_sprite, :hitbox_size, :movement_speed, :player_lives

end
