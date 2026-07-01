from PIL import Image, ImageDraw

def generate_cassette_icon(output_path):
    # Size for notification icon is usually 96x96 for xhdpi or 48x48
    # We will use 96x96
    size = 96
    image = Image.new('RGBA', (size, size), (0, 0, 0, 0)) # Transparent background
    draw = ImageDraw.Draw(image)
    
    # Cassette Tape Body (Rounded rectangle)
    # White shape
    draw.rounded_rectangle([10, 20, 86, 76], radius=6, fill=(255, 255, 255, 255))
    
    # Inner cutout for tape reels
    draw.rounded_rectangle([20, 40, 76, 56], radius=4, fill=(0, 0, 0, 0)) # Transparent cutout
    
    # Left and Right tape reels (circles inside the cutout)
    draw.ellipse([26, 42, 38, 54], fill=(255, 255, 255, 255))
    draw.ellipse([58, 42, 70, 54], fill=(255, 255, 255, 255))
    
    # Bottom trapezoid cutout (typical cassette shape at the bottom)
    draw.polygon([(26, 76), (70, 76), (64, 66), (32, 66)], fill=(0, 0, 0, 0))
    
    image.save(output_path, 'PNG')
    print(f"Generated {output_path}")

if __name__ == '__main__':
    generate_cassette_icon('android/app/src/main/res/drawable/ic_notification.png')
