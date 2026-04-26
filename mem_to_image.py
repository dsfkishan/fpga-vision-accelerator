import os
from PIL import Image

def mem_to_image(mem_file, output_image="fpga_result.png", size=(128, 128)):
    # Get current directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    hex_path = os.path.join(script_dir, mem_file)
    out_path = os.path.join(script_dir, output_image)

    try:
        # Create a new blank RGB image
        img = Image.new('RGB', size)
        pixels = img.load()

        with open(hex_path, "r") as f:
            lines = f.readlines()

        if len(lines) < size[0] * size[1]:
            print(f"⚠️ Warning: File only has {len(lines)} pixels, expected {size[0]*size[1]}")

        # Parse hex and write to image
        i = 0
        for y in range(size[1]):
            for x in range(size[0]):
                if i < len(lines):
                    # Clean up string (remove \n) and parse
                    hex_str = lines[i].strip()
                    
                    # Split into R, G, B components
                    r = int(hex_str[0:2], 16)
                    g = int(hex_str[2:4], 16)
                    b = int(hex_str[4:6], 16)
                    
                    pixels[x, y] = (r, g, b)
                    i += 1

        img.save(out_path)
        print(f"✅ Success! Image saved as {output_image}")
        img.show() # Automatically pop open the image viewer

    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    # Make sure output_image.hex is in the same folder as this script
    mem_to_image("final_edge_image.mem")