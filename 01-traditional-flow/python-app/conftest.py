# conftest.py — configuración global de pytest para la Python_App
#
# Este archivo es reconocido automáticamente por pytest al iniciar.
# Su función aquí es agregar la carpeta `src/` al sys.path de Python,
# lo que permite que los tests en `test/` importen módulos de `src/`
# con un simple `from app import app` sin necesidad de manipular
# sys.path dentro de cada archivo de test.

import sys
import os

# Agrega la carpeta src/ al path de búsqueda de módulos de Python
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))
