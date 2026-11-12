# US-25 · Actualizar el estado de una reserva

Historia: https://github.com/UPT-FAING-EPIS/py_moviles_ii_capicodex/issues/25

## Alcance de esta evidencia

Este registro simula la trazabilidad de la actividad en `main`. La funcionalidad
operativa se mantiene fuera de esta rama y no se modifica con este cambio.

## Flujo simulado

1. El administrador selecciona una reserva bajo su gestión.
2. La aplicación muestra únicamente las transiciones de estado permitidas.
3. El administrador confirma el nuevo estado.
4. El sistema registra el cambio asociado al administrador que lo realizó.
5. La reserva actualizada se refleja en la consulta del gestor.

## Criterio representado

Solo se permiten transiciones válidas y cada cambio queda asociado al
administrador responsable. Esta evidencia no despliega código ni altera datos,
permisos o ramas operativas.
