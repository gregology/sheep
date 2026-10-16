class_name RoundStats
extends RefCounted
## What happened in a round, for the celebration screen.

var seconds := 0.0
var sheep := 0
var chaos_stars := 0
var had_chaos_player := false


## One to three stars for the dogs. Everyone gets at least one.
func dog_stars(par_seconds_per_sheep: float) -> int:
	var par := par_seconds_per_sheep * sheep
	if seconds <= par:
		return 3
	if seconds <= par * 1.75:
		return 2
	return 1
