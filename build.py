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


def create_pack(version: str, image_name: str, suffix: str, mode: str, enable_string: bool) -> Path:
    zip_filename = BASE_DIR.joinpath("build", f"3D-fishing-hook-bobber-{version}-{suffix}.zip")
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

    return zip_filename

def main():
    data_file = BASE_DIR / "build-data.json"

    if not data_file.exists():
        raise FileNotFoundError("build-data.json not found in project root.")

    with open(data_file, "r", encoding="utf-8") as f:
        build_data = json.load(f)

    version = build_data["version"]
    metadata = {}
    metadata["mc_versions"] = build_data["mc_versions"]
    metadata["changelog"] = build_data["changelog"]
    metadata_entries = {}
    metadata["versions"] = metadata_entries
    version_list = []
    metadata["version_list"] = version_list

    for entry in build_data["presets"]:
        preset_id = entry["id"]
        suffix = entry["suffix"]
        image = entry["image"]
        mode = entry["bobber_mode"]
        enable_string = entry["line"]

        print(f"Creating {preset_id}...")

        zip_path = create_pack(version, image, suffix, mode, enable_string)

        metadata_entries.update({preset_id: {
            "version-id": f"{version}-{preset_id}",
            "name": f"3D Bobber {version} {suffix.replace('-', '')}",
            "path": str(zip_path.relative_to(BASE_DIR))
        }})
        version_list.append(preset_id)

    # Write metadata.json
    metadata_path = BASE_DIR.joinpath("build", "metadata.json")
    metadata_path.parent.mkdir(exist_ok=True, parents=True)
    with open(metadata_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=4)

    print("Done.")


if __name__ == "__main__":
    main()
