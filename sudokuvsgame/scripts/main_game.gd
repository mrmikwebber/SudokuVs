extends Node2D

@onready var grid:GridContainer = $GridContainer

var gameGrid = []
var puzzle = []
var solution_grid = []
var selectedButton:Vector2i = Vector2(-1, -1)
const GRID_SIZE = 9
var solution_count = 0
var select_button_answer = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bind_selectedGrid_button_actions()
	init_game()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func init_game():
	_create_empty_grid()
	_fill_grid(solution_grid)
	_create_puzzle(Settings.DIFFICULTY)
	_populate_grid()
	
func _populate_grid():
	gameGrid = []
	for i in range(GRID_SIZE):
		var row = []
		for j in range(GRID_SIZE):
			row.append(create_button(Vector2(i,j)))
		gameGrid.append(row)
			

func _create_empty_grid():
	solution_grid = []
	for i in range(GRID_SIZE):
		var row = []
		for j in range(GRID_SIZE):
			row.append(0)
		solution_grid.append(row)

func _create_puzzle(difficulty):
	puzzle = solution_grid.duplicate(true)
	var removals = difficulty * 10 #Easy = 20, Hard = 50
	while removals > 0:
		var row = randi_range(0,8)
		var col = randi_range(0,8)
		if puzzle[row][col] != 0:
			var temp = puzzle[row][col]
			puzzle[row][col] = 0
			if not has_unique_solution(puzzle):
				puzzle[row][col] = temp
			else:
				removals -= 1
				
				
func has_unique_solution(puzzle_grid):
	solution_count = 0
	try_to_solve_grid(puzzle_grid)
	return solution_count == 1
	
func try_to_solve_grid(puzzle_grid):
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
	button.custom_minimum_size = Vector2(52,52)
	
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
		

func _on_selectgrid_button_pressed(numberPressed):
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
		
func _generate_sudoku_soln():
	for i in range(GRID_SIZE):
		var row =[]
		for j in range(GRID_SIZE):
			row.append(j + 1)
		randomize()
		row.shuffle()
		solution_grid.append(row)
	
	print(solution_grid)
