# Definition of Done · GameOn Network

Una historia o incremento se considera terminado únicamente cuando cumple todos los criterios aplicables.

| # | Criterio | Cómo se verifica |
|---:|---|---|
| 1 | El proyecto compila en modo debug | `flutter build apk --debug` en CI |
| 2 | El análisis estático no presenta errores | `flutter analyze` |
| 3 | Las pruebas unitarias están en verde | `flutter test` |
| 4 | Cobertura de la capa de dominio de la funcionalidad vertical ≥ 70 % | `flutter test --coverage` + validación de `coverage/lcov.info` |
| 5 | Los cuatro estados de interfaz están implementados cuando corresponda | Revisión del código y demostración: Loading, Success, Empty y Error con reintento |
| 6 | No existen secretos versionados | Trivy secret scanner en CI |
| 7 | DTO y entidad de dominio permanecen separados | Revisión de `data/models`, `domain/entities` y mapper |
| 8 | El dominio no importa `data` ni `presentation` | Script de arquitectura en CI |
| 9 | Las dependencias externas se inyectan | Revisión del constructor de ViewModels/repositorios y composition root |
| 10 | El código sigue formato y convenciones | `dart format --output=none --set-exit-if-changed lib test` |
| 11 | El cambio entra mediante Pull Request revisado por otra persona | Branch protection + aprobación obligatoria |
| 12 | Documentación y evidencia del incremento están actualizadas | Revisión de `docs/`, URLs y evidencias antes del merge |
