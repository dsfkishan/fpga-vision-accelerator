import os
from PIL import Image

def generate_mem_file(image_path, output_path="image_in.mem", size=(128, 128)):
    try:
        # Open image and ensure it is standard RGB (drops alpha/transparency channels)
        img = Image.open(image_path).convert('RGB')
        
        # Resize to fit safely in standard BRAM (128x128 = 16,384 pixels)
        img = img.resize(size)
        pixels = img.load()

        # Write to the .mem file
        with open(output_path, "w") as f:
            for y in range(img.height):
                for x in range(img.width):
                    r, g, b = pixels[x, y]
                    # Write exactly 24 bits (6 hex characters) per line
                    # Example: pure red becomes "ff0000"
                    f.write(f"{r:02x}{g:02x}{b:02x}\n")
        
        print(f"✅ Success! '{output_path}' generated.")
        print(f"📊 Total pixels written: {img.width * img.height}")
        print("Ready for Vivado $readmemh!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        print("Check that your image file exists in the same directory.")

if __name__ == "__main__":
    # 1. Get the exact folder path where this script is saved
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # 2. Combine that folder path with your image name
    test_image_name = "test_image_2.webp"
    full_image_path = os.path.join(script_dir, test_image_name)
    
    # 3. Also save the output .mem file in the exact same folder
    full_output_path = os.path.join(script_dir, "image_in.mem")
    
    generate_mem_file(full_image_path, output_path=full_output_path)