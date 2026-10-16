extends Node2D

# ASHVAULT: The Last Flame — playable vertical-slice prototype.
# Drawn with procedural shapes so the project has no external asset dependencies.

const W := 960.0
const H := 540.0
const PATH_WIDTH := 42.0
const PAD_RADIUS := 21.0
const TOWER_TYPES := ["Ember", "Gale", "Rune"]
const TOWER_COLORS := {
	"Ember": Color("ff7545"),
	"Gale": Color("72e8d4"),
	"Rune": Color("b78cff"),
	"Stormforge": Color("f7d66d"),
	"Soulflame": Color("e86cce"),
	"Voidroot": Color("9bdf78")
}
const FUSIONS := {
	"Ember+Gale": "Stormforge",
	"Ember+Rune": "Soulflame",
	"Gale+Rune": "Voidroot"
}
const ROUTE := [Vector2(35, 135), Vector2(190, 135), Vector2(190, 275), Vector2(390, 275), Vector2(390, 115), Vector2(610, 115), Vector2(610, 350), Vector2(820, 350), Vector2(920, 430)]
const PADS := [Vector2(105, 205), Vector2(270, 95), Vector2(290, 345), Vector2(465, 205), Vector2(520, 65), Vector2(685, 205), Vector2(720, 405), Vector2(850, 285)]

var towers: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var gold := 220
var lives := 20
var wave := 0
var wave_active := false
var spawn_timer := 0.0
var spawn_remaining := 0
var selected_type := "Ember"
var selected_tower := -1
var game_over := false
var message := "Choose a tower, then tap a glowing build pad."
var message_timer := 4.0
var elapsed := 0.0
var ui_scale := 1.0

func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)
	set_process(true)

func _process(delta: float) -> void:
	if game_over:
		queue_redraw()
		return
	elapsed += delta
	message_timer = maxf(0.0, message_timer - delta)
	if wave_active:
		spawn_timer -= delta
		if spawn_remaining > 0 and spawn_timer <= 0.0:
			spawn_enemy()
			spawn_remaining -= 1
			spawn_timer = maxf(0.42, 1.05 - wave * 0.035)
			if spawn_remaining <= 0:
				message = "Wave %d: hold the line." % wave
				message_timer = 2.0
		move_enemies(delta)
		if spawn_remaining <= 0 and enemies.is_empty():
			wave_active = false
			gold += 45 + wave * 8
			message = "Wave cleared. +%d gold. Prepare your defenses." % (45 + wave * 8)
			message_timer = 3.0
	move_towers(delta)
	move_shots(delta)
	move_particles(delta)
	queue_redraw()

func _draw() -> void:
	draw_world()
	draw_route()
	draw_pads()
	draw_enemies()
	draw_towers()
	draw_shots()
	draw_particles()
	draw_ui()

func draw_world() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("10141b"))
	# Layered dark terrain, faint grid, and ember-lit ruins.
	for x in range(0, 960, 48):
		draw_line(Vector2(x, 0), Vector2(x, 480), Color(0.24, 0.27, 0.30, 0.16), 1.0)
	for y in range(0, 480, 48):
		draw_line(Vector2(0, y), Vector2(960, y), Color(0.24, 0.27, 0.30, 0.16), 1.0)
	for i in range(11):
		var px := float((i * 137 + 53) % 930)
		var py := float((i * 79 + 25) % 450)
		draw_circle(Vector2(px, py), 3.0 + float(i % 3), Color(0.75, 0.31, 0.14, 0.12))
	# Ancient fortress at the end of the road.
	var fortress := Vector2(900, 430)
	draw_circle(fortress, 48, Color(0.95, 0.30, 0.08, 0.08))
	draw_colored_polygon(PackedVector2Array([Vector2(864, 440), Vector2(872, 393), Vector2(892, 382), Vector2(912, 393), Vector2(920, 440)]), Color("38343a"))
	draw_rect(Rect2(877, 410, 29, 30), Color("26252d"))
	draw_circle(Vector2(891, 403), 10, Color(1.0, 0.46, 0.13, 0.18))
	draw_circle(Vector2(891, 403), 5 + sin(elapsed * 4.0) * 1.5, Color("ffb84d"))
	# Broken pillars.
	for p in [Vector2(70, 340), Vector2(440, 425), Vector2(775, 80), Vector2(830, 170)]:
		draw_rect(Rect2(p.x - 7, p.y - 15, 14, 30), Color("34353b"))
		draw_rect(Rect2(p.x - 11, p.y - 17, 22, 5), Color("555057"))

func draw_route() -> void:
	for i in range(ROUTE.size() - 1):
		draw_line(ROUTE[i], ROUTE[i + 1], Color("080b10"), PATH_WIDTH + 12.0, true)
		draw_line(ROUTE[i], ROUTE[i + 1], Color("36343a"), PATH_WIDTH, true)
		draw_line(ROUTE[i], ROUTE[i + 1], Color(0.66, 0.38, 0.24, 0.20), 2.0, true)
	for p in ROUTE:
		draw_circle(p, PATH_WIDTH * 0.5, Color("36343a"))
		draw_circle(p, 3, Color(0.92, 0.58, 0.29, 0.20))

func draw_pads() -> void:
	for i in range(PADS.size()):
		var p: Vector2 = PADS[i]
		var occupied := false
		for t in towers:
			if int(t.pad) == i:
				occupied = true
				break
		if occupied:
			continue
		var pulse := 0.58 + 0.20 * sin(elapsed * 3.0 + i)
		draw_circle(p, PAD_RADIUS + 5, Color(0.93, 0.52, 0.20, 0.10))
		draw_circle(p, PAD_RADIUS, Color(0.76, 0.48, 0.24, 0.25))
		draw_arc(p, PAD_RADIUS, 0, TAU, 36, Color(1.0, 0.68, 0.31, pulse), 2.0)
		draw_line(p + Vector2(-6, 0), p + Vector2(6, 0), Color(1.0, 0.76, 0.42, 0.8), 2.0)
		draw_line(p + Vector2(0, -6), p + Vector2(0, 6), Color(1.0, 0.76, 0.42, 0.8), 2.0)

func draw_enemies() -> void:
	for e in enemies:
		var p: Vector2 = e.pos
		var r: float = e.radius
		var col: Color = e.color
		draw_circle(p, r + 5, Color(col.r, col.g, col.b, 0.12))
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.8, -r * 0.2), p + Vector2(r * 0.65, r * 0.75), p + Vector2(-r * 0.65, r * 0.75), p + Vector2(-r * 0.8, -r * 0.2)]), col)
		draw_circle(p + Vector2(-r * 0.25, -r * 0.1), 2.0, Color("fff0c4"))
		draw_circle(p + Vector2(r * 0.25, -r * 0.1), 2.0, Color("fff0c4"))
		var bw := r * 2.4
		draw_rect(Rect2(p.x - bw * 0.5, p.y - r - 9, bw, 3), Color("19191e"))
		draw_rect(Rect2(p.x - bw * 0.5, p.y - r - 9, bw * clampf(e.hp / e.max_hp, 0, 1), 3), Color("ff654f"))

func draw_towers() -> void:
	for i in range(towers.size()):
		var t := towers[i]
		var p: Vector2 = PADS[int(t.pad)]
		var col: Color = TOWER_COLORS[t.kind]
		if i == selected_tower:
			draw_circle(p, 34, Color(col.r, col.g, col.b, 0.15))
			draw_arc(p, 33, 0, TAU, 48, col, 2.5)
		draw_circle(p, 23, Color(0.0, 0.0, 0.0, 0.35))
		draw_circle(p, 18, Color("292b33"))
		draw_arc(p, 18, 0, TAU, 32, col, 3.0)
		if t.kind == "Ember":
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -15), p + Vector2(11, 7), p + Vector2(0, 13), p + Vector2(-11, 7)]), col)
		elif t.kind == "Gale":
			draw_line(p + Vector2(-11, 5), p + Vector2(10, -5), col, 4.0, true)
			draw_line(p + Vector2(-7, -8), p + Vector2(7, 8), col, 3.0, true)
		elif t.kind == "Rune":
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -12), p + Vector2(10, 0), p + Vector2(0, 12), p + Vector2(-10, 0)]), col)
		else:
			draw_circle(p, 9, col)
			draw_circle(p, 4, Color("fff0c4"))
		draw_string(ThemeDB.fallback_font, p + Vector2(-17, 31), "Lv.%d" % int(t.level), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("eee5d3"))

func draw_shots() -> void:
	for s in shots:
		var p: Vector2 = s.pos
		var col: Color = s.color
		draw_line(p, p - s.direction * 12, Color(col.r, col.g, col.b, 0.35), 4.0, true)
		draw_circle(p, 4.5, col)
		draw_circle(p, 2.0, Color("fff5d6"))

func draw_particles() -> void:
	for part in particles:
		var c: Color = part.color
		c.a = clampf(part.life / part.max_life, 0.0, 1.0)
		draw_circle(part.pos, part.size * c.a, c)

func draw_ui() -> void:
	# Header strip.
	draw_rect(Rect2(0, 0, W, 48), Color(0.035, 0.045, 0.06, 0.96))
	draw_line(Vector2(0, 48), Vector2(W, 48), Color("a65d35"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(18, 29), "ASHVAULT", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("f2d6a0"))
	draw_string(ThemeDB.fallback_font, Vector2(155, 28), "THE LAST FLAME", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("a99d91"))
	draw_string(ThemeDB.fallback_font, Vector2(690, 29), "GOLD  %d" % gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffd477"))
	draw_string(ThemeDB.fallback_font, Vector2(820, 29), "LIVES  %d" % lives, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ff9380"))
	# Bottom command panel.
	draw_rect(Rect2(0, 480, W, 60), Color(0.035, 0.045, 0.06, 0.98))
	draw_line(Vector2(0, 480), Vector2(W, 480), Color("a65d35"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(18, 502), "BUILD", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("a99d91"))
	for i in range(3):
		var rect := tower_button_rect(i)
		var kind: String = TOWER_TYPES[i]
		var col: Color = TOWER_COLORS[kind]
		var active := selected_type == kind
		draw_rect(rect, Color(col.r, col.g, col.b, 0.22 if active else 0.08))
		draw_rect(rect, col if active else Color(0.38, 0.39, 0.43), false, 1.5)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, 19), kind, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, 35), "Cost %d" % tower_cost(kind), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d7d0c6"))
	var fusion_rect := Rect2(355, 490, 145, 38)
	draw_rect(fusion_rect, Color("65453a"))
	draw_rect(fusion_rect, Color("e9ad69"), false, 1.5)
	draw_string(ThemeDB.fallback_font, fusion_rect.position + Vector2(18, 16), "FUSE SELECTED", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("ffe4b4"))
	draw_string(ThemeDB.fallback_font, fusion_rect.position + Vector2(18, 30), "Cost: 50 gold", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("d8c2a1"))
	var wave_rect := Rect2(520, 490, 135, 38)
	draw_rect(wave_rect, Color("873d2b") if not wave_active else Color("3a3b42"))
	draw_rect(wave_rect, Color("ff9b59") if not wave_active else Color("77757b"), false, 1.5)
	draw_string(ThemeDB.fallback_font, wave_rect.position + Vector2(18, 23), "START WAVE" if not wave_active else "WAVE ACTIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("fff0d6"))
	draw_string(ThemeDB.fallback_font, Vector2(680, 505), "WAVE %d" % wave, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e7d9c5"))
	draw_string(ThemeDB.fallback_font, Vector2(680, 521), "Fusion: select two towers", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("a99d91"))
	if message_timer > 0.0:
		var alpha := minf(1.0, message_timer * 2.0)
		draw_rect(Rect2(175, 56, 610, 30), Color(0.035, 0.045, 0.06, 0.82 * alpha))
		draw_string(ThemeDB.fallback_font, Vector2(190, 76), message, HORIZONTAL_ALIGNMENT_CENTER, 580, 13, Color(0.96, 0.87, 0.72, alpha))
	if game_over:
		draw_rect(Rect2(0, 0, W, H), Color(0.01, 0.01, 0.02, 0.78))
		draw_string(ThemeDB.fallback_font, Vector2(0, 230), "THE LAST FLAME HAS FALLEN", HORIZONTAL_ALIGNMENT_CENTER, W, 30, Color("ff8d73"))
		draw_string(ThemeDB.fallback_font, Vector2(0, 270), "Tap anywhere to restart the prototype", HORIZONTAL_ALIGNMENT_CENTER, W, 16, Color("e8d9c8"))

func tower_button_rect(i: int) -> Rect2:
	return Rect2(18 + i * 105, 488, 94, 42)

func tower_cost(kind: String) -> int:
	return 65 if kind == "Ember" else (75 if kind == "Gale" else 85)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_tap(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		handle_tap(event.position)

func handle_tap(pos: Vector2) -> void:
	if game_over:
		restart_game()
		return
	if pos.y >= 480:
		for i in range(3):
			if tower_button_rect(i).has_point(pos):
				selected_type = TOWER_TYPES[i]
				message = "%s tower selected. Tap a glowing pad." % selected_type
				message_timer = 2.0
				return
		if Rect2(355, 490, 145, 38).has_point(pos):
			fuse_selected()
			return
		if Rect2(520, 490, 135, 38).has_point(pos):
			start_wave()
			return
		return
	# Select existing tower first. A second tower selection arms fusion.
	for i in range(towers.size()):
		var p: Vector2 = PADS[int(towers[i].pad)]
		if p.distance_to(pos) <= 25:
			if selected_tower >= 0 and selected_tower != i:
				var a: String = towers[selected_tower].kind
				var b: String = towers[i].kind
				if a != b and towers[selected_tower].level >= 1 and towers[i].level >= 1:
					fuse_pair(selected_tower, i)
				else:
				selected_tower = i
				message = "%s tower selected. Select a different tower to fuse." % towers[i].kind
				message_timer = 2.4
			else:
				selected_tower = i
				message = "%s tower selected. Choose a second tower to fuse." % towers[i].kind
				message_timer = 2.4
			return
	# Build on empty pad.
	for i in range(PADS.size()):
		if PADS[i].distance_to(pos) <= PAD_RADIUS + 7:
			for t in towers:
				if int(t.pad) == i:
					return
			var cost := tower_cost(selected_type)
			if gold < cost:
				message = "Not enough gold. Defeat enemies to earn more."
				message_timer = 2.0
				return
			gold -= cost
			towers.append({"pad": i, "kind": selected_type, "level": 1, "cooldown": 0.2, "range": 150.0, "damage": 18.0, "rate": 0.9})
			selected_tower = towers.size() - 1
			message = "%s tower deployed." % selected_type
			message_timer = 1.8
			return

func fuse_selected() -> void:
	if selected_tower < 0 or selected_tower >= towers.size():
		message = "Select a tower, then select a second tower to fuse."
		message_timer = 2.0
		return
	message = "Tap a different tower to fuse their powers."
	message_timer = 2.0

func fuse_pair(first: int, second: int) -> void:
	if gold < 50:
		message = "Fusion needs 50 gold."
		message_timer = 2.0
		return
	var a: String = towers[first].kind
	var b: String = towers[second].kind
	var key := "" if a < b else ""
	if (a == "Ember" and b == "Gale") or (a == "Gale" and b == "Ember"):
		key = "Ember+Gale"
	elif (a == "Ember" and b == "Rune") or (a == "Rune" and b == "Ember"):
		key = "Ember+Rune"
	elif (a == "Gale" and b == "Rune") or (a == "Rune" and b == "Gale"):
		key = "Gale+Rune"
	else:
		message = "These towers cannot fuse again."
		message_timer = 2.0
		return
	gold -= 50
	var fused_kind: String = FUSIONS[key]
	var keep_pad: int = towers[first].pad
	var fused_level: int = mini(3, int(towers[first].level) + int(towers[second].level))
	var hi := maxi(first, second)
	var lo := mini(first, second)
	towers.remove_at(hi)
	towers.remove_at(lo)
	towers.append({"pad": keep_pad, "kind": fused_kind, "level": fused_level, "cooldown": 0.1, "range": 185.0, "damage": 34.0, "rate": 1.15})
	selected_tower = towers.size() - 1
	burst(PADS[keep_pad], TOWER_COLORS[fused_kind], 24)
	message = "FUSION COMPLETE: %s" % fused_kind.to_upper()
	message_timer = 3.0

func start_wave() -> void:
	if wave_active:
		message = "The current wave is still active."
		message_timer = 1.8
		return
	wave += 1
	wave_active = true
	spawn_remaining = 7 + wave * 2
	spawn_timer = 0.2
	message = "WAVE %d — THE NISHKAYA APPROACH" % wave
	message_timer = 2.8

func spawn_enemy() -> void:
	var heavy := wave >= 3 and randi() % 4 == 0
	var fast := wave >= 2 and randi() % 3 == 0 and not heavy
	var hp := 48.0 + wave * 11.0
	var speed := 48.0 + minf(wave * 1.5, 22.0)
	var radius := 11.0
	var col := Color("c65a49")
	if heavy:
		hp *= 2.8
		speed *= 0.62
		radius = 16.0
		col = Color("8c4b65")
	elif fast:
		hp *= 0.65
		speed *= 1.65
		radius = 8.0
		col = Color("e4a35c")
	enemies.append({"pos": ROUTE[0], "segment": 0, "progress": 0.0, "hp": hp, "max_hp": hp, "speed": speed, "radius": radius, "color": col, "reward": 8 if not heavy else 15})

func move_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var e := enemies[i]
		var seg: int = int(e.segment)
		if seg >= ROUTE.size() - 1:
			lives -= 1
			enemies.remove_at(i)
			if lives <= 0:
				game_over = true
			return
		var a: Vector2 = ROUTE[seg]
		var b: Vector2 = ROUTE[seg + 1]
		var distance := a.distance_to(b)
		var move_dist: float = float(e.speed) * delta
		var progress: float = float(e.progress) + move_dist / maxf(1.0, distance)
		while progress >= 1.0 and seg < ROUTE.size() - 1:
			progress -= 1.0
			seg += 1
			if seg >= ROUTE.size() - 1:
				break
			a = ROUTE[seg]
			b = ROUTE[seg + 1]
			distance = a.distance_to(b)
		e.segment = seg
		e.progress = progress
		if seg < ROUTE.size() - 1:
			e.pos = ROUTE[seg].lerp(ROUTE[seg + 1], progress)
		if e.hp <= 0:
			gold += int(e.reward)
			burst(e.pos, e.color, 7)
			enemies.remove_at(i)

func move_towers(delta: float) -> void:
	for t in towers:
		t.cooldown = float(t.cooldown) - delta
		if float(t.cooldown) > 0.0:
			continue
		var origin: Vector2 = PADS[int(t.pad)]
		var target_index := -1
		var best_progress := -1.0
		for i in range(enemies.size()):
			var e := enemies[i]
			if origin.distance_to(e.pos) <= float(t.range) and float(e.progress) + float(e.segment) > best_progress:
				target_index = i
				best_progress = float(e.progress) + float(e.segment)
		if target_index >= 0:
			var target: Dictionary = enemies[target_index]
			var dmg: float = float(t.damage) * (1.0 + (int(t.level) - 1) * 0.32)
			var col: Color = TOWER_COLORS[t.kind]
			if t.kind == "Ember":
				dmg *= 1.25
			elif t.kind == "Gale":
				target.speed = maxf(20.0, float(target.speed) * 0.93)
			elif t.kind == "Rune":
				dmg *= 1.12
			elif t.kind == "Stormforge":
				dmg *= 1.45
				for other in enemies:
					if other != target and other.pos.distance_to(target.pos) < 45:
						other.hp -= dmg * 0.35
			elif t.kind == "Soulflame":
				dmg *= 1.3
				gold += 1
			elif t.kind == "Voidroot":
				dmg *= 0.92
				target.speed = maxf(18.0, float(target.speed) * 0.82)
			target.hp -= dmg
			shots.append({"pos": origin, "target": target.pos, "direction": (target.pos - origin).normalized(), "speed": 500.0, "damage": dmg, "color": col, "life": 0.22})
			t.cooldown = float(t.rate)

func move_shots(delta: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var s := shots[i]
		s.life = float(s.life) - delta
		s.pos = s.pos.move_toward(s.target, float(s.speed) * delta)
		if float(s.life) <= 0.0 or s.pos.distance_to(s.target) < 8.0:
			burst(s.pos, s.color, 3)
			shots.remove_at(i)

func burst(pos: Vector2, col: Color, count: int) -> void:
	for i in range(count):
		var angle := randf() * TAU
		var speed := randf_range(18.0, 80.0)
		particles.append({"pos": pos, "vel": Vector2(cos(angle), sin(angle)) * speed, "life": randf_range(0.2, 0.55), "max_life": 0.55, "size": randf_range(1.5, 4.0), "color": col})

func move_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p := particles[i]
		p.life = float(p.life) - delta
		p.pos += p.vel * delta
		p.vel *= 0.94
		if float(p.life) <= 0.0:
			particles.remove_at(i)

func restart_game() -> void:
	towers.clear()
	enemies.clear()
	shots.clear()
	particles.clear()
	gold = 220
	lives = 20
	wave = 0
	wave_active = false
	spawn_remaining = 0
	selected_type = "Ember"
	selected_tower = -1
	game_over = false
	message = "Choose a tower, then tap a glowing build pad."
	message_timer = 4.0
