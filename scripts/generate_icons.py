import os
import subprocess
from PIL import Image, ImageDraw

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.abspath(os.path.join(base_dir, ".."))
    
    # 1. Create the SVG content matching login_page.dart exactly
    # In login_page.dart:
    # Outer circle: 150x150, color #E5EFFE
    # Inner circle: 96x96, color #FFFFFF
    # Icon: Icons.local_laundry_service_rounded, size: 68x68, color #1E64D4
    # The SVG path for local_laundry_service_rounded in 24x24 viewBox:
    path_d = (
        "M9.64,16.36c1.3,1.3,3.42,1.3,4.72,0c1.3-1.3,1.3-3.42,0-4.72L9.64,16.36z "
        "M18,2.01L6,2C4.89,2,4,2.89,4,4v16 c0,1.11,0.89,2,2,2h12c1.11,0,2-0.89,2-2V4C20,2.89,19.11,2.01,18,2.01z "
        "M11,5c0.55,0,1,0.45,1,1s-0.45,1-1,1s-1-0.45-1-1 S10.45,5,11,5z "
        "M8,5c0.55,0,1,0.45,1,1S8.55,7,8,7S7,6.55,7,6S7.45,5,8,5z "
        "M12,19c-2.76,0-5-2.24-5-5c0-2.76,2.24-5,5-5s5,2.24,5,5 C17,16.76,14.76,19,12,19z"
    )

    # HTML for rendering high-res transparent badge (just the circular logo)
    badge_html_content = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  html, body {{
    width: 1024px;
    height: 1024px;
    background: transparent;
    overflow: hidden;
    display: flex;
    align-items: center;
    justify-content: center;
  }}
</style>
</head>
<body>
  <svg width="1024" height="1024" viewBox="0 0 150 150" xmlns="http://www.w3.org/2000/svg">
    <circle cx="75" cy="75" r="75" fill="#E5EFFE" />
    <circle cx="75" cy="75" r="48" fill="#FFFFFF" />
    <g transform="translate(41, 41) scale(2.833333333)">
      <path d="{path_d}" fill="#1E64D4" />
    </g>
  </svg>
</body>
</html>
"""

    # HTML for rendering high-res full app launcher icon (squircle background like picture 1)
    # With a crisp modern rounded-card / squircle or soft background
    launcher_html_content = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  html, body {{
    width: 1024px;
    height: 1024px;
    background: transparent;
    overflow: hidden;
    display: flex;
    align-items: center;
    justify-content: center;
  }}
</style>
</head>
<body>
  <svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
    <!-- Rounded squircle container with subtle gradient -->
    <defs>
      <linearGradient id="bg" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#FFFFFF" />
        <stop offset="100%" stop-color="#F2F6FC" />
      </linearGradient>
      <filter id="shadow" x="-10%" y="-10%" width="120%" height="120%">
        <feDropShadow dx="0" dy="16" stdDeviation="24" flood-color="#1E64D4" flood-opacity="0.12" />
      </filter>
    </defs>
    
    <!-- Background Card -->
    <rect x="32" y="32" width="960" height="960" rx="220" ry="220" fill="url(#bg)" />
    <rect x="32" y="32" width="960" height="960" rx="220" ry="220" fill="none" stroke="#E2E8F0" stroke-width="8" />

    <!-- Outer Light Blue Circle with Soft Shadow -->
    <g filter="url(#shadow)">
      <circle cx="512" cy="512" r="340" fill="#E5EFFE" />
    </g>

    <!-- Inner White Circle -->
    <circle cx="512" cy="512" r="218" fill="#FFFFFF" />

    <!-- Washing Machine Icon in Center -->
    <g transform="translate(358, 358) scale(12.83333333)">
      <path d="{path_d}" fill="#1E64D4" />
    </g>
  </svg>
</body>
</html>
"""

    badge_html_path = os.path.join(base_dir, "badge.html")
    launcher_html_path = os.path.join(base_dir, "launcher.html")
    with open(badge_html_path, "w", encoding="utf-8") as f:
        f.write(badge_html_content)
    with open(launcher_html_path, "w", encoding="utf-8") as f:
        f.write(launcher_html_content)

    edge_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    badge_png = os.path.join(base_dir, "badge_1024.png")
    launcher_png = os.path.join(base_dir, "launcher_1024.png")

    print("Rendering badge with Edge...")
    subprocess.run([
        edge_path,
        "--headless",
        "--disable-gpu",
        "--default-background-color=00000000",
        f"--screenshot={badge_png}",
        "--window-size=1024,1024",
        f"file:///{badge_html_path.replace(os.sep, '/')}"
    ], check=True)

    print("Rendering launcher with Edge...")
    subprocess.run([
        edge_path,
        "--headless",
        "--disable-gpu",
        "--default-background-color=00000000",
        f"--screenshot={launcher_png}",
        "--window-size=1024,1024",
        f"file:///{launcher_html_path.replace(os.sep, '/')}"
    ], check=True)

    print("Checking rendered images...")
    img_badge = Image.open(badge_png).convert("RGBA")
    img_launcher = Image.open(launcher_png).convert("RGBA")
    print(f"Badge size: {img_badge.size}, Launcher size: {img_launcher.size}")

    # Generate assets/images/app_logo.png (512x512 circular logo with badge)
    assets_dir = os.path.join(project_dir, "assets", "images")
    os.makedirs(assets_dir, exist_ok=True)
    img_badge.resize((512, 512), Image.Resampling.LANCZOS).save(
        os.path.join(assets_dir, "app_logo.png"), "PNG"
    )
    img_launcher.resize((512, 512), Image.Resampling.LANCZOS).save(
        os.path.join(assets_dir, "app_icon.png"), "PNG"
    )
    print(f"Saved {assets_dir}/app_logo.png and app_icon.png")

    # Generate Android legacy launcher icons (ic_launcher.png and ic_launcher_round.png)
    # mipmap sizes:
    # mdpi: 48x48
    # hdpi: 72x72
    # xhdpi: 96x96
    # xxhdpi: 144x144
    # xxxhdpi: 192x192
    res_dir = os.path.join(project_dir, "android", "app", "src", "main", "res")
    mipmap_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }

    # For round icon: circular crop of img_launcher
    mask = Image.new("L", (1024, 1024), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((32, 32, 992, 992), fill=255)
    img_round = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    img_round.paste(img_launcher, (0, 0), mask=mask)

    # For adaptive foreground: 432x432 (108dp * 4) with logo in center 264x264
    img_foreground = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    badge_for_foreground = img_badge.resize((264, 264), Image.Resampling.LANCZOS)
    img_foreground.paste(badge_for_foreground, (84, 84), mask=badge_for_foreground)

    # For splash logo in drawable:
    drawable_dir = os.path.join(res_dir, "drawable")
    os.makedirs(drawable_dir, exist_ok=True)
    img_badge.resize((288, 288), Image.Resampling.LANCZOS).save(
        os.path.join(drawable_dir, "splash_logo.png"), "PNG"
    )

    for folder, size in mipmap_sizes.items():
        target_folder = os.path.join(res_dir, folder)
        os.makedirs(target_folder, exist_ok=True)
        
        # ic_launcher.png
        icon_resized = img_launcher.resize((size, size), Image.Resampling.LANCZOS)
        icon_resized.save(os.path.join(target_folder, "ic_launcher.png"), "PNG")

        # ic_launcher_round.png
        round_resized = img_round.resize((size, size), Image.Resampling.LANCZOS)
        round_resized.save(os.path.join(target_folder, "ic_launcher_round.png"), "PNG")

        # ic_launcher_foreground.png (for adaptive icons across densities)
        # density ratios: mdpi=108, hdpi=162, xhdpi=216, xxhdpi=324, xxxhdpi=432
        fg_size = int(size * 108 / 48)
        fg_resized = img_foreground.resize((fg_size, fg_size), Image.Resampling.LANCZOS)
        fg_resized.save(os.path.join(target_folder, "ic_launcher_foreground.png"), "PNG")

        print(f"Generated {folder}: {size}x{size}")

    print("All icons successfully generated!")

if __name__ == "__main__":
    main()
