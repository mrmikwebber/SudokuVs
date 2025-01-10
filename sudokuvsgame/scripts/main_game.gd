extends Node2D

@onready var grid:GridContainer = $GridContainer

var gameGrid = []
var puzzle = []
var playablePuzzle = []
var alreadyScoredTable = []
var staticScoredTable = []
var aiPuzzle = []
var permanantNums = []
var solution_grid = []
var selectedButton:Vector2i = Vector2(-1, -1)
var playerTimer : Timer = Timer.new()
var playerTurn = true
var enemyTimer : Timer = Timer.new()
var enemyTurn = false
var playerScore = 0
var numberOfAIBeat = 0
var currentFloor = 1
var currentRoom = 1
var aiScore = 0
var playerCheckButtonPressedCount = 0
var aiCheckButtonPressedCount = 0
var AI_MOVE_DELAY = 3

const GRID_SIZE = 9
var solution_count = 0
var select_button_answer = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bind_selectedGrid_button_actions()
	updateStaticLabels()
	setupCheckButton()
	init_game(Settings.STARTING_DIFFICULTY)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Get the time left in seconds
	var player_time_left = playerTimer.get_time_left()
	var enemy_time_left = enemyTimer.get_time_left()
	
	# Convert to an integer number of seconds
	var player_total_seconds = int(floor(player_time_left))
	var enemy_total_seconds = int(floor(enemy_time_left))
	
	# Calculate minutes and remaining seconds
	var player_minutes = player_total_seconds / 60
	var player_seconds = player_total_seconds % 60
	
	var enemy_minutes = enemy_total_seconds / 60
	var enemy_seconds = enemy_total_seconds % 60
	
	# Format as MM:SS (e.g., 02:05)
	$PlayerTimerLabel.text = "%02d:%02d" % [player_minutes, player_seconds]
	$EnemyTimerLabel.text = "%02d:%02d" % [enemy_minutes, enemy_seconds]
	
	if enemyTurn:
		toggle_timer_pause(enemyTimer, false)
		toggle_timer_pause(playerTimer, true)
		$CheckButton.disabled = true
		_playAIMove()
	
	if playerTurn:
		toggle_timer_pause(playerTimer, false)
		toggle_timer_pause(enemyTimer, true)
		$CheckButton.disabled = false
	
	pass

func reset_game():
	clear_grid()
	gameGrid = []
	puzzle = []
	playablePuzzle = []
	alreadyScoredTable = []
	staticScoredTable = []
	aiPuzzle = []
	permanantNums = []
	solution_grid = []
	selectedButton = Vector2(-1, -1)
	playerTurn = true
	enemyTimer = Timer.new()
	enemyTurn = false
	playerScore = 0
	aiScore = 0
	AI_MOVE_DELAY = 3
	solution_count = 0
	select_button_answer = 0

func setupCheckButton():
	$CheckButton.pressed.connect(_checkButtonPressed)
	
func _checkButtonPressed():
	playerCheckButtonPressedCount += 1
	playerTimer.start(playerTimer.get_time_left() - (playerCheckButtonPressedCount * 8))
	checkBoard(playablePuzzle, Color.SEA_GREEN, Color.DARK_RED)
				 
func checkBoard(checkedPuzzle, correctColor, incorrectColor):
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var btn = gameGrid[row][col] as Button
			var stylebox:StyleBoxFlat = btn.get_theme_stylebox("normal").duplicate(true)
			if puzzle[row][col] == 0 and checkedPuzzle[row][col] != 0:
				if checkedPuzzle[row][col] == solution_grid[row][col]:
					stylebox.bg_color = correctColor
				else:
					stylebox.bg_color = incorrectColor
				btn.add_theme_stylebox_override("normal", stylebox)

func init_game(difficulty: int):
	print("Starting Game with Difficulty ", difficulty)
	_create_empty_grid()
	_fill_grid(solution_grid)
	_create_puzzle(Settings.STARTING_DIFFICULTY)
	_populate_grid()
	_populateAlreadyScoreTable()
	if numberOfAIBeat == 0:
		_createPlayerTimer()
	_createEnemyTimer()
	print(playablePuzzle)
	
func updateStaticLabels():
	$CurrentRoom.text = "Current Room: " + str(currentRoom)
	$CurrentFloor.text = "Current Floor: " + str(currentFloor)
	
func toggle_timer_pause(timer: Timer, pauseTimer: bool):
	if pauseTimer:
		timer.set_paused(true)
	else: 
		timer.set_paused(false)
		timer.start(timer.get_time_left())	
	
func _playAIMove():
	enemyTurn = false
	var aiMove = await ai_Move()
	if aiMove:
		print('MOVING')
	return

func ai_Move():
	var rng = RandomNumberGenerator.new()
	
	await get_tree().create_timer(rng.randf_range(0.5, 8)).timeout
	#Determine AI Move
	
	var ans = find_one_forced_move(aiPuzzle)
	
	if Settings.STARTING_DIFFICULTY > 6:
		ans = solve_step_by_step(aiPuzzle)
	
	if Settings.blunder_only:
		ans = ai_blunder_move(aiPuzzle)
		
	var blunderChance = rng.randf_range(0, 1.0)
	var checkBoardChance = rng.randf_range(0, 1.0)
	
	
	print(blunderChance)
	print(Settings.BLUNDER_CHANCE)
	print('-----------------')
	print(checkBoardChance)
	print(Settings.CHECK_BOARD_CHANCE)
	
	if checkBoardChance < Settings.CHECK_BOARD_CHANCE:
		aiCheckButtonPressedCount += 1
		enemyTimer.start(enemyTimer.get_time_left() - (aiCheckButtonPressedCount * 8))
		checkBoard(aiPuzzle, Color.SKY_BLUE, Color.CORAL)
	
	if blunderChance < Settings.BLUNDER_CHANCE:
		ans = ai_blunder_move(aiPuzzle)
	
	if ans.size() == 0:
		return false
	
	var row = ans[0]
	var col = ans[1]
	var num = ans[2]
	print('AI Placed', num, " at (", row, ",", col, ")")
	_on_ai_place_number(row, col, num) 
	return true;
	
func ai_blunder_move(puzzle_grid):
	var empty_cells = get_empty_cells(puzzle_grid)
	if empty_cells.size() == 0:
		return false
	var random_cell = empty_cells[randi() % empty_cells.size()]
	var row = random_cell[0]
	var col = random_cell[1]
	
	var guess_num = randi_range(1,GRID_SIZE)
	return [row, col, guess_num]

func get_empty_cells(puzzle_grid):
	var empty_cells = []
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			if puzzle_grid[row][col] == 0:
				empty_cells.append(Vector2(row, col))
	return empty_cells

	
func find_one_forced_move(puzzle_grid):
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			if puzzle_grid[row][col] == 0 and not alreadyScoredTable[row][col]:
				# Count possible numbers
				var candidates = []
				for num in range(1,10):
					if is_valid(puzzle_grid, row, col, num):
						candidates.append(num)
				if candidates.size() == 1:
					# This is a forced move
					return [row, col, candidates[0]]
	return []  # No forced move found
	
func solve_step_by_step(puzzle_grid):
	while true:
		var move = find_one_forced_move(puzzle_grid)
		if move.size() == 0:
			break
		var row = move[0]
		var col = move[1]
		var num = move[2]
		print('Forced Moved Returning')
		return [row, col, num] 
	
	var bestPoint = find_cell_with_fewest_candidates(puzzle_grid)
	var best_row = bestPoint[0]
	var best_col = bestPoint[1]
	if best_row == -1:
		return false
		
	var candidates = get_valid_candidates(grid, best_row, best_col)
	for candidate in candidates:
		print("Complicated returning")
		return [best_row, best_col, candidate]
	# If no candidate leads to a solution, return false
	return false
	
		
func find_cell_with_fewest_candidates(puzzle_grid) -> Vector2:
	var best_row = -1
	var best_col = -1
	var min_count = GRID_SIZE + 1  # More than max possible (9)

	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			if puzzle_grid[row][col] == 0 and not alreadyScoredTable[row][col]:
				var count = 0
				for num in range(1, 10):
					if is_valid(puzzle_grid, row, col, num):
						count += 1
				if count < min_count:
					min_count = count
					best_row = row
					best_col = col
	return Vector2(best_row, best_col)
	
	
func _createPlayerTimer():
	add_child(playerTimer)
	playerTimer.one_shot = true
	playerTimer.autostart = false
	playerTimer.timeout.connect(_playerTimer_Timeout)
	playerTimer.start(Settings.PLAYER_TIME * 60)
	
func _createEnemyTimer():
	add_child(enemyTimer)
	enemyTimer.one_shot = true
	enemyTimer.autostart = false
	enemyTimer.set_paused(true)
	enemyTimer.timeout.connect(_enemyTimer_Timeout)
	enemyTimer.start(((0.4667 + (0.22 * (Settings.STARTING_DIFFICULTY * 4))) * 60) / 2)
	
func incrementRoom():
	currentRoom += 1
	if currentRoom == 5:
		currentFloor += 1
		currentRoom = 1
	
func _playerTimer_Timeout():
	print('Game Over')
	get_tree().quit()
	
func _enemyTimer_Timeout():
	print('You Win!')
	print('Youre Score is: ', "%0.4d" % playerScore)
	print('AI Score is: ', "%0.4d" % aiScore)
	numberOfAIBeat += 1
	incrementRoom()
	updateStaticLabels()
	reset_game()
	init_game(Settings.STARTING_DIFFICULTY + 1) 
	
func _populateAlreadyScoreTable():
	for i in range(GRID_SIZE):
		var row = []
		for j in range(GRID_SIZE):
			if puzzle[i][j] != 0:
				row.append(true)
			else:
				row.append(false)
		alreadyScoredTable.append(row)
	
func _populate_grid():
	gameGrid = []
	for i in range(GRID_SIZE):
		var row = []
		for j in range(GRID_SIZE):
			row.append(create_button(Vector2(i,j)))
		gameGrid.append(row)
			
			
func _input(ev):
	if ev is InputEventKey:
		if Input.is_key_pressed(KEY_1): _on_numberKey_pressed(1)
		if Input.is_key_pressed(KEY_2): _on_numberKey_pressed(2)
		if Input.is_key_pressed(KEY_3): _on_numberKey_pressed(3)
		if Input.is_key_pressed(KEY_4): _on_numberKey_pressed(4)
		if Input.is_key_pressed(KEY_5): _on_numberKey_pressed(5)
		if Input.is_key_pressed(KEY_6): _on_numberKey_pressed(6)
		if Input.is_key_pressed(KEY_7): _on_numberKey_pressed(7)
		if Input.is_key_pressed(KEY_8): _on_numberKey_pressed(8)
		if Input.is_key_pressed(KEY_9): _on_numberKey_pressed(9)
		if Input.is_key_pressed(KEY_BACKSPACE): _on_numberKey_pressed(0)
		if Input.is_key_pressed(KEY_C): playerTimer.set_paused(true)

func _create_empty_grid():
	solution_grid = []
	for i in range(GRID_SIZE):
		var row = []
		for j in range(GRID_SIZE):
			row.append(0)
		solution_grid.append(row)
		

func _create_puzzle(difficulty):
	puzzle = solution_grid.duplicate(true)
	var removals = min(difficulty * 4, 64) # Max removals for solvability
	var positions = []
	
	# Precompute all positions and shuffle them
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			positions.append(Vector2(row, col))
	positions.shuffle()

	for pos in positions:
		if removals <= 0:
			break
		var row = pos.x
		var col = pos.y
		if puzzle[row][col] != 0:
			var temp = puzzle[row][col]
			puzzle[row][col] = 0
			if not _is_unique_solution(puzzle):
				puzzle[row][col] = temp # Revert if not unique
			else:
				removals -= 1
	playablePuzzle = puzzle.duplicate(true)
	aiPuzzle = puzzle.duplicate(true)
	return puzzle
	

func _is_unique_solution(puzzle_grid):
	solution_count = 0
	try_to_solve_grid(puzzle_grid)
	return solution_count == 1
#	
	
func try_to_solve_grid(puzzle_grid):
	if solution_count > 1:
		return
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			if puzzle_grid[row][col] == 0:
				for num in range(1,10):
					if is_valid(puzzle_grid, row, col, num):
						puzzle_grid[row][col] = num
						try_to_solve_grid(puzzle_grid)
						puzzle_grid[row][col] = 0
				return
	solution_count += 1
	if solution_count > 1:
		return
		
func try_to_solve_grid_ai(puzzle_grid):
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			if puzzle_grid[row][col] == 0:
				for num in range(1,10):
					if is_valid(puzzle_grid, row, col, num):
						return
						puzzle_grid[row][col] = num
						try_to_solve_grid_ai(puzzle_grid)
						puzzle_grid[row][col] = 0
				return
	solution_count += 1
	if solution_count > 1:
		return

func clear_grid():
	for n in grid.get_children():
		grid.remove_child(n)
		n.queue_free()

func get_column(grd, col):
	var col_list = []
	for i in range(GRID_SIZE):
		col_list.append(grd[i][col])
	return col_list
	
func get_subgrid(grd, row, col):
	var subgrid = []
	var start_row = (row / 3) * 3
	var start_col = (col / 3) * 3
	for r in range(start_row, start_row + 3):
		for c in range(start_col, start_col + 3):
			subgrid.append(grd[r][c])
	return subgrid

func is_valid(grd, row, col, num):
	return (
		num not in grd[row] and
		num not in get_column(grd, col) and 
		num not in get_subgrid(grd, row, col)
	)

func _fill_grid(grid_obj):
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			if grid_obj[i][j] == 0:
				var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]
				numbers.shuffle()
				for num in numbers:
					if is_valid(grid_obj, i, j, num):
						grid_obj[i][j] = num
						if _fill_grid(grid_obj):
							return true
						grid_obj[i][j] = 0
				return false
	return true

func create_button(pos:Vector2i):
	var row = pos[0]
	var col = pos[1]
	var ans = solution_grid[row][col]
	
	var button = Button.new()
	if puzzle[row][col] != 0:
		button.text = str(puzzle[row][col])
	button.set("theme_override_font_sizes/font_size", 32)
	button.set("theme_override_colors/font_color", Color.BLACK)
	button.custom_minimum_size = Vector2(52,52)
	
		# Create a StyleBoxFlat for the button's appearance
	var stylebox = StyleBoxFlat.new()

	# Set default border widths and colors
	var border_width = 1
	var thick_border = 4
	stylebox.border_color = Color.BLACK
	stylebox.bg_color = Color.WHITE

	# Adjust border thickness for subgrid boundaries
	stylebox.border_width_top = border_width if row % 3 != 0 else thick_border
	stylebox.border_width_bottom = border_width if (row + 1) % 3 != 0 else thick_border
	stylebox.border_width_left = border_width if col % 3 != 0 else thick_border
	stylebox.border_width_right = border_width if (col + 1) % 3 != 0 else thick_border

	button.add_theme_stylebox_override("normal", stylebox)
	
	button.pressed.connect(_on_grid_button_pressed.bind(pos, ans))
	
	grid.add_child(button)
	return button
	
func _on_grid_button_pressed(pos: Vector2i, ans):
	selectedButton = pos
	select_button_answer = ans

	
func bind_selectedGrid_button_actions():
	for button in $SelectedGrid.get_children():
		var b = button as Button
		b.pressed.connect(_on_selectgrid_button_pressed.bind(int(b.text)))
		

func _on_numberKey_pressed(keyPressed):
	var btn = gameGrid[selectedButton[0]][selectedButton[1]] as Button
	var stylebox:StyleBoxFlat = btn.get_theme_stylebox("normal").duplicate(true)
	if puzzle[selectedButton[0]][selectedButton[1]] != 0 or enemyTurn or alreadyScoredTable[selectedButton[0]][selectedButton[1]]:
		return
	
	if selectedButton != Vector2i(-1,-1):
		
		if keyPressed != select_button_answer and keyPressed != 0:
			if playerTimer.get_time_left() - 10 < 0:
				print('You Lose! Your Time Ran Out')
				print('Youre Score is: ', "%0.4d" % playerScore)
				print('AI Score is: ', "%0.4d" % aiScore)
				print('You beat ', numberOfAIBeat, ' AI')
				get_tree().quit()
			playerTimer.start(playerTimer.get_time_left() - 10)
		var gridSelectedButton = gameGrid[selectedButton[0]][selectedButton[1]]
		playablePuzzle[selectedButton[0]][selectedButton[1]] = keyPressed
		if keyPressed == select_button_answer and not alreadyScoredTable[selectedButton[0]][selectedButton[1]] and not keyPressed == 0:
			print(alreadyScoredTable[selectedButton[0]][selectedButton[1]])
			playerScore += calculate_difficulty_score(playablePuzzle, selectedButton[1], selectedButton[0])
			alreadyScoredTable[selectedButton[0]][selectedButton[1]] = true
			_checkGameWin()
		if keyPressed == 0:
			gridSelectedButton.text = ''
			stylebox.bg_color = Color.WHITE
		else: 
			gridSelectedButton.text = str(keyPressed)

	if Settings.SHOW_HINTS and keyPressed != 0:
		var result_match = (keyPressed == select_button_answer)

		if result_match == true:
			stylebox.bg_color = Color.SEA_GREEN
		else:
			stylebox.bg_color = Color.DARK_RED
	btn.add_theme_stylebox_override("normal", stylebox)
	
	if keyPressed != 0:
		playerTurn = false
		enemyTurn = true

func _on_selectgrid_button_pressed(numberPressed: int):
	if puzzle[selectedButton[0]][selectedButton[1]] != 0 or enemyTurn:
		return
	
	if selectedButton != Vector2i(-1,-1):
		var gridSelectedButton = gameGrid[selectedButton[0]][selectedButton[1]]
		gridSelectedButton.text = str(numberPressed)
		
		if Settings.SHOW_HINTS:
			var result_match = (numberPressed == select_button_answer)
			var btn = gameGrid[selectedButton[0]][selectedButton[1]] as Button
			
			var stylebox:StyleBoxFlat = btn.get_theme_stylebox("normal").duplicate(true)
			if result_match == true:
				stylebox.bg_color = Color.SEA_GREEN
			else:
				stylebox.bg_color = Color.DARK_RED
			btn.add_theme_stylebox_override("normal", stylebox)
		
		if numberPressed != select_button_answer:
			if playerTimer.get_time_left() - 10 < 0:
				print('You Lose! Your Time Ran Out')
				print('Youre Score is: ', "%0.4d" % playerScore)
				print('AI Score is: ', "%0.4d" % aiScore)
				get_tree().quit()
				init_game(Settings.STARTING_DIFFICULTY + 1)
			playerTimer.start(playerTimer.get_time_left() - 10)
		playablePuzzle[selectedButton[0]][selectedButton[1]] = numberPressed
		if numberPressed == select_button_answer and not alreadyScoredTable[selectedButton[0]][selectedButton[1]]:
			playerScore += calculate_difficulty_score(playablePuzzle, selectedButton[1], selectedButton[0])
			alreadyScoredTable[selectedButton[0]][selectedButton[1]] = true
			_checkGameWin()
		
	playerTurn = false
	enemyTurn = true
		
func _on_ai_place_number(row, col, num):
	if puzzle[row][col] != 0 or playerTurn:
		return
	
	
	var gridSelectedButton = gameGrid[row][col]
	gridSelectedButton.text = str(num)
	if Settings.SHOW_HINTS:
		var result_match = (num == solution_grid[row][col])
		var btn = gameGrid[row][col] as Button
		
		var stylebox:StyleBoxFlat = btn.get_theme_stylebox("normal").duplicate(true)
		if result_match == true:
			stylebox.bg_color = Color.SKY_BLUE
		else:
			stylebox.bg_color = Color.CORAL
		btn.add_theme_stylebox_override("normal", stylebox)
	if num != solution_grid[row][col]:
		if enemyTimer.get_time_left() - 10 < 0:
			print('You Win, Enemy Timer Ran Out')
			print('Youre Score is: ', "%0.4d" % playerScore)
			print('AI Score is: ', "%0.4d" % aiScore)
			numberOfAIBeat += 1
			incrementRoom()
			updateStaticLabels()
			reset_game()
			init_game(Settings.STARTING_DIFFICULTY + 1)
		enemyTimer.start(enemyTimer.get_time_left() - 10)
		enemyTurn = false
		playerTurn = true
		
	if num == solution_grid[row][col] and not alreadyScoredTable[row][col]:
		aiScore += calculate_difficulty_score(playablePuzzle, col, row)
		alreadyScoredTable[row][col] = true
		aiPuzzle[row][col] = num
		_checkGameWin()
		
	enemyTurn = false
	playerTurn = true
		
func _generate_sudoku_soln():
	for i in range(GRID_SIZE):
		var row =[]
		for j in range(GRID_SIZE):
			row.append(j + 1)
		randomize()
		row.shuffle()
		solution_grid.append(row)
		
func isBoardFull():
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			if !alreadyScoredTable[row][col]:
				return false
	return true


func _checkGameWin():
	if isBoardFull():
		playerScore += (1 + (playerTimer.get_time_left() / 100)) * 1000
		aiScore += (1 + (enemyTimer.get_time_left() / 100)) * 1000
		if playerScore > aiScore:
			print('You Win!')
			print('Youre Score is: ', "%0.4d" % playerScore)
			print('AI Score is: ', "%0.4d" % aiScore)
			numberOfAIBeat += 1
			incrementRoom()
			updateStaticLabels()
			reset_game()
			init_game(Settings.STARTING_DIFFICULTY + 1)
		else: 
			print('You Lose!')
			print('Youre Score is: ', "%0.4d" % playerScore)
			print('AI Score is: ', "%0.4d" % aiScore)
			print('You beat ', numberOfAIBeat, ' AI')
			get_tree().quit()
func count_candidates(grd, row, col):
	if grd[row][col] != 0:
		return 0  # Already filled cell
	var candidates = 0
	for num in range(1, 10):
		if is_valid(grd, row, col, num):
			candidates += 1
	return candidates
	
func get_valid_candidates(grd, row, col) -> Array:
	var cands = []
	for num in range(1, 10):
		if is_valid(grd, row, col, num):
			cands.append(num)
	return cands

func calculate_difficulty_score(grd, row, col):
	var candidates = count_candidates(grd, row, col)
	if candidates == 0:
		return 1  # No valid move (shouldn't happen for a valid puzzle)
	return 10 - candidates  # Fewer candidates = higher score
