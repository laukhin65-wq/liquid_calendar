"""
Скрипт для обработки иконки приложения.
Удаляет тёмный фон и обрезает до иконки.

Использование:
  python crop_icon.py input.png output.png

Требования:
  pip install Pillow
"""

import sys
from PIL import Image
import numpy as np

def remove_dark_bg(img, threshold=60):
    """Удаляет тёмный фон (заменяет на прозрачный)."""
    data = np.array(img)
    r, g, b = data[:,:,0], data[:,:,1], data[:,:,2]
    brightness = (r.astype(int) + g.astype(int) + b.astype(int)) / 3
    mask = brightness < threshold
    data[mask] = [0, 0, 0, 0]
    return Image.fromarray(data)

def crop_to_content(img, padding=20):
    """Обрезает изображение до содержимого с отступом."""
    bbox = img.getbbox()
    if bbox is None:
        return img
    left = max(0, bbox[0] - padding)
    top = max(1, bbox[1] - padding)
    right = min(img.width, bbox[2] + padding)
    bottom = min(img.height, bbox[3] + padding)
    size = max(right - left, bottom - top)
    return img.crop((left, top, left + size, bottom + size))

def main():
    if len(sys.argv) < 3:
        print("Использование: python crop_icon.py input.png output.png")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    img = Image.open(input_path).convert("RGBA")
    print(f"Загружено: {input_path} ({img.width}x{img.height})")

    img = remove_dark_bg(img, threshold=80)
    print("Фон удалён")

    img = crop_to_content(img, padding=30)
    print(f"Обрезано до: {img.width}x{img.height}")

    img = img.resize((1024, 1024), Image.LANCZOS)
    print("Масштабировано до 1024x1024")

    img.save(output_path, "PNG")
    print(f"Сохранено: {output_path}")

if __name__ == "__main__":
    main()
