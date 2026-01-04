#!/usr/bin/env python3
"""
Process eye icons v4: Remove checkered backgrounds and make square to prevent stretching
"""
from PIL import Image
import os

def remove_checkered_background_and_make_square(input_path, output_path):
    """
    Remove checkered/gray backgrounds and add padding to make icons square.
    This prevents vertical stretching in the menu bar.
    """
    print(f"Processing {os.path.basename(input_path)}...")

    # Open image and convert to RGBA
    img = Image.open(input_path).convert("RGBA")

    original_size = img.size
    print(f"  Original size: {original_size[0]}x{original_size[1]}")

    # Get image data
    data = img.getdata()

    new_data = []
    removed_count = 0

    # Remove gray/checkered background
    for item in data:
        r, g, b, a = item

        # Check if pixel is grayscale (R, G, B are similar)
        color_variance = max(r, g, b) - min(r, g, b)

        # If it's a gray color (low variance between RGB channels)
        # AND it's relatively light (above a certain brightness)
        is_gray = color_variance < 30
        is_light = (r + g + b) / 3 > 150  # Average brightness threshold

        # Also check for specific gray ranges
        is_light_gray = (180 <= r <= 245) and (180 <= g <= 245) and (180 <= b <= 245)

        if (is_gray and is_light) or is_light_gray:
            # Make it transparent
            new_data.append((255, 255, 255, 0))
            removed_count += 1
        else:
            # Keep the pixel (this should be the actual eye design)
            new_data.append(item)

    # Update image data
    img.putdata(new_data)

    # Crop to remove excess transparent space
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        print(f"  ✓ Cropped to {img.size[0]}x{img.size[1]}")

    # Add a touch of vertical padding before squaring
    width, height = img.size
    extra_vertical_padding = max(2, int(round(height * 0.06)))
    padded_height = height + (extra_vertical_padding * 2)
    padded_img = Image.new('RGBA', (width, padded_height), (255, 255, 255, 0))
    padded_img.paste(img, (0, extra_vertical_padding), img)
    img = padded_img
    print(f"  ✓ Added vertical padding: {extra_vertical_padding}px top/bottom")

    # Now make it square by adding transparent padding
    width, height = img.size

    # Determine the size of the square (use the larger dimension)
    max_dimension = max(width, height)

    # Create a new square image with transparent background
    square_img = Image.new('RGBA', (max_dimension, max_dimension), (255, 255, 255, 0))

    # Calculate position to center the eye content
    paste_x = (max_dimension - width) // 2
    paste_y = (max_dimension - height) // 2

    # Paste the eye image onto the square canvas
    square_img.paste(img, (paste_x, paste_y), img)

    print(f"  ✓ Made square: {max_dimension}x{max_dimension}")
    print(f"  ✓ Eye content centered with padding")

    # Save processed image
    square_img.save(output_path, "PNG")

    total_pixels = len(data)
    percent_removed = (removed_count / total_pixels) * 100
    print(f"  ✓ Removed {percent_removed:.1f}% background pixels")
    print(f"  ✓ Saved to {os.path.basename(output_path)}")

def main():
    # Get the repository root (parent directory of scripts/)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(script_dir)
    resources_dir = os.path.join(repo_root, "Sources/VibeWatch/Resources")

    # Process from the original backup files
    icons = [
        ("alert-original.png", "alert.png"),
        ("concerned-original.png", "concerned.png"),
        ("exhausted-original.png", "exhausted.png"),
    ]

    print("👀 Processing Vibe Watch eye icons (Square Format)...")
    print(f"Resources directory: {resources_dir}\n")

    for input_name, output_name in icons:
        input_path = os.path.join(resources_dir, input_name)
        output_path = os.path.join(resources_dir, output_name)

        if os.path.exists(input_path):
            try:
                remove_checkered_background_and_make_square(input_path, output_path)
                print()
            except Exception as e:
                print(f"✗ Error processing {input_name}: {e}\n")
        else:
            print(f"✗ File not found: {input_name}\n")

    print("✓ Done! All eye icons are now square and won't stretch in menu bar.")

if __name__ == "__main__":
    main()
