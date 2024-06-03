# creates - or opens - the scorefile

# scorefile format

# title
# empty line
# id - player name - score - rank

def RecordScore(player_name, score, rank)

	# with the do/end block, the file will close when we exit the block.

	if !File.exist?("score.txt")
		File.open("score.txt", "w+") do |f|
			f.puts("--- BRAVE PILOTS RANKING ---")
			f.puts # empty line...
			f.puts("1: #{player_name} - SCORE #{score} - RANK #{rank}")
		end
	else
		File.open("score.txt", "r+") do |f|
			# We count the total number of lines in this scorefile.
			file_data = f.readlines.map(&:chomp)
			# We iterate through them then record a new score on the next empty line.

			for a in 1..file_data.length
				f.gets()
			end

			f.puts("#{file_data.length-1}: #{player_name} - SCORE #{score} - RANK #{rank}")

		end
	end

end
