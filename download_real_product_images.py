#!/usr/bin/env python3
"""
Download real product images from Unsplash for FlashFeed app
"""

import os
import time
import requests

# Directory to save images
IMAGE_DIR = "assets/images/products"

# Create directory if it doesn't exist
if not os.path.exists(IMAGE_DIR):
    os.makedirs(IMAGE_DIR)

# Product list with Unsplash direct image URLs
products = [
    # Obst & Gemüse
    {'name': 'Äpfel', 'url': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400&h=400&fit=crop', 'filename': 'apfel.jpg'},
    {'name': 'Bananen', 'url': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400&h=400&fit=crop', 'filename': 'bananen.jpg'},
    {'name': 'Bio-Äpfel', 'url': 'https://images.unsplash.com/photo-1569870499705-504209102861?w=400&h=400&fit=crop', 'filename': 'bio_apfel.jpg'},
    {'name': 'Bio-Bananen', 'url': 'https://images.unsplash.com/photo-1603833665858-e61d17a86224?w=400&h=400&fit=crop', 'filename': 'bio_bananen.jpg'},
    {'name': 'Tomaten', 'url': 'https://images.unsplash.com/photo-1546470427-227d2375f0c0?w=400&h=400&fit=crop', 'filename': 'tomaten.jpg'},
    {'name': 'Gurken', 'url': 'https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?w=400&h=400&fit=crop', 'filename': 'gurken.jpg'},
    {'name': 'Kartoffeln', 'url': 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400&h=400&fit=crop', 'filename': 'kartoffeln.jpg'},

    # Milchprodukte
    {'name': 'Vollmilch', 'url': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400&h=400&fit=crop', 'filename': 'vollmilch.jpg'},
    {'name': 'Bio-Vollmilch', 'url': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400&h=400&fit=crop', 'filename': 'bio_vollmilch.jpg'},
    {'name': 'Joghurt', 'url': 'https://images.unsplash.com/photo-1488477304112-4944851de03d?w=400&h=400&fit=crop', 'filename': 'joghurt.jpg'},
    {'name': 'Butter', 'url': 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=400&h=400&fit=crop', 'filename': 'butter.jpg'},
    {'name': 'Gouda', 'url': 'https://images.unsplash.com/photo-1486297678162-eb2e1f1f5f8?w=400&h=400&fit=crop', 'filename': 'gouda.jpg'},
    {'name': 'Quark', 'url': 'https://images.unsplash.com/photo-1634141510639-d691d86f47be?w=400&h=400&fit=crop', 'filename': 'quark.jpg'},

    # Fleisch & Wurst
    {'name': 'Hähnchenbrust', 'url': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400&h=400&fit=crop', 'filename': 'haehnchen.jpg'},
    {'name': 'Rinderhack', 'url': 'https://images.unsplash.com/photo-1603048297172-c92544798d5b?w=400&h=400&fit=crop', 'filename': 'rinderhack.jpg'},
    {'name': 'Bratwurst', 'url': 'https://images.unsplash.com/photo-1612871689353-cccf581d667b?w=400&h=400&fit=crop', 'filename': 'bratwurst.jpg'},
    {'name': 'Schnitzel', 'url': 'https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=400&h=400&fit=crop', 'filename': 'schnitzel.jpg'},

    # Brot & Backwaren
    {'name': 'Vollkornbrot', 'url': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&h=400&fit=crop', 'filename': 'vollkornbrot.jpg'},
    {'name': 'Brötchen', 'url': 'https://images.unsplash.com/photo-1558963675-94dc9c3a66a9?w=400&h=400&fit=crop', 'filename': 'broetchen.jpg'},
    {'name': 'Milchbrötchen', 'url': 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400&h=400&fit=crop', 'filename': 'milchbroetchen.jpg'},
    {'name': 'Croissants', 'url': 'https://images.unsplash.com/photo-1530610476181-d83430b64dcd?w=400&h=400&fit=crop', 'filename': 'croissants.jpg'},

    # Getränke
    {'name': 'Mineralwasser', 'url': 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=400&h=400&fit=crop', 'filename': 'mineralwasser.jpg'},
    {'name': 'Apfelsaft', 'url': 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=400&h=400&fit=crop', 'filename': 'apfelsaft.jpg'},
    {'name': 'Cola', 'url': 'https://images.unsplash.com/photo-1561758033-48d52648ae8b?w=400&h=400&fit=crop', 'filename': 'cola.jpg'},
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
print("Starting download of REAL product images from Unsplash...")
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
    time.sleep(1)  # Be polite to the server

print("-" * 50)
print(f"Download complete!")
print(f"[OK] Successful: {successful}")
print(f"[FAIL] Failed: {failed}")
print(f"Images saved in: {os.path.abspath(IMAGE_DIR)}")