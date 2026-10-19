import os
import math
from PIL import Image, ImageDraw, ImageFilter

def create_priostack_icon(size=1024):
    # Ultra High Resolution Master Image with Alpha
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    scale = size / 1024.0
    
    # 1. Background Squircle with subtle gradient
    # Dimensions: 880x880 centered (margin 72px)
    margin = int(72 * scale)
    corner_radius = int(220 * scale)
    box = [margin, margin, size - margin, size - margin]
    
    # Create background mask with rounded rectangle
    bg_mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(bg_mask)
    mask_draw.rounded_rectangle(box, radius=corner_radius, fill=255)
    
    # Gradient for background: Deep Obsidian/Midnight Slate
    bg_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    for y in range(size):
        ratio = y / size
        # Top: #121520 -> Bottom: #07080D
        r = int(18 * (1 - ratio) + 7 * ratio)
        g = int(21 * (1 - ratio) + 8 * ratio)
        b = int(32 * (1 - ratio) + 13 * ratio)
        ImageDraw.Draw(bg_img).line([(0, y), (size, y)], fill=(r, g, b, 255))
        
    img.paste(bg_img, (0, 0), bg_mask)
    
    # Ambient border glow / hairline stroke
    border_draw = ImageDraw.Draw(img)
    border_draw.rounded_rectangle(box, radius=corner_radius, outline=(59, 130, 246, 120), width=int(6 * scale))
    
    # 2. Draw 3 Floating Priority Stack Layers
    # Layer Dimensions & Perspective
    # Center X: 512, Y: 320 (top), 490 (mid), 660 (bottom)
    
    # Helper to draw isometric-style rounded horizontal priority slab
    def draw_stack_slab(center_y, width, height, colors, glow=False, is_top=False):
        cx = size / 2.0
        cy = center_y * scale
        w = width * scale
        h = height * scale
        r = int(26 * scale)
        
        slab_box = [int(cx - w / 2), int(cy - h / 2), int(cx + w / 2), int(cy + h / 2)]
        
        # Soft drop shadow
        shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        s_draw = ImageDraw.Draw(shadow)
        s_box = [slab_box[0], slab_box[1] + int(18 * scale), slab_box[2], slab_box[3] + int(24 * scale)]
        shadow_color = (0, 0, 0, 160) if not glow else (0, 180, 255, 70)
        s_draw.rounded_rectangle(s_box, radius=r, fill=shadow_color)
        shadow = shadow.filter(ImageFilter.GaussianBlur(radius=int(22 * scale)))
        img.alpha_composite(shadow)
        
        # Slab body with gradient
        slab_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        slab_mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(slab_mask).rounded_rectangle(slab_box, radius=r, fill=255)
        
        s_draw_grad = ImageDraw.Draw(slab_img)
        c_start, c_end = colors
        for x in range(slab_box[0], slab_box[2]):
            t = (x - slab_box[0]) / (slab_box[2] - slab_box[0] + 1e-5)
            cr = int(c_start[0] * (1 - t) + c_end[0] * t)
            cg = int(c_start[1] * (1 - t) + c_end[1] * t)
            cb = int(c_start[2] * (1 - t) + c_end[2] * t)
            ca = int(c_start[3] * (1 - t) + c_end[3] * t)
            s_draw_grad.line([(x, slab_box[1]), (x, slab_box[3])], fill=(cr, cg, cb, ca))
            
        img.paste(slab_img, (0, 0), slab_mask)
        
        # Specular top highlight
        highlight_draw = ImageDraw.Draw(img)
        hl_y = slab_box[1] + int(2 * scale)
        highlight_draw.line([(slab_box[0] + r, hl_y), (slab_box[2] - r, hl_y)], fill=(255, 255, 255, 140 if is_top else 70), width=int(3 * scale))
        
        # If top active priority, add the Neon Green Sanctuary indicator pip on the right
        if is_top:
            pip_x = slab_box[2] - int(60 * scale)
            pip_y = int(cy)
            pip_r = int(14 * scale)
            # Pip Glow
            pip_glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
            ImageDraw.Draw(pip_glow).ellipse([pip_x - pip_r*2, pip_y - pip_r*2, pip_x + pip_r*2, pip_y + pip_r*2], fill=(16, 185, 129, 120))
            pip_glow = pip_glow.filter(ImageFilter.GaussianBlur(radius=int(10 * scale)))
            img.alpha_composite(pip_glow)
            # Pip Core
            pip_core = ImageDraw.Draw(img)
            pip_core.ellipse([pip_x - pip_r, pip_y - pip_r, pip_x + pip_r, pip_y + pip_r], fill=(52, 211, 153, 255), outline=(255, 255, 255, 220), width=int(2*scale))
            
            # Left side priority bar indicator
            p_bar_box = [slab_box[0] + int(45 * scale), int(cy - 6 * scale), slab_box[0] + int(120 * scale), int(cy + 6 * scale)]
            pip_core.rounded_rectangle(p_bar_box, radius=int(6 * scale), fill=(255, 255, 255, 210))
            
    # Bottom Slab (Base backlog / Stack foundation)
    draw_stack_slab(center_y=680, width=540, height=92, colors=((124, 58, 237, 240), (99, 102, 241, 240)))
    
    # Middle Slab (Next up / Call Frame)
    draw_stack_slab(center_y=510, width=580, height=100, colors=((59, 130, 246, 255), (79, 70, 229, 255)))
    
    # Top Slab (Active Priority / Sanctuary - Glowing)
    draw_stack_slab(center_y=340, width=620, height=110, colors=((0, 229, 255, 255), (0, 114, 255, 255)), glow=True, is_top=True)
    
    return img

def create_svg():
    return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <defs>
    <!-- Background Gradient -->
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#121520" />
      <stop offset="100%" stop-color="#07080D" />
    </linearGradient>

    <!-- Top Slab (Sanctuary / Active) -->
    <linearGradient id="topSlab" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#00E5FF" />
      <stop offset="100%" stop-color="#0066FF" />
    </linearGradient>

    <!-- Mid Slab -->
    <linearGradient id="midSlab" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#3B82F6" />
      <stop offset="100%" stop-color="#4F46E5" />
    </linearGradient>

    <!-- Bottom Slab -->
    <linearGradient id="bottomSlab" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#7C3AED" />
      <stop offset="100%" stop-color="#4338CA" />
    </linearGradient>

    <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="10" result="blur" />
      <feComposite in="SourceGraphic" in2="blur" operator="over" />
    </filter>

    <filter id="shadow" x="-10%" y="-10%" width="120%" height="140%">
      <feDropShadow dx="0" dy="10" stdDeviation="8" flood-color="#000" flood-opacity="0.6"/>
    </filter>
  </defs>

  <!-- Squircle Base -->
  <rect x="36" y="36" width="440" height="440" rx="110" fill="url(#bgGrad)" stroke="#3B82F6" stroke-opacity="0.35" stroke-width="3" />

  <!-- Layer 3: Bottom (Base) -->
  <g filter="url(#shadow)">
    <rect x="120" y="316" width="272" height="52" rx="15" fill="url(#bottomSlab)" />
    <line x1="135" y1="318" x2="377" y2="318" stroke="#FFFFFF" stroke-opacity="0.25" stroke-width="2" stroke-linecap="round"/>
  </g>

  <!-- Layer 2: Middle -->
  <g filter="url(#shadow)">
    <rect x="106" y="228" width="300" height="56" rx="16" fill="url(#midSlab)" />
    <line x1="122" y1="230" x2="390" y2="230" stroke="#FFFFFF" stroke-opacity="0.3" stroke-width="2" stroke-linecap="round"/>
  </g>

  <!-- Layer 1: Top (Active Focus / Call Stack Top) -->
  <g filter="url(#shadow)">
    <rect x="92" y="136" width="328" height="64" rx="18" fill="url(#topSlab)" filter="url(#glow)"/>
    <line x1="110" y1="138" x2="402" y2="138" stroke="#FFFFFF" stroke-opacity="0.6" stroke-width="2.5" stroke-linecap="round"/>
    
    <!-- Top Active Indicators -->
    <rect x="116" y="164" width="40" height="8" rx="4" fill="#FFFFFF" fill-opacity="0.85" />
    <circle cx="386" cy="168" r="8" fill="#10B981" stroke="#FFFFFF" stroke-width="1.5" />
  </g>
</svg>
'''

if __name__ == "__main__":
    print("Generating PrioStack Master High-Res Icons...")
    master = create_priostack_icon(1024)
    
    # Target folders
    repo_dir = r"d:\Workspace\DamelIT\Antigravity\PrioStack"
    web_dir = os.path.join(repo_dir, "web")
    icons_dir = os.path.join(web_dir, "icons")
    windows_res_dir = os.path.join(repo_dir, "windows", "runner", "resources")
    installer_dir = os.path.join(repo_dir, "installer")
    os.makedirs(icons_dir, exist_ok=True)
    os.makedirs(windows_res_dir, exist_ok=True)
    os.makedirs(installer_dir, exist_ok=True)
    
    # 1. Favicon PNG (64x64 multi-purpose / crisp)
    fav_64 = master.resize((64, 64), Image.Resampling.LANCZOS)
    fav_64.save(os.path.join(web_dir, "favicon.png"), "PNG")
    fav_64.save(os.path.join(web_dir, "favicon.ico"), format="ICO", sizes=[(16, 16), (32, 32), (48, 48), (64, 64)])
    
    # 2. Windows Multi-Size ICO for desktop .exe and runner
    ico_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    master.save(os.path.join(windows_res_dir, "app_icon.ico"), format="ICO", sizes=ico_sizes)
    master.save(os.path.join(installer_dir, "app_icon.ico"), format="ICO", sizes=ico_sizes)
    
    # 3. SVG Favicon
    with open(os.path.join(web_dir, "favicon.svg"), "w", encoding="utf-8") as f:
        f.write(create_svg())
        
    # 4. PWA Icons
    master.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(icons_dir, "Icon-192.png"), "PNG")
    master.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(icons_dir, "Icon-512.png"), "PNG")
    master.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(icons_dir, "Icon-maskable-192.png"), "PNG")
    master.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(icons_dir, "Icon-maskable-512.png"), "PNG")
    
    # Also save master in web
    master.resize((256, 256), Image.Resampling.LANCZOS).save(os.path.join(web_dir, "priostack_logo.png"), "PNG")
    
    print("All PrioStack icons (Web + Windows app_icon.ico + Installer) generated successfully!")
