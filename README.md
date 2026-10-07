# venexpress_driver

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Versión web en Render

La app también se publica como sitio web estático en Render (plan
gratis), definido en el `render.yaml` del repositorio `venexpress`. Render
ejecuta `./render-build.sh`, que instala Flutter y compila con
`API_BASE_URL` (la URL del backend + `/api`). Guía completa:
`docs/DESPLIEGUE_RENDER.md` en el repositorio `venexpress`.

Para probar el build web en local:

```
API_BASE_URL=https://<backend>/api ./render-build.sh
```
