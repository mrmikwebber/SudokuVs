extends Node2D

@onready var grid:GridContainer = $GridContainer

var gameGrid = []
var puzzle = []
var playablePuzzle = []
var alreadyScoredTable = []
var permanantNums = []
var solution_grid = []
var selectedButton:Vector2i = Vector2(-1, -1)
var playerTimer : Timer = Timer.new()
var playerTurn = true
var enemyTimer : Timer = Timer.new()
var enemyTurn = false
var playerScore = 0

const GRID_SIZE = 9
var solution_count = 0
var select_button_answer = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bind_selectedGrid_button_actions()
	init_game()


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
	pass

func init_game():
	_create_empty_grid()
	_fill_grid(solution_grid)
	_create_puzzle(Settings.DIFFICULTY)
	_populate_grid()
	_populateAlreadyScoreTable()
	_createPlayerTimer()
	_createEnemyTimer()
	
func _createPlayerTimer():
	add_child(playerTimer)
	playerTimer.one_shot = true
	playerTimer.autostart = false
	playerTimer.timeout.connect(_playerTimer_Timeout)
	playerTimer.start(((0.4667 + (0.22 * (Settings.DIFFICULTY * 4))) * 60) / 2)
	
func _createEnemyTimer():
	add_child(enemyTimer)
	enemyTimer.one_shot = true
	enemyTimer.autostart = false
	enemyTimer.timeout.connect(_enemyTimer_Timeout)
	enemyTimer.start(((0.4667 + (0.22 * (Settings.DIFFICULTY * 4))) * 60) / 2)
	
func _playerTimer_Timeout():
	print('Game Over')
	get_tree().quit()
	
func _enemyTimer_Timeout():
	print('You Win!')
	get_tree().quit()
	
func _populateAlreadyScoreTable():
	for i in range(GRID_SIZE):
		var row = []
		for j in range(GRID_SIZE):
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
	for row in range(9):
		for col in range(9):
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
	if puzzle[selectedButton[0]][selectedButton[1]] != 0:
		return
	
	if selectedButton != Vector2i(-1,-1):
		
		if keyPressed != select_button_answer and keyPressed != 0:
			playerTimer.start(playerTimer.get_time_left() - 10)
		var gridSelectedButton = gameGrid[selectedButton[0]][selectedButton[1]]
		playablePuzzle[selectedButton[0]][selectedButton[1]] = keyPressed
		if keyPressed == select_button_answer and not alreadyScoredTable[selectedButton[0]][selectedButton[1]]:
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

func _on_selectgrid_button_pressed(numberPressed: int):
	if puzzle[selectedButton[0]][selectedButton[1]] != 0:
		return
	
	if selectedButton != Vector2i(-1,-1):
		var gridSelectedButton = gameGrid[selectedButton[0]][selectedButton[1]]
		if numberPressed != select_button_answer:
			playerTimer.start(playerTimer.get_time_left() - 10)
		playablePuzzle[selectedButton[0]][selectedButton[1]] = numberPressed
		if numberPressed == select_button_answer and not alreadyScoredTable[selectedButton[0]][selectedButton[1]]:
			playerScore += calculate_difficulty_score(playablePuzzle, selectedButton[1], selectedButton[0])
			_checkGameWin()
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
		
func _generate_sudoku_soln():
	for i in range(GRID_SIZE):
		var row =[]
		for j in range(GRID_SIZE):
			row.append(j + 1)
		randomize()
		row.shuffle()
		solution_grid.append(row)
		
		
func _checkGameWin():
	if playablePuzzle.hash() == solution_grid.hash():
		print('You Win!')
		playerScore += (1 + (playerTimer.get_time_left() / 100))
		print('Youre Score is: ', "%0.2d" % playerScore)
		get_tree().quit()
		
func count_candidates(grd, row, col):
	if grd[row][col] != 0:
		return 0  # Already filled cell
	var candidates = 0
	for num in range(1, 10):
		if is_valid(grd, row, col, num):
			candidates += 1
	return candidates

func calculate_difficulty_score(grd, row, col):
	var candidates = count_candidates(grd, row, col)
	if candidates == 0:
		return 1  # No valid move (shouldn't happen for a valid puzzle)
	return 10 - candidates  # Fewer candidates = higher score
