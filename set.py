import os
import sys
from PIL import Image

# Check that a folder path was provided
if len(sys.argv) != 2:
    print("Usage: python set.py <folder_path>")
    sys.exit(1)

folder_path = sys.argv[1]

if not os.path.isdir(folder_path):
    print(f"Error: '{folder_path}' is not a valid directory.")
    sys.exit(1)

for filename in os.listdir(folder_path):
    if filename.lower().endswith(".png"):
        file_path = os.path.join(folder_path, filename)

        with Image.open(file_path) as img:
            img = img.convert("RGBA")
            pixels = img.load()
            width, height = img.size

            if width >= 2 and height >= 1:
                pixels[0, 0] = (255, 0, 255, 0)              # top-left
                pixels[width - 1, 0] = (0, 255, 255, 0)     # top-right

                img.save(file_path)
                print(f"Updated: {filename}")

print("Done.")
