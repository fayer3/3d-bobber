import zipfile
import json
from pathlib import Path

BASE_DIR = Path.cwd()
IMAGES_DIR = BASE_DIR.joinpath("images")

BOBBER = "bobber.glsl"
BOBBER_PATH = "assets/minecraft/shaders/include/bobber.glsl"

IGNORE = [".git", "images", ".gitignore", "build.py", "build-data.json", "build"]

def modify_shader_content(mode: str, enable_string: bool) -> str:
    with open(BOBBER_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    content = content.replace(
        "#define bobbermode bobber3Dbasic",
        f"#define bobbermode {mode}"
    )

    if enable_string:
        content = content.replace(
            "//#define bobberString",
            "#define bobberString"
        )

    return content


def create_pack(version: str, image_name: str, suffix: str, mode: str, enable_string: bool):
    print(f"Creating {suffix}...")

    zip_filename = BASE_DIR.joinpath("build", version, f"3D-fishing-hook-bobber-{version}-{suffix}.zip")
    zip_filename.parent.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(zip_filename, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:

        # 1. Add all asset files except shader (we override it)
        for file_path in BASE_DIR.rglob("*"):
            rel_path = file_path.relative_to(BASE_DIR)
            if rel_path.is_file():
                if (rel_path.parts[0] in IGNORE
                    or rel_path.name == BOBBER
                    or rel_path.name.endswith(".zip")):
                    continue

                zf.write(rel_path)

        # 2. Add modified shader from memory
        shader_content = modify_shader_content(mode, enable_string)
        zf.writestr(BOBBER_PATH, shader_content.encode("utf-8"))

        # 3. Add pack.png
        with open(IMAGES_DIR / f"{image_name}.png", "rb") as f:
            zf.writestr("pack.png", f.read())


def main():
    data_file = BASE_DIR / "build-data.json"

    if not data_file.exists():
        raise FileNotFoundError("build-data.json not found in project root.")

    with open(data_file, "r", encoding="utf-8") as f:
        build_data = json.load(f)
    
    version = build_data["version"]

    for entry in build_data["presets"]:
        suffix = entry["suffix"]
        image = entry["image"]
        mode = entry["bobber_mode"]
        enable_string = entry["line"]
        create_pack(version, image, suffix, mode, enable_string)

    print("Done.")


if __name__ == "__main__":
    main()
