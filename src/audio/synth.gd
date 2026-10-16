class_name Synth
## A tiny procedural sound generator for placeholder effects. Real recordings
## dropped into assets/audio/sfx/<name>/ or the family folder replace these.

const RATE := 22050


## A two-pole band-pass filter, used to give a buzzy source a vowel-like "voice".
class Resonator:
	var gain := 1.0
	var _b0 := 0.0
	var _b2 := 0.0
	var _a1 := 0.0
	var _a2 := 0.0
	var _x1 := 0.0
	var _x2 := 0.0
	var _y1 := 0.0
	var _y2 := 0.0

	func _init(freq: float, q: float, resonator_gain: float) -> void:
		gain = resonator_gain
		var w := TAU * freq / RATE
		var alpha := sin(w) / (2.0 * q)
		var a0 := 1.0 + alpha
		_b0 = alpha / a0
		_b2 = -alpha / a0
		_a1 = -2.0 * cos(w) / a0
		_a2 = (1.0 - alpha) / a0

	func process(x: float) -> float:
		var y := _b0 * x + _b2 * _x2 - _a1 * _y1 - _a2 * _y2
		_x2 = _x1
		_x1 = x
		_y2 = _y1
		_y1 = y
		return y * gain


## Returns a placeholder for a named sound, or null if there isn't one.
static func make(sound: StringName) -> AudioStreamWAV:
	var samples: PackedFloat32Array
	match sound:
		&"bark": samples = _bark()
		&"baa": samples = _baa()
		&"boing": samples = _boing()
		&"pop": samples = _sweep(0.05, 900.0, 300.0, 40.0)
		&"land": samples = _sweep(0.14, 140.0, 55.0, 20.0, 0.25)
		&"ding": samples = _chord([1318.5, 1975.5], 0.8, 5.0)
		&"star": samples = _arpeggio([1568.0, 2093.0, 2637.0, 3136.0], 0.055, 0.3)
		&"fanfare": samples = _arpeggio([523.3, 659.3, 784.0, 1046.5], 0.13, 0.6, true)
		&"howl": samples = _howl()
		&"whoosh": samples = _whoosh()
		&"tick": samples = _sweep(0.025, 1400.0, 1200.0, 60.0)
		_: return null
	return _to_stream(samples)


static func _bark() -> PackedFloat32Array:
	var pitch := func(t: float) -> float: return 330.0 + 220.0 * exp(-t * 25.0)
	var envelope := func(t: float) -> float: return minf(1.0, t / 0.005) * exp(-t * 16.0)
	var formants := [Resonator.new(450.0, 4.0, 1.0), Resonator.new(1100.0, 5.0, 0.6), Resonator.new(2400.0, 6.0, 0.25)]
	return _voice(0.2, pitch, formants, envelope, 0.25)


static func _baa() -> PackedFloat32Array:
	var pitch := func(t: float) -> float: return (285.0 - 30.0 * t) * (1.0 + 0.05 * sin(TAU * 8.5 * t))
	var envelope := func(t: float) -> float:
		var shape := minf(1.0, t / 0.04) * clampf((0.7 - t) / 0.18, 0.0, 1.0)
		return shape * (0.72 + 0.28 * sin(TAU * 8.5 * t))
	var formants := [Resonator.new(750.0, 5.0, 1.0), Resonator.new(1250.0, 6.0, 0.7), Resonator.new(2600.0, 8.0, 0.3)]
	return _voice(0.7, pitch, formants, envelope, 0.05)


static func _howl() -> PackedFloat32Array:
	var pitch := func(t: float) -> float:
		var glide := 380.0 + 240.0 * sin(PI * minf(t / 0.9, 1.0)) * (1.0 - 0.3 * maxf(0.0, t - 0.9))
		return glide * (1.0 + 0.03 * sin(TAU * 5.0 * t))
	var envelope := func(t: float) -> float: return minf(1.0, t / 0.15) * clampf((1.4 - t) / 0.4, 0.0, 1.0)
	var formants := [Resonator.new(600.0, 4.0, 1.0), Resonator.new(1000.0, 5.0, 0.5)]
	return _voice(1.4, pitch, formants, envelope, 0.08)


## A buzzy source shaped by formant filters: the basis for animal noises.
static func _voice(duration: float, pitch: Callable, formants: Array, envelope: Callable, noise: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(duration * RATE))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase = fposmod(phase + float(pitch.call(t)) / RATE, 1.0)
		var source := (2.0 * phase - 1.0) * (1.0 - noise) + rng.randf_range(-1.0, 1.0) * noise
		var y := 0.0
		for r: Resonator in formants:
			y += r.process(source)
		out[i] = y * float(envelope.call(t))
	return _normalize(out)


static func _boing() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(0.45 * RATE))
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var freq := 170.0 * pow(3.2, minf(t / 0.25, 1.0)) * (1.0 + 0.12 * sin(TAU * 14.0 * t) * exp(-t * 6.0))
		phase = fposmod(phase + freq / RATE, 1.0)
		out[i] = sin(TAU * phase) * exp(-t * 5.0) * minf(1.0, t / 0.005)
	return _normalize(out)


static func _sweep(duration: float, from_hz: float, to_hz: float, decay: float, noise := 0.0) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(duration * RATE))
	var rng := RandomNumberGenerator.new()
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var freq := lerpf(from_hz, to_hz, t / duration)
		phase = fposmod(phase + freq / RATE, 1.0)
		var s := sin(TAU * phase) * (1.0 - noise) + rng.randf_range(-1.0, 1.0) * noise
		out[i] = s * exp(-t * decay) * minf(1.0, t / 0.002)
	return _normalize(out)


static func _chord(freqs: Array, duration: float, decay: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(duration * RATE))
	for i in out.size():
		var t := float(i) / RATE
		var s := 0.0
		for f: float in freqs:
			s += sin(TAU * f * t)
		out[i] = s * exp(-t * decay) * minf(1.0, t / 0.003)
	return _normalize(out)


## Notes one after another; `square` gives a brassier, fanfare-y tone.
static func _arpeggio(freqs: Array, note_length: float, tail: float, square := false) -> PackedFloat32Array:
	var total := note_length * (freqs.size() - 1) + tail
	var out := PackedFloat32Array()
	out.resize(int(total * RATE))
	for n in freqs.size():
		var f: float = freqs[n]
		var start := int(n * note_length * RATE)
		var length := int((tail if n == freqs.size() - 1 else note_length * 1.6) * RATE)
		for i in length:
			if start + i >= out.size():
				break
			var t := float(i) / RATE
			var s := sin(TAU * f * t)
			if square:
				s += sin(TAU * f * 3.0 * t) / 3.0 + sin(TAU * f * 5.0 * t) / 5.0
			out[start + i] += s * exp(-t * 4.0) * minf(1.0, t / 0.004)
	return _normalize(out)


static func _whoosh() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(0.4 * RATE))
	var rng := RandomNumberGenerator.new()
	var low := Resonator.new(700.0, 0.8, 1.0)
	for i in out.size():
		var t := float(i) / RATE
		out[i] = low.process(rng.randf_range(-1.0, 1.0)) * sin(PI * t / 0.4)
	return _normalize(out)


## A bouncy 8-bar loop (16 s at 120 bpm): oom-pah bass, plucked chords, marimba
## melody and a shaker. A placeholder until real music is added; slow-ish to build,
## so call it off the main thread.
static func music_loop() -> AudioStreamWAV:
	const BEAT := 0.5
	const BARS := 8
	# Chord roots (MIDI) and chord tones per bar: C G Am F C G F G.
	var chords := [
		[48, [60, 64, 67]], [43, [59, 62, 67]], [45, [60, 64, 69]], [41, [60, 65, 69]],
		[48, [60, 64, 67]], [43, [59, 62, 67]], [41, [60, 65, 69]], [43, [59, 62, 67]],
	]
	# Melody in eighth notes (MIDI, 0 = rest), one row per bar.
	var melody := [
		[76, 79, 81, 79, 76, 74, 72, 74], [74, 79, 79, 81, 83, 0, 79, 0],
		[81, 84, 83, 81, 76, 0, 81, 0], [77, 81, 84, 81, 79, 0, 0, 0],
		[76, 79, 84, 79, 76, 74, 72, 74], [74, 79, 83, 79, 74, 0, 76, 77],
		[81, 79, 77, 81, 84, 81, 79, 77], [79, 0, 83, 0, 86, 0, 79, 0],
	]
	var total := int(BARS * 4 * BEAT * RATE)
	var out := PackedFloat32Array()
	out.resize(total)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for bar in BARS:
		var bar_start := bar * 4 * BEAT
		var root: int = chords[bar][0]
		var tones: Array = chords[bar][1]
		for beat in 4:
			var t0 := bar_start + beat * BEAT
			if beat % 2 == 0:
				_add_note(out, t0, _midi(root - (0 if beat == 0 else -7)), 0.42, 0.55, 2)  # oom
				_add_kick(out, t0, 0.35)
			else:
				for tone: int in tones:
					_add_pluck(out, t0, _midi(tone), 0.16, rng)  # pah
		for step in 8:
			var note: int = melody[bar][step]
			if note > 0:
				_add_note(out, bar_start + step * BEAT * 0.5, _midi(note), 0.3, 0.32, 1)
			_add_shaker(out, bar_start + step * BEAT * 0.5, 0.05 if step % 2 == 1 else 0.03, rng)
	var stream := _to_stream(_normalize(out, 0.6))
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total
	return stream


static func _midi(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0)


## A mallet-like note (kind 1 = marimba, 2 = round bass). Wraps around the loop end.
static func _add_note(out: PackedFloat32Array, start: float, freq: float, length: float, gain: float, kind: int) -> void:
	var first := int(start * RATE)
	for i in int(length * RATE):
		var t := float(i) / RATE
		var s := sin(TAU * freq * t)
		if kind == 1:
			s += 0.25 * sin(TAU * freq * 4.0 * t) * exp(-t * 30.0)
			s *= exp(-t * 7.0)
		else:
			s = (s + 0.3 * sin(TAU * freq * 2.0 * t)) * exp(-t * 5.0)
		out[(first + i) % out.size()] += s * gain * minf(1.0, t / 0.003)


## A soft plucked string (Karplus-Strong), for the off-beat chords.
static func _add_pluck(out: PackedFloat32Array, start: float, freq: float, gain: float, rng: RandomNumberGenerator) -> void:
	var period := maxi(2, int(RATE / freq))
	var ring := PackedFloat32Array()
	ring.resize(period)
	for i in period:
		ring[i] = rng.randf_range(-1.0, 1.0)
	var first := int(start * RATE)
	for i in int(0.35 * RATE):
		var j := i % period
		var next := (j + 1) % period
		var value := ring[j]
		ring[j] = (value + ring[next]) * 0.5 * 0.996
		out[(first + i) % out.size()] += value * gain


static func _add_kick(out: PackedFloat32Array, start: float, gain: float) -> void:
	var first := int(start * RATE)
	var phase := 0.0
	for i in int(0.18 * RATE):
		var t := float(i) / RATE
		phase += (50.0 + 90.0 * exp(-t * 30.0)) / RATE
		out[(first + i) % out.size()] += sin(TAU * phase) * exp(-t * 18.0) * gain


static func _add_shaker(out: PackedFloat32Array, start: float, gain: float, rng: RandomNumberGenerator) -> void:
	var first := int(start * RATE)
	var last := 0.0
	for i in int(0.06 * RATE):
		var t := float(i) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		var bright := noise - last  # crude high-pass
		last = noise
		out[(first + i) % out.size()] += bright * gain * exp(-t * 60.0)


static func _normalize(samples: PackedFloat32Array, peak := 0.8) -> PackedFloat32Array:
	var loudest := 0.0
	for s in samples:
		loudest = maxf(loudest, absf(s))
	if loudest > 0.0:
		var scale := peak / loudest
		for i in samples.size():
			samples[i] *= scale
	return samples


static func _to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream
