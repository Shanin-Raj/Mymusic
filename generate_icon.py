import os
from PIL import Image

def create_notification_icon():
    input_path = r'd:\music\flutter_app\assets\mixtapelogo.jpeg'
    output_path = r'd:\music\flutter_app\android\app\src\main\res\drawable\ic_notification.png'

    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    img = Image.open(input_path).convert("RGBA")
    data = img.getdata()
    
    new_data = []
    # threshold for considering a pixel 'background'
    for item in data:
        r, g, b, a = item
        # The background is black, logo is green.
        if r < 30 and g < 30 and b < 30:
            new_data.append((255, 255, 255, 0)) # transparent
        else:
            new_data.append((255, 255, 255, 255)) # solid white

    img.putdata(new_data)
    
    # Crop to bounding box
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        
    # Resize to fit in 96x96 canvas, keeping aspect ratio
    max_size = 96
    ratio = min(max_size / img.width, max_size / img.height)
    new_size = (int(img.width * ratio), int(img.height * ratio))
    img = img.resize(new_size, Image.Resampling.LANCZOS)
    
    # Create 96x96 transparent canvas and paste the resized image in the center
    canvas = Image.new("RGBA", (max_size, max_size), (0, 0, 0, 0))
    offset_x = (max_size - img.width) // 2
    offset_y = (max_size - img.height) // 2
    canvas.paste(img, (offset_x, offset_y))
    
    canvas.save(output_path, "PNG")
    print(f"Saved notification icon to {output_path}")

if __name__ == '__main__':
    create_notification_icon()
