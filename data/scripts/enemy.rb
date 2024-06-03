require 'minigl'

include MiniGL

# #initialize(x, y, w, h, img, img_gap = nil, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = nil) ⇒ GameObject

class Enemy < GameObject

	attr_accessor :x, :y, :w, :h, :img, :img_gap, :sprite_cols, :sprite_rows, :mass, :retro,

	:hitbox_size, :image_size, :movement_speed, :movement_angle, :hp,

	:scale_x, :scale_y,

	:autodelete_timer, :fire_timer,

	:autodelete_tick, :fire_tick,

	:type, :autodelete,

	:args1, :args2, :z_order,

	:min_score, :max_score, :pointblank_distance

	def initialize(x, y, w, h,
				img, img_gap = nil, sprite_cols = nil, sprite_rows = nil,
				mass = 1.0, retro = nil,
				hitbox_size, image_size, movement_speed, movement_angle, hp,
				scale_x, scale_y,
				autodelete_timer, fire_timer)

		super(x, y, w, h, img, img_gap = nil, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = nil)

		@hitbox_size = hitbox_size
		@image_size = image_size

		self.w = @hitbox_size
		self.h = @hitbox_size
		self.img_gap = Vector.new(-@image_size/2 + @hitbox_size/4, -@image_size/2 + @hitbox_size/4)
		self.retro = true

		@movement_speed = movement_speed
		@movement_angle = movement_angle

		@hp = hp

		@scale_x = scale_x
		@scale_y = scale_y

		@autodelete = false

		@autodelete_tick = 0
		@fire_tick = 0

		@args1 = []
		@args2 = []

		@z_order = ZOrder::FLYINGENEMY

		@min_score = 10
		@max_score = 100
		@pointblank_distance = @image_size * 3

	end

end
