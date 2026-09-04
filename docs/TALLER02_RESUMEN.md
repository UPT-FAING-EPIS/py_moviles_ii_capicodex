# Taller 02 · GameOn Network

Este paquete adapta GameOn Network a los requisitos del Taller 02 de SI-988. El alcance móvil trabajado por el equipo es Android.

## Funcionalidad vertical

Visualizar instalaciones deportivas.

## Archivos principales

- `docs/decisiones/evaluacion_stacks.csv`
- `docs/decisiones/ADR-001-arquitectura.md`
- `docs/decisiones/ADR-002-stack.md`
- `docs/equipo/DEFINITION_OF_DONE.md`
- `docs/arquitectura/arquitectura.md`
- `.github/workflows/ci.yml`
- `test/features/home/viewmodels/home_viewmodel_test.dart`

## Refactor realizado

La consulta a Supabase se retiró del `HomeViewModel` y se trasladó a la capa `data`. La presentación depende ahora del contrato de dominio `InstitucionesRepository`. Se separaron DTO, entidad y mapper y se añadieron cuatro estados de interfaz.

## Evidencia

Consultar `docs/evidencias/S02/README_EVIDENCIAS.md` para obtener las capturas y salidas reales que faltan antes de entregar.
