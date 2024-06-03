require 'bundler/setup'

require 'gosu'
require 'minigl'
require 'orange_zest'

require_relative 'data/scripts/bullet.rb'
require_relative 'data/scripts/enemy.rb'
require_relative 'data/scripts/player.rb'
require_relative 'data/scripts/ui.rb'

require_relative 'data/scripts/lerp_lib.rb'
require_relative 'data/scripts/enemytasks.rb'

require_relative 'data/scripts/recordfunctions.rb'

include Gosu
include MiniGL
include OrangeZest

module ZOrder
	BACKGROUND, UI, GROUNDENEMY, FLYINGENEMY, PLAYERSHOT, PLAYER, ENMSHOT, HITBOX = *0..7
end

class MyGame < GameWindow

	def needs_cursor?
		true
	end

	def initialize

		@enemies = []

		@SCREEN_WIDTH = 480
		@SCREEN_HEIGHT = 640

		super @SCREEN_WIDTH, @SCREEN_HEIGHT, false # creating a 800 x 600 window, not full screen

		@threshold = 48 # Autodeletion for shots

		InitialiseGameObjects()

		@font = Res.font(:FormalFuture, 20, global = true, ext = '.ttf')
		@fontlarge = Res.font(:FormalFuture, 40, global = true, ext = '.ttf')
		@th = TextHelper.new @font

		@score_text_tick = 0

		# background

		@bg = Res.img(:fulltex_seabg, global = true, tileable = true, ext = '.png', retro = true)
		@bg_x = 0
		@bg_y = 0

		# meh

		@is_start_screen = true
		@is_paused = false
		@is_game_over = false

		@player_name = ""

		@name_input = TextField.new 140, 320, @fontlarge, :misc_input, cursor_img = :misc_inputcursor, disabled_img = nil, margin_x = 12, margin_y = 12, max_length = 10, focused = true, text = '', allowed_chars = "abcdefghijklmnopqrstuvwxyz1234567890 ABCDEFGHIJKLMNOPQRSTUVWXYZ", text_color = 0xffffff, disabled_text_color = 0x494949, selection_color = 0x494949, locale = 'en-us', params = nil, retro = true, scale_x = 1, scale_y = 1, anchor = nil

	end

	def InitialiseGameObjects()

		InitialisePlayer()
		InitialiseEnemies()
		InitialiseData()
		InitialiseEffects()
		InitialiseSound()

	end

	def InitialiseEnemies()

		@timer = 90 # frames
		@rank_timer = 120
		@enemy_timer_tick = 0

		@rank = 1
		@true_rank = 1.0

		@density_rate = 1.0 + @rank/200.to_f # per rank
		@speed_rate = 1.0 + @rank/150.to_f # per rank
		@move_speed_rate = 1.0 + @rank/250.to_f
		@delay_rate = 1.0 - @rank/250.to_f
		@timer_rate = 1.0 - @rank/250.to_f

		@enemy_shoot_tick = 0

		@flying_wave_number = 0
		@ground_wave_number = 0

		@ground_waves = 0
		@flying_waves = 9

		@total_flying_waves = 0
		@total_ground_waves = 0

		@is_spawn_flying_wave = false
		@is_spawn_ground_wave = false

	end

	# Create enemy

	# enm = Enemy.new(rand(SCREEN_WIDTH/4, 3 * SCREEN_WIDTH/4), -36,
	#  				w, h, img, img_gap = nil,
	# 				sprite_cols = nil, sprite_rows = nil,
	# 				mass = 1.0, retro = nil,
	# 				hitbox_size, image_size,
	# 				movement_speed, movement_angle,
	# 				enemy_hp)

	def InitialisePlayer()

		@player_hitbox = 8
		@player_speed = 10
		@player_fspeed = 5
		@player_dmg = 30

		@player_w = 32
		@player_h = 32

		@player_offset = Vector.new(-@player_w/2 + @player_hitbox/4, -@player_h/2 + @player_hitbox/4)

		@tick = 0

		@player_shot_delay = 5
		@is_diagonal = false
		@diagonal = 0.733

		@pshot_hitbox_size = 48
		@pshot_image_size = 32

		@player = GameObject.new(@SCREEN_WIDTH/2, 5 * @SCREEN_HEIGHT/8, @player_hitbox, @player_hitbox, :player_player, img_gap = @player_offset, sprite_cols = 3, sprite_rows = 3, mass = 1.0, retro = true)

		# Score system: pointblank enemies for score.

		# lives

	end

	def InitialiseData()

		@score = 0

		@score_text_array = []
		@to_next_extend = 10000000

		@player_hp = 2
		@player_hits = 0

		@player_max_hp = 30
		@hp_sprite_array = []

		@is_player_invincible = false
		@is_player_dead = false
		@player_iframes = 0

		h = 0
		while h < @player_max_hp
			heart = Sprite.new(h * 24, @SCREEN_HEIGHT-72, :player_hp, sprite_cols = 1, sprite_rows = 1, retro = true)
			@hp_sprite_array << heart
			h += 1
		end

	end

	def InitialiseEffects()

		@effect_array = []

	end

	def InitialiseSound()

		@game_music = Res.song(:SunTower55F, global = true)

		@extend_sfx = Res.sound(:lifeget, global = true)
		@damage_sfx = Res.sound(:damagesound, global = true)
		@player_fire_sfx = Res.sound(:playerfire, global = true)

		#@player_fire_sfx.volume = 0.5

	end

	def update

		KB.update
		Mouse.update

		HandleGameStart()
		HandlePause()

		if @is_game_over
			@name_input.update
			HandleScoreRecording()
		end

		unless @is_paused or @is_game_over or @is_start_screen

			Scheduler.update

			AwardExtend()

			UpdatePlayerMovement()
			UpdatePlayerShooting()

			UpdateObjects()
			UpdateValues()

			UpdateEnemySpawns()
			CheckCollision()

			UpdateEffects()

		end

	end

	def UpdatePlayerMovement()

		# Animate the player

		if !@is_player_invincible
			@player.animate([0, 1], 6)
		else
			@player.animate([3, 4], 4)
		end

		# Normalised diagonals

		@diagonal = 1

		if KB.key_down? Gosu::KbUp or KB.key_down? Gosu::KbDown

			if KB.key_down? Gosu::KbLeft or KB.key_down? Gosu::KbRight

				@is_diagonal = true
				@diagonal = 0.733

			end

		end

		if KB.key_down? Gosu::KB_LEFT_SHIFT or KB.key_down? Gosu::KB_RIGHT_SHIFT

			@player.y -= @player_fspeed * @diagonal if KB.key_down? Gosu::KbUp
			@player.y += @player_fspeed * @diagonal if KB.key_down? Gosu::KbDown

			@player.x += @player_fspeed * @diagonal if KB.key_down? Gosu::KbRight
			@player.x -= @player_fspeed * @diagonal if KB.key_down? Gosu::KbLeft

		else

			@player.y -= @player_speed * @diagonal if KB.key_down? Gosu::KbUp
			@player.y += @player_speed * @diagonal if KB.key_down? Gosu::KbDown

			@player.x += @player_speed * @diagonal if KB.key_down? Gosu::KbRight
			@player.x -= @player_speed * @diagonal if KB.key_down? Gosu::KbLeft

		end

		@player.x = @player.x.clamp(0 - @player_w/2, @SCREEN_WIDTH + @player_w/2)
		@player.y = @player.y.clamp(0 - @player_h/4, @SCREEN_HEIGHT + @player_h/4)

	end

	def UpdatePlayerShooting()

		if KB.key_down? Gosu::KB_Z

			@tick += 1

			#def initialize(bullet_sprite, hitbox_size, image_size, movement_speed, movement_angle, damage, is_enemy)

			#x, y, w, h, img, img_gap = nil, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = nil,
			#hitbox_size, image_size, movement_speed, movement_angle, damage, is_enemy

			if @tick % @player_shot_delay == 0

				@player_fire_sfx.play(volume = 0.5)

				if @rank > 400
					PlayerShot(5)
				elsif @rank > 300
					PlayerShot(4)
				elsif @rank > 200
					PlayerShot(3)
				elsif @rank > 100
					PlayerShot(2)
				else
					PlayerShot(1)
				end

			end

			if @tick > 99999

				@tick = 0

			end

		end

	end

	def PlayerShot(powerLevel)

		case powerLevel

			when 1

				if KB.key_down? Gosu::KB_LEFT_SHIFT or KB.key_down? Gosu::KB_RIGHT_SHIFT

					for angle in [250, 260, 270, 280, 290] do

						shot = Bullet.new(@player.x-16, @player.y, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 2, 2)
						Bullet.player << shot

					end

				else

					for angle in [230, 250, 270, 290, 310] do

						shot = Bullet.new(@player.x-16, @player.y, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 2, 2)
						Bullet.player << shot

					end

				end

			when 2

				if KB.key_down? Gosu::KB_LEFT_SHIFT or KB.key_down? Gosu::KB_RIGHT_SHIFT

					for angle in [240, 250, 260, 270, 280, 290, 300] do

						shot = Bullet.new(@player.x-16, @player.y, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 2, 2)
						Bullet.player << shot

					end

				else

					for angle in [260, 270, 280] do

						shot = Bullet.new(@player.x-16, @player.y, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 2, 2)
						Bullet.player << shot

					end

					for angle in [175, 200] do

						shot = Bullet.new(@player.x, @player.y-16, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 2, 2)
						Bullet.player << shot

					end

					for angle in [5, -20] do

						shot = Bullet.new(@player.x-32, @player.y-16, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 2, 2)
						Bullet.player << shot

					end
				end

			when 3

				if KB.key_down? Gosu::KB_LEFT_SHIFT or KB.key_down? Gosu::KB_RIGHT_SHIFT

					for angle in [220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320] do

						shot = Bullet.new(@player.x-16, @player.y, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 2, 2)
						Bullet.player << shot

					end

				else

					for angle in [250, 260, 270, 280, 290] do

						shot = Bullet.new(@player.x-16, @player.y, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 2, 2)
						Bullet.player << shot

					end

					for angle in [160, 180, 200] do

						shot = Bullet.new(@player.x, @player.y-16, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 2, 2)
						Bullet.player << shot

					end

					for angle in [340+5, 360+5, 380+5] do

						shot = Bullet.new(@player.x-32, @player.y-16, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 2, 2)
						Bullet.player << shot

					end
				end

			when 4

				if KB.key_down? Gosu::KB_LEFT_SHIFT or KB.key_down? Gosu::KB_RIGHT_SHIFT

					for angle in [220, 230, 240, 250, 255, 260, 265, 270, 275, 280, 285, 290, 300, 310, 320] do

						shot = Bullet.new(@player.x-16, @player.y, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 3, 3)
						Bullet.player << shot

					end

				else

					for angle in [250, 260, 270, 280, 290] do

						shot = Bullet.new(@player.x-16, @player.y, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 3, 3)
						Bullet.player << shot

					end

					for angle in [140, 160, 180, 200] do

						shot = Bullet.new(@player.x, @player.y-16, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 3, 3)
						Bullet.player << shot

					end

					for angle in [340-10, 360-10, 380-10, 400-10] do

						shot = Bullet.new(@player.x-24, @player.y-16, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 3, 3)
						Bullet.player << shot

					end
				end

			when 5

				if KB.key_down? Gosu::KB_LEFT_SHIFT or KB.key_down? Gosu::KB_RIGHT_SHIFT

					for angle in [220, 230, 240, 250, 255, 260, 265, 270, 275, 280, 285, 290, 300, 310, 320] do

						shot = Bullet.new(@player.x-32, @player.y, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 4, 4)
						Bullet.player << shot

					end

				else

					for angle in [250, 260, 270, 280, 290] do

						shot = Bullet.new(@player.x-32, @player.y, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 4, 4)
						Bullet.player << shot

					end

					for angle in [140, 160, 180, 200] do

						shot = Bullet.new(@player.x, @player.y, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 4, 4)
						Bullet.player << shot

					end

					for angle in [340-10, 360-10, 380-10, 400-10] do

						shot = Bullet.new(@player.x-24, @player.y-16, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 4, 4)
						Bullet.player << shot

					end
				end

			else

				if KB.key_down? Gosu::KB_LEFT_SHIFT or KB.key_down? Gosu::KB_RIGHT_SHIFT

					for angle in [250, 260, 270, 280, 290] do

						shot = Bullet.new(@player.x-16, @player.y, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 2, 2)
						Bullet.player << shot

					end

				else

					for angle in [230, 250, 270, 290, 310] do

						shot = Bullet.new(@player.x-16, @player.y, 1, 1, :fulltex_tile_playershot,
										img_gap = 1, sprite_cols = nil, sprite_rows = nil, mass = 1.0, retro = true,
										@pshot_hitbox_size, @pshot_image_size,
										38, angle, @player_dmg, false, 2, 2)
						Bullet.player << shot

					end

				end

		end
	end

	def UpdateObjects()

		UpdateShots()
		UpdateEnemies()

	end

	def UpdateValues()

		@density_rate = 1.0 + @rank/280.to_f # per rank
		@speed_rate = 1.0 + @rank/280.to_f # per rank

		@delay_rate = 1.0 - @rank/320.to_f
		@delay_rate = @delay_rate.clamp(0.4, 1.0)

		@move_speed_rate = 1.0 + @rank/250.to_f

		@timer_rate = 1.0 - @rank/600.to_f
		@timer_rate = @timer_rate.clamp(0.4, 1.0)

		@score = @score.round
		@score = (@score/10)*10

		@true_rank += 0.004
		@rank = @true_rank.floor
		@bg_y += 4

	end

	def UpdateShots()

		for shot in Bullet.player do
			shot.move_free(shot.movement_angle, shot.movement_speed)
			if shot.x < 0 - shot.w - @threshold or shot.x > @SCREEN_WIDTH + shot.w + @threshold or shot.y < 0 - shot.h - @threshold or shot.y > @SCREEN_HEIGHT + shot.h + @threshold
				Bullet.player.delete_at(Bullet.player.index(shot))
				shot = nil
			end
		end

		for shot in Bullet.enemy do
			shot.move_free(shot.movement_angle, shot.movement_speed)
			if shot.x < 0 - shot.w - @threshold or shot.x > @SCREEN_WIDTH + shot.w + @threshold or shot.y < 0 - shot.h - @threshold or shot.y > @SCREEN_HEIGHT + shot.h + @threshold
				Bullet.enemy.delete_at(Bullet.enemy.index(shot))
				shot = nil
			end
		end

	end

	def UpdateEnemies()

		for enemy in @enemies do

			enemy.move_free(enemy.movement_angle, enemy.movement_speed)

			enemy.autodelete_tick += 1
			enemy.fire_tick += 1

			if enemy.autodelete_tick >= enemy.autodelete_timer
				enemy.autodelete = true
			end

			if enemy.fire_tick.to_i % enemy.fire_timer.to_i == 0
				UpdateEnemyFire(enemy, enemy.type, enemy.args1, enemy.args2)
			end

			if enemy.autodelete == true
				if enemy.x < 0 - enemy.w or enemy.x > @SCREEN_WIDTH + enemy.w or enemy.y < 0 - enemy.h or enemy.y > @SCREEN_HEIGHT + enemy.h
					@enemies.delete_at(@enemies.index(enemy))
					enemy = nil
				end
			end

		end

	end

	def UpdateEnemyFire(enemy, type, args_1 = [], args_2 = [])

		#puts "received"
		# args_1 = [x_offset, y_offset, speed, is_aimed, angle, hitbox_size, img, image_size, scale_x = 1.0, scale_y = 1.0]
		# args_2 = [density, angle_difference]

		# Natashi: I'm stuff

		if args_1[3] == true
			args_1[4] = Gosu.angle(enemy.x + enemy.hitbox_size/2, enemy.y + enemy.hitbox_size/2,
			@player.x - @player_hitbox/2, @player.y - @player_hitbox/2) - 90
		end

		case type

			when "single"

				fire_single(enemy.x + enemy.hitbox_size/2 + args_1[0], enemy.y + enemy.hitbox_size/2 + args_1[1], args_1[2], 	args_1[4],
						args_1[5], args_1[6], args_1[7], args_1[8],
						args_1[9])

			when "spread"

				fire_spread(enemy.x + enemy.hitbox_size/2 + args_1[0], enemy.y + enemy.hitbox_size/2 + args_1[1], args_1[2], args_1[4],
						args_1[5], args_1[6], args_1[7], args_1[8],
						args_1[9],
						args_2[0], args_2[1])

			when "ring"

				fire_ring(enemy.x + enemy.hitbox_size/2 + args_1[0], enemy.y + enemy.hitbox_size/2 + args_1[1], args_1[2], args_1[4],
						args_1[5], args_1[6], args_1[7], args_1[8],
						args_1[9],
						args_2[0])

			when "custom"

				# Do nothing

			else

				fire_single(enemy.x + enemy.hitbox_size/2 + args_1[0], enemy.y + enemy.hitbox_size/2 + args_1[1], args_1[2], args_1[4],
						args_1[4], args_1[5], args_1[6], args_1[7],
						args_1[8])

		end

	end

	def UpdateEnemySpawns()

		@enemy_timer_tick += 1

		@timer = (120 * (1.0 - (@rank.to_f/170.0).to_f)).to_i
		@timer = @timer.clamp(5, 30)

		if @flying_wave_number >= 5
			@flying_wave_number = 0
		end

		if @enemy_timer_tick % @timer == 0 && CheckEnemyCount(5) && @is_spawn_flying_wave == false

			#@flying_wave_number = 4 # debug

			case @flying_wave_number

			when 0
				Wave1(12, (180*@timer_rate).ceil, 6.0, 7.5, 60)
				@flying_wave_number += 1
			when 1
				Wave2(3, (170*@timer_rate).ceil, 15, 4.5, 3.75, 60)
				@flying_wave_number += 1
			when 2
				Wave3(7*@density_rate, (60*@timer_rate).ceil, 11.0, 6.5, 45)
				@flying_wave_number += 1
			when 3
				Wave4(3, (90*@timer_rate).ceil, 5, 0.8, 4.0, 5.0, 75)
				#Wave4(8, 60, 11.0, 9.0, 30)
				@flying_wave_number += 1
			when 4
				Wave5(3*@density_rate, (180*@timer_rate), 10, 3, 4.0, 4.4, 100)
				@flying_wave_number += 1
			else
				#Wave1(12, 180, 4.0, 5.0, 40)
				@flying_wave_number == 0
			end

		end

		if @enemy_timer_tick >= 9999
			@enemy_timer_tick = 0
		end

	end

	# Aimed enemies from 3 lanes

	def Wave1(enemy_count, wave_timer, start_move_speed, start_bullet_speed, start_bullet_delay)

		enemy_spawn_delay = (wave_timer/enemy_count).ceil
		enemy_count_per_lane = (enemy_count/3).ceil

		xSpawn1 = @SCREEN_WIDTH/8
		xSpawn2 = @SCREEN_WIDTH/2
		xSpawn3 = @SCREEN_WIDTH/8 * 7

		Scheduler.start do

			@is_spawn_flying_wave = true
			lane = 0
			while lane < 3
				enm = 0
				while enm < enemy_count_per_lane
					AimPopcornSingle([xSpawn1, xSpawn2, xSpawn3][lane], -36, bulletSpeed = start_bullet_speed * @speed_rate, moveSpeed = start_move_speed * @move_speed_rate, moveAngle = 90, fireDelay = start_bullet_delay * @delay_rate)
					Scheduler.wait(enemy_spawn_delay)
					enm += 1
				end
				lane += 1
			end
			@is_spawn_flying_wave = false

		end

	end

	# Slower enemies that fire rings, 2 laners

	def Wave2(enemy_duo_count, wave_timer, start_bullet_density, start_move_speed, start_bullet_speed, start_bullet_delay)

		enemy_spawn_delay = (wave_timer/enemy_duo_count).ceil

		xSpawn1 = @SCREEN_WIDTH/2 - @SCREEN_WIDTH/6
		xSpawn2 = @SCREEN_WIDTH/2 + @SCREEN_WIDTH/6

		Scheduler.start do

			@is_spawn_flying_wave = true

			lane = 0

			while lane < enemy_duo_count

				x_variant = rand(-80...80)

				AimRingSingle(xSpawn1 + x_variant, -36,
					ringDensity = start_bullet_density * @density_rate,
					bulletSpeed = start_bullet_speed * @speed_rate,
					moveSpeed = start_move_speed * @move_speed_rate, 90,
					fireDelay = start_bullet_delay * @delay_rate)

				AimRingSingle(xSpawn2 + x_variant, -36,
					ringDensity = start_bullet_density * @density_rate,
					bulletSpeed = start_bullet_speed * @speed_rate,
					moveSpeed = start_move_speed * @move_speed_rate, 90,
					fireDelay = start_bullet_delay * @delay_rate)

				Scheduler.wait(enemy_spawn_delay)

				lane += 1

			end

			@is_spawn_flying_wave = false

		end

	end

	# Fast aimed enemies from both sides

	def Wave3(enemy_count_per_lane, wave_timer, start_move_speed, start_bullet_speed, start_bullet_delay)

		enemy_spawn_delay = (wave_timer/3).ceil

		ySpawn1 = @SCREEN_HEIGHT/10
		ySpawn2 = 2*@SCREEN_HEIGHT/10 + rand(-30...30)
		ySpawn3 = 3*@SCREEN_HEIGHT/10 + rand(-30...30)

		xSpawnLeft = -24
		xSpawnRight = @SCREEN_WIDTH + 24

		Scheduler.start do

			@is_spawn_flying_wave = true

			lane = 0
			count = 0

			while lane < 3

				x = [xSpawnLeft, xSpawnRight, xSpawnLeft][lane]
				y = [ySpawn1, ySpawn2, ySpawn3][lane]
				move_angle = [30, 150, 30][lane]

				while count < enemy_count_per_lane

					AimPopcornSingle(x, y, start_bullet_speed * @speed_rate, start_move_speed * @move_speed_rate, move_angle, start_bullet_delay * @delay_rate, enmHP = 70)
					count += 1

					Scheduler.wait(6)

				end

				lane += 1
				count = 0

				Scheduler.wait(enemy_spawn_delay)

			end

			@is_spawn_flying_wave = false

		end

	end

	# Lanes of enemies

	def Wave4(enemy_fleet_count, wave_timer, start_bullet_density, start_bullet_spread, start_move_speed, start_bullet_speed, start_bullet_delay)

		enemy_spawn_delay = (wave_timer/enemy_fleet_count).ceil

		xSpawn = @SCREEN_WIDTH/2

		Scheduler.start do

			# Six enemies per fleet

			@is_spawn_flying_wave = true

			fleet = 0

			while fleet < enemy_fleet_count

				final_x = xSpawn + rand(-90...90)
				final_x = final_x.clamp(@SCREEN_WIDTH/4, 3*@SCREEN_WIDTH/4)

				x_arr = [
					final_x - 100, final_x + 100,
					final_x - 120, final_x + 120,
					final_x - 140, final_x + 140
				]

				i = 0

				while i < x_arr.length

					AimSpreadSingle(x_arr[i], -36,
						spreadDensity = start_bullet_density * @density_rate,
						spreadLevel = start_bullet_density * @density_rate * 0.8,
						bulletSpeed = start_bullet_speed * @speed_rate,
						moveSpeed = start_move_speed * @move_speed_rate, 90,
						fireDelay = start_bullet_delay * @delay_rate)

					AimSpreadSingle(x_arr[i+1], -36,
						spreadDensity = start_bullet_density * @density_rate,
						spreadLevel = start_bullet_density * @density_rate * 0.8,
						bulletSpeed = start_bullet_speed * @speed_rate,
						moveSpeed = start_move_speed * @move_speed_rate, 90,
						fireDelay = start_bullet_delay * @delay_rate)

					Scheduler.wait(enemy_spawn_delay)

					i += 2

				end

				fleet += 1

			end

			@is_spawn_flying_wave = false

		end

	end

	def Wave5(enemy_count, wave_timer, start_bullet_density, start_ring_count, start_move_speed, start_bullet_speed, start_bullet_delay)

		enemy_spawn_delay = (wave_timer/enemy_count).ceil

		xSpawn1 = @SCREEN_WIDTH/2 - @SCREEN_WIDTH/6
		xSpawn2 = @SCREEN_WIDTH/2 + @SCREEN_WIDTH/6

		Scheduler.start do

			@is_spawn_flying_wave = true

			lane = 0

			while lane < enemy_count

				x_variant = rand(-80...80)
				counter = 0
				if lane % 2 == 0
					counter = 1
				end
				# #CustomRing01(xSpawn1 + x_variant, -36,
				# 	ringDensity = 16, spreadCount = 3, bulletSpeed = 2.0, moveSpeed = 3.0, moveAngle = 90, fireDelay = 60, enmHP = 300)

				CustomRing01([xSpawn1, xSpawn2][counter] + x_variant, -36,
					ringDensity = start_bullet_density * @density_rate, ringCount = start_ring_count * @density_rate,
					bulletSpeed = start_bullet_speed * @speed_rate,
					moveSpeed = start_move_speed * @move_speed_rate,
					moveAngle = [60, 120][counter],
					fireDelay = start_bullet_delay * @delay_rate)

				Scheduler.wait(enemy_spawn_delay)

				lane += 1

			end

			@is_spawn_flying_wave = false

		end

	end

	# Award score

	def AwardScore(enm, x, y)

		dist = Gosu.distance(@player.x, @player.y, x, y)
		#puts(dist)
		lerp_value = enm.pointblank_distance/dist
		lerp_value = lerp_value.clamp(0.1, 1.0)
		lerp_value = lerp_value.round(1)
		final_score = 10
		#puts(lerp_value)

		colour = 0x007BEF
		scale = 2
		rank_boost = 0.0

		if lerp_value >= 0.7

			final_score = enm.max_score
			colour = 0xFFBC06
			scale = 3
			rank_boost = 0.11

		elsif lerp_value <= 0.2

			final_score = enm.min_score
			rank_boost = 0.01

		else

			final_score = lerp_linear(enm.min_score, enm.max_score, lerp_value)
			rank_boost = lerp_linear(0.01, 0.07, lerp_value)

		end

		@true_rank += rank_boost
		@score += ((final_score/10) * 10).ceil # Round to zero

		ScoreTextEffect(x, y, ((final_score/10) * 10).ceil, colour, scale)

	end

	def ScoreTextEffect(x, y, value, colour, scale)

		text = ScoreLabel.new(x, y, font = @font, text = "+#{value}", text_color = 0xffffff, disabled_text_color = 0xffffff, scale_x = scale, scale_y = scale, anchor = nil, 30, flash_colour = colour)

		@score_text_array << text

	end

	def AwardExtend()

		if @score >= @to_next_extend

			@extend_sfx.play

			@player_hp += 1
			@true_rank += 20

			text = ScoreLabel.new(@player.x, @player.y, font = @font, text = "EXTEND!", text_color = 0xFF8E8E, disabled_text_color = 0xffffff, scale_x = 3, scale_y = 3, anchor = nil, 60, 0xffffff)
			@score_text_array << text
			@to_next_extend += 10000000

		end

	end

	def UpdateEffects()
		for effect in @effect_array
			effect.update
			if effect.dead
				@effect_array.delete_at(@effect_array.index(effect))
			end
		end
	end

	# collisions

	def CheckCollision()

		# Check if player bullet hit enemy
		# Delete enemy if enemy hp reached 0

		for shot in Bullet.player
			for enemy in @enemies
				if shot != nil and shot.bounds.intersect? enemy.bounds
					Bullet.player.delete_at(Bullet.player.index(shot))
					shot = nil
					enemy.hp -= @player_dmg
				end
			end
		end

		if @enemies.length > 0
			for enemy in @enemies
				if enemy != nil
					if enemy.hp <= 0
						AwardScore(enemy, enemy.x, enemy.y)
						DestroyEffect(enemy)
						@enemies.delete_at(@enemies.index(enemy))
						enemy = nil
						#@rank += 3
					end
				end
			end
		end

		# Player damage
		for shot in Bullet.enemy
			if shot.bounds.intersect? @player.bounds and shot != nil
				Bullet.enemy.delete_at(Bullet.enemy.index(shot))
				shot = nil
				if !@is_player_invincible
					@damage_sfx.play
					PlayerDamage()
				end
			end
		end

	end

	def PlayerDamage

		Scheduler.start do

			@player_hits += 1
			@player_hp -= 1
			if @player_hp < 0
				@is_game_over = true
				#GameOverScreen()
			end
			@is_player_invincible = true
			@player_iframes = 120
			while @player_iframes > 0
				Scheduler.wait(1)
				@player_iframes -= 1
			end
			@is_player_invincible = false

		end

	end

	#caravan

	def CheckEnemyCount(threshold)
		result = false
		if @enemies.length < threshold
			result = true
		end
		return result
	end

	# draw

	def draw

		# Draw functions

		#Label.draw
		DrawGameObjects()
		DrawBackground()
		DrawUI()

		DrawScoreToast()
		DrawEffects()

		if @is_start_screen
			StartScreen()
		elsif @is_game_over
			GameOverScreen()
			@name_input.draw(0xff, ZOrder::HITBOX)
		end

	end

	def DrawUI()

		# Lives
		life = 0
		alpha = 180

		while life < @player_hp
			#@hp_sprite_array[life].visible? = true

			alpha = 125

			if @player.y <= @SCREEN_HEIGHT - 64
				alpha = 255
			end

			@hp_sprite_array[life].draw(map = nil, scale_x = 2, scale_y = 2, alpha, color = 0xffffff, angle = nil, flip = nil, z_index = ZOrder::UI, round = false)
			life += 1
		end

		# Score

		@th.write_line "SCORE", 10, 10, :left, 0xffffff, alpha = 0xff, effect = :border, effect_color = 0x000000, effect_size = 3, effect_alpha = 0xff, z_index = ZOrder::UI, scale_x = 1.5, scale_y = 1.5
		@th.write_line "#{@score}", 10, 35, :left, 0xffffff, alpha = 0xff, effect = nil, effect_color = 0x000000, effect_size = 4, effect_alpha = 0xff, z_index = ZOrder::UI, scale_x = 2, scale_y = 2

		@th.write_line "EXTEND+: #{@to_next_extend}", 10, 70, :left, 0xFF9191, alpha = 0xff, effect = :border, effect_color = 0x6A0000, effect_size = 1.5, effect_alpha = 0xff, z_index = ZOrder::UI, scale_x = 1, scale_y = 1

		# Rank
		@th.write_line "RANK", 440, 570, :center, 0xffffff, alpha = 0xff, effect = :border, effect_color = 0x000000, effect_size = 4, effect_alpha = 0xff, z_index = ZOrder::UI, scale_x = 1.5, scale_y = 1.5
		@th.write_line "#{@rank}", 440, 595, :center, 0xffffff, alpha = 0xff, effect = nil, effect_color = 0, effect_size = 1, effect_alpha = 0xff, z_index = ZOrder::UI, scale_x = 2, scale_y = 2

	end

	def DrawBackground()

		# Draw image above
		@bg_local_y = @bg_y % - @SCREEN_HEIGHT
		@bg.draw(@bg_x, @bg_local_y, 0)

		# Draw image below (decrement and reset via modulus)
		if @bg_local_y < 0
			#puts @bg_local_y + @SCREEN_HEIGHT
			@bg.draw(@bg_x, @bg_local_y + @SCREEN_HEIGHT, 0)
		end

		#@coordinates.draw(0, 0, 1)

	end

	def DrawGameObjects()

		# Player

		unless @player_hp < 0
			@player.draw(map = nil, scale_x = 2, scale_y = 2, alpha = 0xff, color = 0xffffff, angle = nil, flip = nil, z_index = ZOrder::PLAYER)
		end

		# Enemy

		for enemy in @enemies do
			if enemy != nil
				enemy.draw(map = nil, enemy.scale_x, enemy.scale_y, alpha = 0xff, color = 0xffffff, angle = enemy.movement_angle + 90, flip = nil, z_index = enemy.z_order)
			end
		end

		# Hitbox visualisation

		#draw_rect(@player.bounds.x, @player.bounds.y, @player_hitbox, @player_hitbox, Gosu::Color::FUCHSIA, ZOrder::HITBOX, mode=:default)

		# Shots

		for shot in Bullet.player do

			if shot != nil

				shot.img_gap = Vector.new(2, 2)

				shot.draw(map = nil, shot.scale_x, shot.scale_y, alpha = 0xff, color = 0xffffff, angle = shot.movement_angle + 90, flip = nil, z_index = ZOrder::PLAYERSHOT, round = true)

				#draw_rect(shot.bounds.x, shot.bounds.y, @pshot_hitbox_size, @pshot_hitbox_size, Gosu::Color::BLUE, ZOrder::BACKGROUND, mode=:default)

			elsif shot == nil

			end

		end

		for shot in Bullet.enemy do
			if shot != nil

				shot.draw(map = nil, shot.scale_x, shot.scale_y, alpha = 0xff, color = 0xffffff, angle = shot.movement_angle + 90, flip = nil, z_index = ZOrder::ENMSHOT, round = true)

				#draw_rect(shot.bounds.x, shot.bounds.y, shot.hitbox_size, shot.hitbox_size, Gosu::Color::RED, ZOrder::HITBOX, mode=:default)

			elsif shot == nil

			end
		end

	end

	def DrawScoreToast()

		for text in @score_text_array
			text.text_timer -= 1
			if text.text_timer <= 0
				@score_text_array.delete_at(@score_text_array.index(text))
			else
				text.set_position(text.x-2, text.y-2)
				if text.text_timer % 7 == 0
					text.draw(255, ZOrder::UI, text.flash_colour)
				else
					text.draw(255, ZOrder::UI, text.text_color)
				end
			end
		end

	end

	def DrawEffects()
		for effect in @effect_array
			if !effect.dead
				effect.draw
			end
		end
	end

	def DestroyEffect(enemy)
		boom = Effect.new(enemy.x - enemy.image_size, enemy.y - enemy.image_size, img = :enemy_boom, sprite_cols = 5, sprite_rows = 3, interval = 2, indices = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], lifetime = 2 * 13, sound = :enemyboom, sound_ext = '.wav', sound_volume = 0.5)
		@effect_array << boom
	end

	# Screens

	def HandleGameStart()

		if KB.key_pressed? Gosu::KB_RETURN
			@is_start_screen = false
			@game_music.play(looping = true)
			@game_music.volume = 0.25
		end

	end

	def HandlePause()

		if KB.key_pressed? Gosu::KB_P
			@is_paused = !@is_paused
		end

	end

	def HandleScoreRecording()

		@player_name = @name_input.text
		@game_music.stop

		#puts(@player_name)

		if KB.key_pressed? Gosu::KB_RETURN and @player_name != ""
			RecordScore(@player_name, @score, @rank)
			close
		end

	end

	def StartScreen()

		@th.write_line "SEA OF TRANQUILITY", 240, 200, :center, 0xB4BFFF, alpha = 0xff, effect = :border, effect_color = 0x0019AD, effect_size = 4, effect_alpha = 255, z_index = ZOrder::HITBOX, scale_x = 2, scale_y = 2
		@th.write_line "THIS IS \"HIGH TENSION SHOOTING GAME\".", 240, 240, :center, 0xffffff, alpha = 0xff, effect = :border, effect_color = 0x000000, effect_size = 4, effect_alpha = 255, z_index = ZOrder::HITBOX, scale_x = 1, scale_y = 1

		@th.write_line "ARROW KEYS TO MOVE", 240, 300, :center, 0x88FF99, alpha = 0xff, effect = :border, effect_color = 0x000000, effect_size = 3, effect_alpha = 255, z_index = ZOrder::HITBOX, scale_x = 1, scale_y = 1
		@th.write_line "Z TO FIRE", 240, 320, :center, 0x88FF99, alpha = 0xff, effect = :border, effect_color = 0x000000, effect_size = 3, effect_alpha = 255, z_index = ZOrder::HITBOX, scale_x = 1, scale_y = 1
		@th.write_line "SHIFT TO FOCUS", 240, 340, :center, 0x88FF99, alpha = 0xff, effect = :border, effect_color = 0x000000, effect_size = 3, effect_alpha = 255, z_index = ZOrder::HITBOX, scale_x = 1, scale_y = 1

		@th.write_line "AS RANK CLIMBS, SO DOES THE ENEMY FIRE", 240, 380, :center, 0xFF8B88, alpha = 0xff, effect = :border, effect_color = 0x000000, effect_size = 3, effect_alpha = 255, z_index = ZOrder::HITBOX, scale_x = 1, scale_y = 1
		@th.write_line "EXTENDS EVERY 10 MILLION POINTS", 240, 400, :center, 0xFF8B88, alpha = 0xff, effect = :border, effect_color = 0x000000, effect_size = 3, effect_alpha = 255, z_index = ZOrder::HITBOX, scale_x = 1, scale_y = 1
		@th.write_line "HOW LONG WILL YOU LAST?", 240, 420, :center, 0xffffff, alpha = 0xff, effect = :border, effect_color = 0x000000, effect_size = 3, effect_alpha = 255, z_index = ZOrder::HITBOX, scale_x = 1, scale_y = 1
		@th.write_line "PRESS ENTER TO INITIATE", 240, 470, :center, 0xffffff, alpha = 0xff, effect = :border, effect_color = 0x000000, effect_size = 3, effect_alpha = 255, z_index = ZOrder::HITBOX, scale_x = 1.5, scale_y = 1.5


	end

	def GameOverScreen()

		@th.write_line "THE GAME HAS BEEN OVER", 240, 240, :center, 0xffffff, alpha = 0xff, effect = :border, effect_color = 0x000000, effect_size = 4, effect_alpha = 255, z_index = ZOrder::HITBOX, scale_x = 2, scale_y = 2
		@th.write_line "HONOR THE FALLEN PILOT", 240, 280, :center, 0xffffff, alpha = 0xff, effect = :border, effect_color = 0x000000, effect_size = 4, effect_alpha = 255, z_index = ZOrder::HITBOX, scale_x = 2, scale_y = 2

		@th.write_line "SCORE: #{@score}", 240, 400, :center, 0xffffff, alpha = 0xff, effect = :border, effect_color = 0x000000, effect_size = 4, effect_alpha = 255, z_index = ZOrder::HITBOX, scale_x = 1, scale_y = 1
		@th.write_line "RANK: #{@rank}", 240, 420, :center, 0xffffff, alpha = 0xff, effect = :border, effect_color = 0x000000, effect_size = 4, effect_alpha = 255, z_index = ZOrder::HITBOX, scale_x = 1, scale_y = 1

		@th.write_line "PRESS ENTER WHEN YOU ARE FINISHED", 240, 440, :center, 0xffffff, alpha = 0xff, effect = :border, effect_color = 0x000000, effect_size = 2, effect_alpha = 255, z_index = ZOrder::HITBOX, scale_x = 1, scale_y = 1

		@th.write_line "MAY YOU AT LAST FIND PEACE", 240, 480, :center, 0xffffff, alpha = 0xff, effect = :border, effect_color = 0x000000, effect_size = 2, effect_alpha = 255, z_index = ZOrder::HITBOX, scale_x = 1, scale_y = 1

	end

end

game = MyGame.new
game.show
