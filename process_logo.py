import sys
from PIL import Image

def process():
    try:
        img = Image.open('assets/images/logo.png').convert("RGBA")
        pixels = img.load()
        width, height = img.size
        
        for y in range(height):
            for x in range(width):
                r, g, b, a = pixels[x, y]
                
                # Calculate saturation / color variance
                cmax = max(r, g, b)
                cmin = min(r, g, b)
                chroma = cmax - cmin
                v = sum([r,g,b])/3.0
                
                # If pixel is heavily white
                if r > 245 and g > 245 and b > 245:
                    pixels[x, y] = (255, 255, 255, 0)
                # If pixel is greyscale (text, shadows, mountains, paper plane)
                elif chroma < 30:
                    # We want to change dark grey/black to white, preserving anti-aliasing against the dark background.
                    # Original text was dark (V) on white (255) background.
                    # Alpha of the original dark shape = (255 - V).
                    alpha = max(0, min(255, int(255 - v)))
                    
                    # Some mountains might be slightly tinted. We just cast them to pure white with varying alpha.
                    pixels[x, y] = (255, 255, 255, alpha)
                else:
                    # It's a colored pixel (like the beige map pin)
                    # We leave it completely untouched so the branding remains intact
                    pass
                    
        img.save('assets/images/logo_dark.png')
        print("Generated logo_dark.png successfully.")
    except Exception as e:
        print("Error:", e)

if __name__ == '__main__':
    process()
