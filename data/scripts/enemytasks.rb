require 'gosu'
require 'minigl'

include Gosu
include MiniGL

require_relative 'bullet.rb'
require_relative 'enemy.rb'

def fire_single(x, y, speed, angle, hitbox_size, img, image_size, scale_x = 1.0, scale_y = 1.0)

	#puts("action")

	shot = Bullet.new(
			x, y, 1, 1, img,
			img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
			hitbox_size, image_size, speed, angle, damage = 1.0, is_enemy = true,
			scale_x, scale_y)

	return shot

end

def fire_spread(x, y, speed, angle, hitbox_size, img, image_size, scale_x = 1.0, scale_y = 1.0,
				density = 1, angle_difference = 1.0)

	shot_array = []
	i = (-density/2).ceil

	while i < (density/2).floor

		shot = Bullet.new(
				x, y, 1, 1, img,
				img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
				hitbox_size, image_size, speed, angle - i.to_i * (angle_difference.to_f/density.to_i), damage = 1.0, is_enemy = true,
				scale_x, scale_y)

		shot_array << shot

		i += 1

	end

	return shot_array

end

def fire_ring(x, y, speed, angle, hitbox_size, img, image_size, scale_x = 1.0, scale_y = 1.0,
			density = 1)

	shot_array = []
	i = 0

	while i < density

		shot = Bullet.new(
				x, y, 1, 1, img,
				img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
				hitbox_size, image_size, speed, angle + 0 + i * 360/density, damage = 1.0, is_enemy = true,
				scale_x, scale_y)

		shot_array << shot

		i += 1

	end

	return shot_array

end

def CreateBasicEnemy(spawnX, spawnY, moveSpeed, moveAngle, enmHP, enmGraphic, enmGraphicSize, enmHitbox, scaleX, scaleY, fireType = "single", fireIntensity = 1)

	enm = Enemy.new(
		spawnX, spawnY, enmHitbox, enmHitbox,
		enmGraphic, img_gap = nil, sprite_cols = nil, sprite_rows = nil,
		mass = 1.0, retro = true,
		enmHitbox, enmGraphicSize, moveSpeed, moveAngle, enmHP,
		scaleX, scaleY,
		60 - moveAngle * 5, fireIntensity)

	timer = (60 - moveAngle * 5)
	timer = timer.clamp(15, 60)

	enm.autodelete_timer = timer.to_i

	enm.type = fireType

	@enemies << enm

	#puts(@enemies.length)

	return enm

end

# args_1 = [x_offset, y_offset, speed, is_aimed, hitbox_size, img, image_size, scale_x = 1.0, scale_y = 1.0]
# args_2 = [density, angle_difference]

def AimPopcornSingle(x, y, bulletSpeed = 4.0, moveSpeed = 4.0, moveAngle = 90, fireDelay = 20, enmHP = 100)

	# Create enemy with asynchronous tasks

	enmGraphicSize = 32

	enm = CreateBasicEnemy(x - enmGraphicSize/2, y,
					moveSpeed, moveAngle,
					enmHP, :enemy_enm1, enmGraphicSize,
					enmHitbox = 48, scaleX = 2, scaleY = 2)

	enm.type = "single"
	enm.fire_tick = fireDelay-15
	enm.fire_timer = fireDelay
	enm.fire_timer = enm.fire_timer.clamp(5, 200).to_i

	enm.min_score = 10000
	enm.max_score = 50000

	# enm.x - enm.hitbox_size/2, enm.y - enm.hitbox_size/2

	enm.z_order = ZOrder::FLYINGENEMY

	enm.args1 = [0, 0, bulletSpeed, true, 1,

				#Gosu.angle(enm.x - enm.hitbox_size/2, enm.y - enm.hitbox_size/2,
				#@player.x - @player_hitbox/2, @player.y - @player_hitbox/2),

				bulletSize = 3, :fulltex_tile_enmshot1green, bulletImgSize = 16, scale_x = 2.0, scale_y = 2.0]

	enm.args2 = [density = 12, angle_difference = 20]

end

def AimRingSingle(x, y, ringDensity = 8.0, bulletSpeed = 4.0, moveSpeed = 4.0, moveAngle = 90, fireDelay = 20, enmHP = 200)

	# Create enemy with asynchronous tasks

	enmGraphicSize = 32

	enm = CreateBasicEnemy(x - enmGraphicSize/2, y,
					moveSpeed, moveAngle,
					enmHP, :enemy_enm2, enmGraphicSize,
					enmHitbox = 64, scaleX = 3, scaleY = 3)

	enm.hp = 200
	enm.type = "ring"
	enm.fire_tick = fireDelay/1.5
	enm.fire_timer = fireDelay
	enm.fire_timer = enm.fire_timer.clamp(5, 999).to_i

	# enm.x - enm.hitbox_size/2, enm.y - enm.hitbox_size/2

	enm.min_score = 30000
	enm.max_score = 150000

	enm.z_order = ZOrder::FLYINGENEMY

	enm.args1 = [0, 0, bulletSpeed, true, 1,

				#Gosu.angle(enm.x - enm.hitbox_size/2, enm.y - enm.hitbox_size/2,
				#@player.x - @player_hitbox/2, @player.y - @player_hitbox/2),

				bulletSize = 3, :fulltex_tile_enmshot1orange, bulletImgSize = 16, scale_x = 2.0, scale_y = 2.0]

	enm.args2 = [density = ringDensity, angle_difference = 1]

end

def AimSpreadSingle(x, y, spreadDensity = 8, spreadLevel = 1.0, bulletSpeed = 4.0, moveSpeed = 4.0, moveAngle = 90, fireDelay = 20, enmHP = 100)

	# Create enemy with asynchronous tasks

	enmGraphicSize = 32

	enm = CreateBasicEnemy(x - enmGraphicSize/2, y,
					moveSpeed, moveAngle,
					100, :enemy_enm2, enmGraphicSize,
					enmHitbox = 32, scaleX = 2, scaleY = 2)

	enm.hp = enmHP
	enm.type = "spread"
	enm.fire_tick = fireDelay/1.5
	enm.fire_timer = fireDelay
	enm.fire_timer = enm.fire_timer.clamp(5, 999).to_i

	# enm.x - enm.hitbox_size/2, enm.y - enm.hitbox_size/2

	enm.min_score = 15000
	enm.max_score = 75000

	enm.z_order = ZOrder::FLYINGENEMY

	enm.args1 = [0, 0, bulletSpeed, true, 1,

				#Gosu.angle(enm.x - enm.hitbox_size/2, enm.y - enm.hitbox_size/2,
				#@player.x - @player_hitbox/2, @player.y - @player_hitbox/2),

				bulletSize = 3, :fulltex_tile_enmshot1green, bulletImgSize = 16, scale_x = 2.0, scale_y = 2.0]

	enm.args2 = [density = spreadDensity, angle_difference = spreadLevel]

end

def CustomRing01(x, y, spreadDensity = 16, spreadCount = 3, bulletSpeed = 2.0, moveSpeed = 3.0, moveAngle = 90, fireDelay = 60, enmHP = 300)

	# Create enemy with asynchronous tasks

	enmGraphicSize = 32

	enm = CreateBasicEnemy(x - enmGraphicSize/2, y,
					moveSpeed, moveAngle,
					enmHP, :enemy_enm3, enmGraphicSize,
					enmHitbox = 90, scaleX = 4, scaleY = 4)

	enm.type = "custom"
	enm.fire_tick = fireDelay-15
	enm.fire_timer = fireDelay
	enm.fire_timer = enm.fire_timer.clamp(5, 200).to_i

	enm.min_score = 40000
	enm.max_score = 200000

	# enm.x - enm.hitbox_size/2, enm.y - enm.hitbox_size/2

	enm.z_order = ZOrder::FLYINGENEMY

	enm.args1 = [0, 0, bulletSpeed, true, 1,

				#Gosu.angle(enm.x - enm.hitbox_size/2, enm.y - enm.hitbox_size/2,
				#@player.x - @player_hitbox/2, @player.y - @player_hitbox/2),

				bulletSize = 3, :fulltex_tile_enmshot1orange, bulletImgSize = 16, scale_x = 2.0, scale_y = 2.0]

	enm.args2 = [density = spreadDensity, angle_difference = 20]

	Scheduler.start do

		while enm != nil and enm.hp > 0

			i = 0
			angle = rand(-180...180)
			x = enm.x
			y = enm.y

			while i < spreadCount

				fire_ring(x, y, bulletSpeed, angle, enm.args1[5], enm.args1[6], enm.args1[7], scale_x = enm.args1[8], scale_y = enm.args1[9], density = enm.args2[0])
				i += 1
				Scheduler.wait(4)

			end

			Scheduler.wait(fireDelay)

		end

	end

end
