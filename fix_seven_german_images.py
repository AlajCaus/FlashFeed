import os
import requests
from time import sleep

# 7 Bilder mit korrekten deutschen Produkten von Pixabay
# Pixabay bietet kostenlose Bilder ohne Attribution
products_to_fix = [
    # Bratwurst - richtige deutsche Bratwurst
    {'name': 'Bratwurst', 'url': 'https://cdn.pixabay.com/photo/2016/11/19/21/04/bratwurst-1841071_1280.jpg', 'filename': 'bratwurst.jpg'},

    # Brötchen - deutsche Brötchen/Semmeln
    {'name': 'Brötchen', 'url': 'https://cdn.pixabay.com/photo/2016/03/27/21/59/bread-1284438_1280.jpg', 'filename': 'broetchen.jpg'},

    # Rinderhack - Hackfleisch/Mett
    {'name': 'Rinderhack', 'url': 'https://cdn.pixabay.com/photo/2021/01/06/10/11/minced-meat-5893943_1280.jpg', 'filename': 'rinderhack.jpg'},

    # Butter - echte Butter
    {'name': 'Butter', 'url': 'https://cdn.pixabay.com/photo/2018/06/21/14/54/butter-3488807_1280.jpg', 'filename': 'butter.jpg'},

    # Bio Vollmilch - Milchflasche/Glas
    {'name': 'Bio Vollmilch', 'url': 'https://cdn.pixabay.com/photo/2017/07/05/15/41/milk-2474993_1280.jpg', 'filename': 'bio_vollmilch.jpg'},

    # Milchbrötchen - süße Brötchen
    {'name': 'Milchbrötchen', 'url': 'https://cdn.pixabay.com/photo/2019/03/24/14/23/bread-4077812_1280.jpg', 'filename': 'milchbroetchen.jpg'},

    # Vollkornbrot - dunkles Vollkornbrot
    {'name': 'Vollkornbrot', 'url': 'https://cdn.pixabay.com/photo/2014/07/22/09/59/bread-399286_1280.jpg', 'filename': 'vollkornbrot.jpg'},
]

print("Korrigiere 7 deutsche Produktbilder von Pixabay...")
print("=" * 50)

success_count = 0
fail_count = 0

for product in products_to_fix:
    filepath = f'assets/images/products/{product["filename"]}'

    try:
        print(f"Lade {product['name']}...", end="")

        # Headers um wie ein Browser auszusehen
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }

        response = requests.get(product['url'], headers=headers, timeout=10)

        if response.status_code == 200:
            with open(filepath, 'wb') as f:
                f.write(response.content)
            print(f" [OK] {product['filename']}")
            success_count += 1
        else:
            print(f" [FEHLER] Status code: {response.status_code}")
            fail_count += 1

    except Exception as e:
        print(f" [FEHLER] {str(e)}")
        fail_count += 1

    # Kleine Pause zwischen Downloads
    sleep(0.5)

print("\n" + "=" * 50)
print(f"Korrektur abgeschlossen!")
print(f"Erfolgreich korrigiert: {success_count}")
print(f"Fehlgeschlagen: {fail_count}")
print(f"Gesamt: {len(products_to_fix)}")