#!/usr/bin/env python3
"""
Download correct food product images from Pexels (free, no API key needed)
"""

import os
import time
import requests

# Directory to save images
IMAGE_DIR = "assets/images/products"

# Create directory if it doesn't exist
if not os.path.exists(IMAGE_DIR):
    os.makedirs(IMAGE_DIR)

# Product list with Pexels direct download URLs (free stock photos)
products = [
    # Obst & Gemüse
    {'name': 'Äpfel', 'url': 'https://images.pexels.com/photos/102104/pexels-photo-102104.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'apfel.jpg'},
    {'name': 'Bananen', 'url': 'https://images.pexels.com/photos/2872755/pexels-photo-2872755.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'bananen.jpg'},
    {'name': 'Bio-Äpfel', 'url': 'https://images.pexels.com/photos/209439/pexels-photo-209439.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'bio_apfel.jpg'},
    {'name': 'Bio-Bananen', 'url': 'https://images.pexels.com/photos/2316466/pexels-photo-2316466.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'bio_bananen.jpg'},
    {'name': 'Tomaten', 'url': 'https://images.pexels.com/photos/1327838/pexels-photo-1327838.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'tomaten.jpg'},
    {'name': 'Gurken', 'url': 'https://images.pexels.com/photos/2329440/pexels-photo-2329440.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'gurken.jpg'},
    {'name': 'Kartoffeln', 'url': 'https://images.pexels.com/photos/144248/potatoes-vegetables-erdfrucht-bio-144248.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'kartoffeln.jpg'},

    # Milchprodukte
    {'name': 'Vollmilch', 'url': 'https://images.pexels.com/photos/248412/pexels-photo-248412.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'vollmilch.jpg'},
    {'name': 'Bio-Vollmilch', 'url': 'https://images.pexels.com/photos/1210005/pexels-photo-1210005.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'bio_vollmilch.jpg'},
    {'name': 'Joghurt', 'url': 'https://images.pexels.com/photos/414262/pexels-photo-414262.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'joghurt.jpg'},
    {'name': 'Butter', 'url': 'https://images.pexels.com/photos/531334/pexels-photo-531334.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'butter.jpg'},
    {'name': 'Gouda Käse', 'url': 'https://images.pexels.com/photos/821365/pexels-photo-821365.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'gouda.jpg'},
    {'name': 'Quark', 'url': 'https://images.pexels.com/photos/4109998/pexels-photo-4109998.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'quark.jpg'},

    # Fleisch & Wurst - KORRIGIERT!
    {'name': 'Hähnchenbrust', 'url': 'https://images.pexels.com/photos/616354/pexels-photo-616354.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'haehnchen.jpg'},
    {'name': 'Rinderhack', 'url': 'https://images.pexels.com/photos/128408/pexels-photo-128408.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'rinderhack.jpg'},
    {'name': 'Bratwurst', 'url': 'https://images.pexels.com/photos/929137/pexels-photo-929137.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'bratwurst.jpg'},
    {'name': 'Schnitzel', 'url': 'https://images.pexels.com/photos/410648/pexels-photo-410648.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'schnitzel.jpg'},

    # Brot & Backwaren
    {'name': 'Vollkornbrot', 'url': 'https://images.pexels.com/photos/1775043/pexels-photo-1775043.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'vollkornbrot.jpg'},
    {'name': 'Brötchen', 'url': 'https://images.pexels.com/photos/209206/pexels-photo-209206.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'broetchen.jpg'},
    {'name': 'Milchbrötchen', 'url': 'https://images.pexels.com/photos/461060/pexels-photo-461060.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'milchbroetchen.jpg'},
    {'name': 'Croissants', 'url': 'https://images.pexels.com/photos/2135/food-france-morning-breakfast.jpg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'croissants.jpg'},

    # Getränke
    {'name': 'Mineralwasser', 'url': 'https://images.pexels.com/photos/1000084/pexels-photo-1000084.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'mineralwasser.jpg'},
    {'name': 'Apfelsaft', 'url': 'https://images.pexels.com/photos/1334295/pexels-photo-1334295.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'apfelsaft.jpg'},
    {'name': 'Cola', 'url': 'https://images.pexels.com/photos/50593/coca-cola-cold-drink-soft-drink-coke-50593.jpeg?auto=compress&cs=tinysrgb&w=400&h=400&dpr=1', 'filename': 'cola.jpg'},
]

def download_image(url, filename):
    """Download an image from URL"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code == 200:
            filepath = os.path.join(IMAGE_DIR, filename)
            with open(filepath, 'wb') as f:
                f.write(response.content)
            print(f"[OK] Downloaded: {filename}")
            return True
        else:
            print(f"[FAIL] Failed to download {filename}: Status {response.status_code}")
            return False
    except Exception as e:
        print(f"[ERROR] Error downloading {filename}: {e}")
        return False

# Download all product images
print("Downloading CORRECT food product images from Pexels...")
print(f"Saving to: {os.path.abspath(IMAGE_DIR)}")
print("-" * 50)

successful = 0
failed = 0

for product in products:
    print(f"Downloading {product['name']}...")
    if download_image(product['url'], product['filename']):
        successful += 1
    else:
        failed += 1
    time.sleep(0.5)  # Be polite to the server

print("-" * 50)
print(f"Download complete!")
print(f"[OK] Successful: {successful}")
print(f"[FAIL] Failed: {failed}")
print(f"Images saved in: {os.path.abspath(IMAGE_DIR)}")