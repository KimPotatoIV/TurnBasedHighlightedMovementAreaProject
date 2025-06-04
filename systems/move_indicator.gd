extends Node2D

##################################################
# 타일 한 개 크기
const TILE_SIZE: float = 64.0
# 이동할 수 있는 최대 타일 개수
const MAX_STEPS: int = 4

# 타일 정보를 가져올 TileMapLayer 노드 참조 변수
var tile_map_layer_node: TileMapLayer

##################################################
func _ready() -> void:
	# TileMapLayer 노드를 가져와 변수에 저장
	tile_map_layer_node = get_node("/root/Main/Map/TileMapLayer")

##################################################
# 현재 위치에서 시작하여 이동할 수 있는 위치 또는 공격 범위를 탐색하는 함수
# is_attackable에 따라 이동 가능 타일을 반환할지 공격 가능한 타일들을 반환할지 정함
func get_reachable_tiles(current_position_value: Vector2, is_attackable: bool) -> Array:
	# BFS 탐색을 위한 이동 가능 타일들을 따로 저장할 배열 초기화
	var reachable_tiles: Array = [{"position": current_position_value, "steps": 0}]
	# 중복 방문 방지를 위해 이미 방문한 타일들을 기록할 배열
	var visited_tiles: Array = [current_position_value]
	# 공격 가능 타일들을 따로 저장할 배열
	var attack_tiles: Array = []
	
	# (상, 하, 좌, 우) 4방향 탐색
	var directions: Array = \
	[Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	
	# BFS 반복 시작
	while reachable_tiles.size() > 0:
		# 현재 탐색 중인 타일 정보 가져오기
		var current_tile: Dictionary = reachable_tiles.pop_front()
		var current_tile_position: Vector2 = current_tile["position"]
		var current_tile_steps: int = current_tile["steps"]
		
		# 만약 MAX_STEPS를 초과하면 공격 범위에 추가하고 다음 타일로 넘어감
		if current_tile_steps > MAX_STEPS:
			attack_tiles.append(current_tile_position)
			continue
		
		# 현재 타일에서 네 방향으로 이동 가능한 타일 탐색
		for direction in directions:
			var new_position: Vector2 =  current_tile_position + direction * TILE_SIZE
			# 이미 방문한 타일이면 무시
			if visited_tiles.has(new_position):
				continue
			
			# 픽셀이 아닌 타일 인덱스 기준으로 타일 좌표 계산
			var tile_coords: Vector2i = Vector2i(new_position / TILE_SIZE)
			
			# 해당 타일에 대한 사용자 정의 데이터 가져오기
			var tile_data: TileData = tile_map_layer_node.get_cell_tile_data(tile_coords)
			# Wall 타입인 경우 통과 불가 하므로 무시
			# get_cell_tile_data()을 제대로 못 가져와도 무시
			if tile_data.get_custom_data("Type") == "Wall" or tile_data == null:
				continue
			
			# 탐색 가능한 타일로 인정되면 방문 목록에 추가하고 이동 가능 타일 배열에 넣음
			visited_tiles.append(new_position)
			reachable_tiles.append({"position": new_position, "steps": current_tile_steps + 1})
	
	# 자기 자신의 위치는 visited 배열 목록에서 제거
	visited_tiles.erase(current_position_value)
	
	# is_attackable에 따라 어떤 배열을 반환할지 결정
	if is_attackable:
		return attack_tiles
	else:
		return visited_tiles
