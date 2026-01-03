import os
try:
    from PIL import Image
except ImportError:
    print("PIL not found. Please install pillow: pip install pillow")
    exit(1)

def process_icon():
    input_path = "assets/game_icon.png"
    output_fg_path = "assets/game_icon_adaptive_foreground.png"
    output_bg_path = "assets/game_icon_adaptive_background.png"
    
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found.")
        return

    try:
        img = Image.open(input_path).convert("RGBA")
        
        # Target size for adaptive icons is usually 432x432
        target_size = (432, 432)
        
        # 1. Create Background (Pick color from corner or default to dark)
        # Try top-left pixel
        bg_color = img.getpixel((0, 0))
        # If transparent, default to black/dark gray
        if bg_color[3] == 0:
             bg_color = (30, 30, 30, 255)
        
        # Create pure color background image
        bg_img = Image.new("RGBA", target_size, bg_color)
        bg_img.save(output_bg_path)
        print(f"Created {output_bg_path} with color {bg_color}")

        # 2. Create Foreground (Logo centered and scaled)
        # Safe zone is circular, diameter ~264px.
        # We want the logo to fit comfortably within that.
        
        safe_diameter = 264
        # Calculate scale to fit larger dimension into safe zone
        scale = safe_diameter / max(img.size)
        
        new_w = int(img.size[0] * scale)
        new_h = int(img.size[1] * scale)
        
        resized_img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # Create transparent foreground canvas
        fg_img = Image.new("RGBA", target_size, (0, 0, 0, 0))
        
        # Paste centered
        paste_x = (target_size[0] - new_w) // 2
        paste_y = (target_size[1] - new_h) // 2
        
        fg_img.paste(resized_img, (paste_x, paste_y), resized_img)
        fg_img.save(output_fg_path)
        print(f"Created {output_fg_path}")
        
        # 3. Create Padded Main Icon (Foreground on Background)
        # This serves as a universal safe fallback
        padded_img = Image.new("RGBA", target_size, bg_color)
        padded_img.paste(resized_img, (paste_x, paste_y), resized_img)
        
        output_padded_path = "assets/game_icon_padded.png"
        padded_img.save(output_padded_path)
        print(f"Created {output_padded_path}")
        
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    process_icon()
