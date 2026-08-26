# Paniko Shop

Sitio web estático listo para GitHub Pages. `index.html` y `assets/` deben permanecer en la raíz del repositorio.

## Publicar

1. Sube el contenido completo a un repositorio de GitHub en la rama `main`.
2. En `Settings > Pages`, selecciona `GitHub Actions` como fuente.
3. Cada push a `main` publicará el sitio mediante `.github/workflows/pages.yml`.

El archivo `.nojekyll` evita que Jekyll intente procesar los recursos estáticos. Las rutas del sitio son relativas, por lo que funcionan tanto en un repositorio de proyecto como en un dominio personalizado.

## Normalizar nombres de imágenes

Para evitar problemas de mayúsculas, acentos, espacios y caracteres especiales en GitHub, abre PowerShell en esta carpeta y ejecuta:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\prepare-github-pages.ps1
```

El script renombra las carpetas a estos nombres:

- `assets/accesorios-de-fieltro-20260825t020827z-1-001/`
- `assets/llaveros-acrilicos-catalogo/`
- `assets/llaveros-hama-beads/`
- `assets/llaveros-personalizados/`
- `assets/pinturas-originales/`
- `assets/prints/`
- `assets/separadores/`
- `assets/stickers-png/`
- `assets/stickers-portada/`

También renombra automáticamente cada imagen, actualiza sus rutas en `index.html` y muestra en consola el nombre final de cada archivo. Haz una copia del proyecto antes de ejecutarlo, porque cambiará los nombres en tu computadora.
