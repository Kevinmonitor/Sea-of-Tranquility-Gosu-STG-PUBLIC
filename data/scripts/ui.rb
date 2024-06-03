require 'minigl'

include MiniGL

class ScoreLabel < Label

	attr_accessor :x, :y,
	:font, :text,
	:text_color, :disabled_text_color,
	:scale_x, :scale_y, :anchor,
	:text_timer,
	:flash_colour

	def initialize(x = nil, y = nil,
				font = nil, text = nil,
				text_color = 0, disabled_text_color = 0,
				scale_x = 1, scale_y = 1, anchor = nil,
				text_timer = 10, flash_colour = 0xffffff)

		super(x, y, font, text, text_color, disabled_text_color, scale_x, scale_y, anchor)

		@text_timer = text_timer
		@flash_colour = flash_colour

	end

end
