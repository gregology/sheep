#!/usr/bin/env python3
"""Builds the game's sound effects and music from CC0 sources.

Every clip below comes from a public-domain (CC0 1.0) source. The script downloads
each source once into .tools/audio-cache/, cuts the listed segment, gently cleans
it up (high-pass, fades, peak normalisation, mono), encodes it as Ogg Vorbis into
assets/audio/, and rewrites assets/audio/CREDITS.md.

    python3 tools/audio/build_sounds.py          # needs ffmpeg with libvorbis

Sound names match the ones the game plays (see src/audio/sfx.gd); a folder with
several files gives random variety.
"""
import json
import pathlib
import subprocess
import sys
import urllib.request
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
CACHE = ROOT / ".tools" / "audio-cache"
SFX_OUT = ROOT / "assets" / "audio" / "sfx"
MUSIC_OUT = ROOT / "assets" / "audio" / "music"
CREDITS = ROOT / "assets" / "audio" / "CREDITS.md"

FREESOUND = "freesound"
KENNEY = "kenney"
OGA = "opengameart"

KENNEY_PACKS = {
    "interface-sounds": "https://kenney.nl/media/pages/assets/interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip",
    "music-jingles": "https://kenney.nl/media/pages/assets/music-jingles/f37e530b9e-1677590399/kenney_music-jingles.zip",
    "impact-sounds": "https://kenney.nl/media/pages/assets/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip",
}


def freesound(sound_id, user, user_id, title):
    bucket = str(sound_id)[:-3] or "0"
    return {
        "kind": FREESOUND,
        "key": f"freesound-{sound_id}",
        "url": f"https://cdn.freesound.org/previews/{bucket}/{sound_id}_{user_id}-hq.mp3",
        "page": f"https://freesound.org/people/{user}/sounds/{sound_id}/",
        "author": user,
        "title": title,
    }


def kenney(pack, member, title):
    return {
        "kind": KENNEY,
        "key": f"kenney-{pack}-{pathlib.Path(member).stem}",
        "pack": pack,
        "member": member,
        "page": f"https://kenney.nl/assets/{pack}",
        "author": "Kenney (kenney.nl)",
        "title": title,
    }


def opengameart(slug, url, author, title, member=None):
    return {
        "kind": OGA,
        "key": f"oga-{slug}",
        "url": url,
        "member": member,
        "page": f"https://opengameart.org/content/{slug}",
        "author": author,
        "title": title,
    }


SHEEP_2 = freesound(171151, "esperar", 377731, "sheep 2.mp3")
SHEEP_SQEEEK = freesound(237103, "sqeeeek", 4277312, "sqeeeek_sheep.wav")
SHEEP_BAH = freesound(669872, "SergioJbs", 8392567, "bah bala oveja/baa bleat sheep.WAV")
SHEEP_EWE = freesound(692900, "satoristudios3", 14166079, "Ewe Shetland Sheep Baa")
SHEEP_NORWEGIAN = freesound(710300, "michaelperfect", 201532, "Sheep baaing 5 - Norwegian sheep expressing itself concisely")
DOG_SMALL = freesound(361544, "Jofae", 6512973, "Small Dog Barking")
DOG_SMALL_2 = freesound(484297, "giddster", 1738686, "Small dog bark")
DOG_MEDIUM = freesound(630648, "haulaway", 7228277, "single bark - small to medium dog")
DOG_SINGLE = freesound(277058, "kwahmah_02", 4486188, "Single Dog Bark")
DOG_HOWL = freesound(115357, "simcotter", 2024015, "dog howling.wav")
BOING_CARTOON = freesound(731262, "sdroliasnick", 15869491, "cartoon-sound-single-boing")
BOING_RISING = freesound(537060, "suzenako", 481768, "boing.wav")
BOING_FUNNY = freesound(543641, "se2001", 8472935, "Funny Boing")
POP_CARTOON = freesound(741368, "Mish7913", 16104671, "Cartoon Pop")
POP_CORK = freesound(676000, "craigsmith", 2524442, "S24-24 Comedy cartoon cork pop.wav")
WHOOSH = freesound(683101, "florianreichelt", 6253486, "quick woosh")

# (sound name, output file, source, start s, end s or None for the whole clip)
CLIPS = [
    ("baa", "baa_1", SHEEP_2, 0.13, 0.97),
    ("baa", "baa_2", SHEEP_SQEEEK, 0.19, 0.88),
    ("baa", "baa_3", SHEEP_BAH, 0.97, 1.62),
    ("baa", "baa_4", SHEEP_EWE, 0.20, 1.40),
    ("baa", "baa_5", SHEEP_NORWEGIAN, 0.0, 1.40),
    ("bark", "bark_1", DOG_SMALL, 0.25, 0.70),
    ("bark", "bark_2", DOG_SMALL, 1.52, 1.95),
    ("bark", "bark_3", DOG_SMALL, 3.18, 3.85),
    ("bark", "bark_4", DOG_SMALL, 4.89, 5.33),
    ("bark", "bark_5", DOG_SMALL_2, 0.58, 1.00),
    ("bark", "bark_6", DOG_MEDIUM, 0.72, 1.08),
    ("bark", "bark_7", DOG_SINGLE, 0.0, 0.30),
    ("howl", "howl_1", DOG_HOWL, 0.22, 1.50),
    ("howl", "howl_2", DOG_HOWL, 9.21, 10.75),
    ("boing", "boing_1", BOING_CARTOON, 0.0, 1.75),
    ("boing", "boing_2", BOING_RISING, 0.0, 0.66),
    ("boing", "boing_3", BOING_FUNNY, 0.14, 0.93),
    ("pop", "pop_1", POP_CARTOON, 0.0, 0.20),
    ("pop", "pop_2", POP_CORK, 0.12, 0.60),
    ("whoosh", "whoosh_1", WHOOSH, 0.0, 0.62),
    ("ding", "ding_1", kenney("interface-sounds", "Audio/confirmation_002.ogg", "confirmation_002"), 0.0, None),
    ("ding", "ding_2", kenney("interface-sounds", "Audio/confirmation_004.ogg", "confirmation_004"), 0.0, None),
    ("tick", "tick_1", kenney("interface-sounds", "Audio/tick_004.ogg", "tick_004"), 0.0, None),
    ("star", "star_1", kenney("music-jingles", "Audio/Pizzicato jingles/jingles_PIZZI10.ogg", "jingles_PIZZI10"), 0.0, None),
    ("star", "star_2", kenney("music-jingles", "Audio/Pizzicato jingles/jingles_PIZZI15.ogg", "jingles_PIZZI15"), 0.0, None),
    ("fanfare", "fanfare_1", kenney("music-jingles", "Audio/Steel jingles/jingles_STEEL02.ogg", "jingles_STEEL02"), 0.0, None),
    ("land", "land_1", kenney("impact-sounds", "Audio/impactSoft_heavy_000.ogg", "impactSoft_heavy_000"), 0.0, None),
    ("land", "land_2", kenney("impact-sounds", "Audio/impactSoft_heavy_002.ogg", "impactSoft_heavy_002"), 0.0, None),
]

# (output file, source): loops, kept in stereo.
MUSIC = [
    ("round", opengameart(
        "childrens-march-theme", "https://opengameart.org/sites/default/files/childrens_march_theme.zip",
        "Cleyton Kauffman", "Children's March Theme", member="Children's March Theme.ogg")),
    ("menu", opengameart(
        "flowerbed-fields-loop", "https://opengameart.org/sites/default/files/flowerbed_fields.ogg",
        "Zane Little Music", "Flowerbed Fields [Loop]")),
]

# Animal recordings get rumble removed; synthetic/UI sounds are left alone.
CLEAN_UP = {"baa", "bark", "howl"}


def download(url: str, dest: pathlib.Path) -> pathlib.Path:
    if not dest.exists():
        dest.parent.mkdir(parents=True, exist_ok=True)
        print(f"  downloading {url}")
        request = urllib.request.Request(url, headers={"User-Agent": "sheep-game-asset-builder"})
        with urllib.request.urlopen(request, timeout=120) as response:
            dest.write_bytes(response.read())
    return dest


def from_zip(archive: pathlib.Path, member: str, dest: pathlib.Path) -> pathlib.Path:
    if not dest.exists():
        with zipfile.ZipFile(archive) as z:
            names = [n for n in z.namelist() if n.endswith(member)]
            if not names:
                raise SystemExit(f"{member} not found in {archive.name}")
            dest.write_bytes(z.read(names[0]))
    return dest


def source_file(source: dict) -> pathlib.Path:
    if source["kind"] == KENNEY:
        archive = download(KENNEY_PACKS[source["pack"]], CACHE / f"kenney_{source['pack']}.zip")
        return from_zip(archive, source["member"], CACHE / f"{source['key']}.ogg")
    suffix = pathlib.Path(source["url"]).suffix
    raw = download(source["url"], CACHE / f"{source['key']}{suffix}")
    if source.get("member"):
        return from_zip(raw, source["member"], CACHE / f"{source['key']}-{pathlib.Path(source['member']).name}")
    return raw


def peak_db(path: pathlib.Path, filters: str) -> float:
    out = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(path), "-af", f"{filters},volumedetect", "-f", "null", "-"],
                         capture_output=True, text=True).stderr
    for line in out.splitlines():
        if "max_volume" in line:
            return float(line.split("max_volume:")[1].split()[0])
    raise SystemExit(f"couldn't measure {path}")


def build_clip(name, out_name, source, start, end) -> None:
    src = source_file(source)
    length = (end - start) if end else None
    filters = []
    if name in CLEAN_UP:
        filters.append("highpass=f=100")
    filters.append("afade=t=in:d=0.006")
    if length:
        fade = min(0.08, length * 0.2)
        filters.append(f"afade=t=out:st={length - fade:.3f}:d={fade:.3f}")
    trim = ["-ss", f"{start:.3f}"] + (["-t", f"{length:.3f}"] if length else [])
    chain = ",".join(filters)
    # Peak-normalise to -1 dBFS so every sound starts from the same level; the game mixes from there.
    measure = subprocess.run(["ffmpeg", "-hide_banner", *trim, "-i", str(src), "-af", f"{chain},volumedetect",
                              "-f", "null", "-"], capture_output=True, text=True).stderr
    peak = float(measure.split("max_volume:")[1].split()[0])
    out = SFX_OUT / name / f"{out_name}.ogg"
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *trim, "-i", str(src),
                    "-af", f"{chain},volume={-1.0 - peak:.2f}dB", "-ac", "1", "-ar", "44100",
                    "-c:a", "libvorbis", "-q:a", "5", str(out)], check=True)
    print(f"  {out.relative_to(ROOT)}  ({length or 0:.2f}s, +{-1.0 - peak:.1f} dB)")


def build_music(out_name, source) -> None:
    src = source_file(source)
    out = MUSIC_OUT / f"{out_name}.ogg"
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(src),
                    "-ar", "44100", "-c:a", "libvorbis", "-q:a", "4", str(out)], check=True)
    print(f"  {out.relative_to(ROOT)}")


def write_credits() -> None:
    lines = [
        "# Audio credits",
        "",
        "Every sound and piece of music here is public domain under",
        "[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). Credit isn't required, but",
        "thank you to everyone below. The files were trimmed, cleaned up, normalised and converted by",
        "`tools/audio/build_sounds.py`, which also regenerates this list.",
        "",
        "## Music",
        "",
        "| File | Track | Author | Source |",
        "|---|---|---|---|",
    ]
    for out_name, s in MUSIC:
        lines.append(f"| `music/{out_name}.ogg` | {s['title']} | {s['author']} | {s['page']} |")
    lines += ["", "## Sound effects", "", "| File | Original | Author | Source |", "|---|---|---|---|"]
    for name, out_name, s, _start, _end in CLIPS:
        lines.append(f"| `sfx/{name}/{out_name}.ogg` | {s['title']} | {s['author']} | {s['page']} |")
    CREDITS.write_text("\n".join(lines) + "\n")
    print(f"  {CREDITS.relative_to(ROOT)}")


def main() -> None:
    only = set(sys.argv[1:])
    print("Sound effects")
    for clip in CLIPS:
        if not only or clip[0] in only:
            build_clip(*clip)
    print("Music")
    for out_name, source in MUSIC:
        if not only or "music" in only:
            build_music(out_name, source)
    write_credits()
    (CACHE / "manifest.json").write_text(json.dumps([c[1] for c in CLIPS]))


if __name__ == "__main__":
    main()
