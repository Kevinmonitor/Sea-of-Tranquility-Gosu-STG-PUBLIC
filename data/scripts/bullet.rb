require 'minigl'

include MiniGL

class Bullet < GameObject

	# Class variables

	@@enemy = []
	@@player = []

	attr_accessor :x, :y, :w, :h, :img, :img_gap, :sprite_cols, :sprite_rows, :mass, :retro, :hitbox_size, :image_size, :movement_speed, :movement_angle, :damage, :is_enemy, :scale_x, :scale_y, :z_order

	def initialize(x, y, w, h, img,
					img_gap = nil, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = nil,
					hitbox_size, image_size, movement_speed, movement_angle, damage, is_enemy,
					scale_x, scale_y)

		super(x, y, w, h, img, img_gap = nil, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = nil)

		@hitbox_size = hitbox_size
		@image_size = image_size

		@scale_x = scale_x
		@scale_y = scale_y

		self.w = @hitbox_size
		self.h = @hitbox_size
		self.img_gap = Vector.new((-@image_size/2 + @hitbox_size/4), (-@image_size/2 + @hitbox_size/4))
		self.retro = true

		@movement_speed = movement_speed
		@movement_angle = movement_angle
		@damage = damage

		@is_enemy = is_enemy

		# Add the bullet to either the enemy bullets array or player bullets array depending on @is_enemy

		if self.is_enemy == true
			@@enemy << self
		else
			@@player << self
		end

	end

	# Get array of enemy/player bullets

	def self.enemy
		@@enemy
	end

	def self.player
		@@player
	end

end

# Bullet patterns
