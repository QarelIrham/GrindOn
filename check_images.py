import os

items = [
    'lib/assets/Head/head_red_bob.png',
    'lib/assets/Head/head_spartan.png',
    'lib/assets/Body1Set/skin_glitch.png',
    'lib/assets/Body1Set/body_set_fire_girl.png'
]

for item in items:
    exists = os.path.exists(item)
    print(f"{item} exists: {exists}")
