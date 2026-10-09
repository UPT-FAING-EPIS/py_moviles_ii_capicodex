import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gameon/features/reservas/models/horario_area.dart';
import 'package:gameon/features/reservas/models/reserva.dart';

class ReservaCalendarioViewModel {
  final int areaId;
  bool cargando = false;
  String? error;
  bool guardando = false; // estado para creación de reserva
  List<HorarioArea> horarios = [];
  List<TimeOfDay> slots = [];
  Set<TimeOfDay> slotsOcupados = {}; // Nuevos slots ocupados
  DateTime? selectedDay;
  // Rango seleccionado (inicio y fin exclusivos del fin visualmente, pero endTime representa inicio del último slot seleccionado)
  TimeOfDay? startTime;
  TimeOfDay? endTime; // endTime siempre > startTime cuando hay rango válido

  // Permite variar el tamaño del slot si luego se necesita
  final int intervaloMinutos;

  ReservaCalendarioViewModel({
    required this.areaId,
    this.intervaloMinutos = 30,
  });

  Future<void> cargarHorarios() async {
    cargando = true;
    error = null;
    try {
      developer.log('[ReservasVM] Cargando horarios areaId=$areaId');
      final data = await Supabase.instance.client
          .from('areas_horarios')
          .select()
          .eq('area_deportiva_id', areaId)
          .eq('disponible', 1);
      horarios = (data as List)
          .map((j) => HorarioArea.fromJson(j as Map<String, dynamic>))
          .toList();
      developer.log('[ReservasVM] Horarios cargados: ${horarios.length}');
    } catch (e, st) {
      error = 'Error cargando horarios: $e';
      developer.log(
        '[ReservasVM][ERROR] cargarHorarios $e',
        error: e,
        stackTrace: st,
      );
    } finally {
      cargando = false;
    }
  }

  bool diaDisponible(DateTime day) {
    final nombre = normalizarDia(day);
    return horarios.any(
      (h) => h.disponible && h.dia.toLowerCase() == nombre.toLowerCase(),
    );
  }

  Future<void> seleccionarDiaAsync(DateTime day) async {
    selectedDay = day;
    startTime = null;
    endTime = null;
    _generarSlotsParaDia(day);
    await _marcarReservasExistentes(day);
  }

  void seleccionarDia(DateTime day) {
    selectedDay = day;
    startTime = null;
    endTime = null;
    _generarSlotsParaDia(day);
  }

  void seleccionarHora(TimeOfDay t) {
    // No permitir seleccionar slots ocupados
    if (slotsOcupados.contains(t)) return;

    // Modo de selección de rango:
    // 1) Si no hay startTime => asignar startTime = t
    // 2) Si hay start y no hay end y t > start => end = t (verificando que no haya slots ocupados en el medio)
    // 3) Si hay start y end:
    //    - Si t < start => nuevo inicio = t, limpiar end
    //    - Si t == start => limpiar todo
    //    - Si start < t < end => acortar rango: end = t
    //    - Si t == end => end = null (reduce a solo start)
    //    - Si t > end => mover end = t (verificando que no haya slots ocupados en el medio)
    if (startTime == null) {
      startTime = t;
      endTime = null;
      return;
    }

    final cmpStart = _compareTimes(t, startTime!);
    if (endTime == null) {
      // Solo había inicio
      if (cmpStart == 0) {
        // Tap de nuevo en mismo => limpiar
        startTime = null;
        endTime = null;
      } else if (cmpStart < 0) {
        // Nuevo inicio anterior
        startTime = t;
      } else {
        // t > start => establecer rango solo si no hay slots ocupados en el medio
        if (_haySlotOcupadoEnRango(startTime!, t)) {
          // Si hay slots ocupados, iniciar nuevo rango desde t
          startTime = t;
          endTime = null;
        } else {
          endTime = t;
        }
      }
      return;
    }

    // Hay start y end
    final cmpEnd = _compareTimes(t, endTime!);
    if (cmpStart < 0) {
      // Nuevo inicio antes del actual rango => reset rango
      startTime = t;
      endTime = null;
    } else if (cmpStart == 0) {
      // Tap en inicio => limpiar todo
      startTime = null;
      endTime = null;
    } else if (cmpEnd == 0) {
      // Tap en fin => remover fin
      endTime = null;
    } else if (cmpStart > 0 && cmpEnd < 0) {
      // Dentro del rango => acortar rango hasta t
      endTime = t;
    } else if (cmpEnd < 0) {
      // t entre start y end (handled) else if t < end
      endTime = t; // fallback
    } else if (cmpEnd > 0) {
      // Expandir rango solo si no hay slots ocupados en el medio
      if (_haySlotOcupadoEnRango(endTime!, t)) {
        // Si hay slots ocupados, iniciar nuevo rango desde t
        startTime = t;
        endTime = null;
      } else {
        endTime = t;
      }
    }
  }

  int _compareTimes(TimeOfDay a, TimeOfDay b) => _toMin(a) - _toMin(b);

  // Verificar si un slot está ocupado
  bool isSlotOcupado(TimeOfDay slot) => slotsOcupados.contains(slot);

  // Verificar si hay slots ocupados en el rango entre dos tiempos (exclusivo)
  bool _haySlotOcupadoEnRango(TimeOfDay inicio, TimeOfDay fin) {
    final inicioMin = _toMin(inicio);
    final finMin = _toMin(fin);

    // Asegurar que inicio < fin
    final minTime = inicioMin < finMin ? inicioMin : finMin;
    final maxTime = inicioMin < finMin ? finMin : inicioMin;

    // Buscar slots ocupados en el rango (excluyendo los extremos)
    for (final slot in slotsOcupados) {
      final slotMin = _toMin(slot);
      if (slotMin > minTime && slotMin < maxTime) {
        return true;
      }
    }
    return false;
  }

  // Consideramos válido si:
  // - Hay start y end y end > start (rango explícito) y no hay slots ocupados en el medio OR
  // - Hay solo start (reservar un bloque mínimo = intervaloMinutos)
  bool get tieneRangoValido {
    if (startTime == null) return false;
    if (endTime == null) return true; // un solo bloque
    if (_toMin(endTime!) <= _toMin(startTime!)) return false;
    // Verificar que no haya slots ocupados en el rango seleccionado
    return !_haySlotOcupadoEnRango(startTime!, endTime!);
  }

  int get duracionMinutos {
    if (!tieneRangoValido) return 0;
    if (startTime != null && endTime == null) {
      // Un solo slot seleccionado: duración = intervaloMinutos
      return intervaloMinutos;
    }
    // Rango seleccionado: desde startTime hasta endTime + intervaloMinutos
    return _toMin(endTime!) - _toMin(startTime!) + intervaloMinutos;
  }

  // Obtener la hora final real (incluyendo el intervalo del último slot)
  TimeOfDay get horaFinReal {
    if (endTime != null) {
      return _add(endTime!, intervaloMinutos);
    }
    return _add(startTime!, intervaloMinutos);
  }

  double costoTotal(double tarifaPorHora) {
    if (duracionMinutos == 0) return 0;
    final horas = duracionMinutos / 60.0;
    return horas * tarifaPorHora;
  }

  Future<ReservaInsertResult> crearReserva({
    required String idUsuario,
    String estado = 'Pendiente', // Pendiente, Confirmada, En curso, Completada
    double? montoPagado,
    String? metodoPago,
    DateTime? fechaPago,
    String? paypalOrderId,
  }) async {
    if (!tieneRangoValido || selectedDay == null || guardando) {
      return ReservaInsertResult.error('Selección inválida o en progreso');
    }
    guardando = true;
    try {
      developer.log('[ReservasVM] crearReserva estado=$estado areaId=$areaId');
      final fecha = DateTime(
        selectedDay!.year,
        selectedDay!.month,
        selectedDay!.day,
      ).toIso8601String().split('T').first; // yyyy-MM-dd

      final inicio = startTime!;
      // Usar horaFinReal para obtener el tiempo final correcto
      final finT = horaFinReal;

      String _fmt(TimeOfDay t) =>
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

      final userIdInt = int.tryParse(idUsuario);
      if (userIdInt == null) {
        return ReservaInsertResult.error('ID de usuario inválido');
      }

      final insertPayload = <String, dynamic>{
        'id_usuario': userIdInt,
        'area_deportiva_id': areaId,
        'fecha': fecha,
        'hora_inicio': _fmt(inicio),
        'hora_fin': _fmt(finT),
        'estado': estado,
      };

      if (montoPagado != null) insertPayload['monto_pagado'] = montoPagado;
      if (metodoPago != null) insertPayload['metodo_pago'] = metodoPago;
      if (fechaPago != null) {
        insertPayload['fecha_pago'] = fechaPago.toUtc().toIso8601String();
      }
      if (paypalOrderId != null)
        insertPayload['paypal_order_id'] = paypalOrderId;
      final client = Supabase.instance.client;
      developer.log('[ReservasVM] Insert reservas payload=$insertPayload');
      final resp = await client
          .from('reservas')
          .insert(insertPayload)
          .select()
          .maybeSingle();
      if (resp == null) {
        developer.log('[ReservasVM][WARN] Insert retornó null');
        return ReservaInsertResult.error('No se pudo crear la reserva');
      }
      final idGenerado = resp['id'] as int?;
      developer.log(
        '[ReservasVM] Reserva creada id=$idGenerado estado=$estado',
      );

      // Insertar notificación en Firestore solo si está Confirmada
      if (estado.toLowerCase() == 'confirmada' && idGenerado != null) {
        try {
          await FirebaseFirestore.instance.collection('notificaciones').add({
            'usuario_id': userIdInt,
            'titulo': 'Reserva confirmada',
            'mensaje': 'Tu reserva #$idGenerado ha sido confirmada',
            'tipo': 'reserva',
            'referencia_id': idGenerado,
            'fecha': FieldValue.serverTimestamp(),
            'leido': false,
          });
          developer.log(
            '[ReservasVM] Notificación creada en Firestore para usuario $userIdInt, reservaId=$idGenerado',
          );
        } catch (e, st) {
          developer.log(
            '[ReservasVM][WARN] Error insertando notificación en Firestore: $e',
            error: e,
            stackTrace: st,
          );
        }
      }

      return ReservaInsertResult.success(id: idGenerado);
    } on PostgrestException catch (e, st) {
      developer.log(
        '[ReservasVM][ERROR] Postgrest crearReserva code=${e.code} message=${e.message}',
        error: e,
        stackTrace: st,
      );
      return ReservaInsertResult.error(e.message);
    } catch (e, st) {
      developer.log(
        '[ReservasVM][ERROR] crearReserva generico $e',
        error: e,
        stackTrace: st,
      );
      return ReservaInsertResult.error('Error inesperado');
    } finally {
      guardando = false;
    }
  }

  void _generarSlotsParaDia(DateTime day) {
    slots = [];
    final nombre = normalizarDia(day);
    final horario = horarios.firstWhere(
      (h) => h.dia.toLowerCase() == nombre.toLowerCase(),
      orElse: () => HorarioArea(
        id: -1,
        areaDeportivaId: areaId,
        dia: nombre,
        horaApertura: '00:00:00',
        horaCierre: '00:00:00',
        disponible: false,
      ),
    );
    if (!horario.disponible || horario.id == -1) return;
    final inicio = _parse(horario.horaApertura);
    final fin = _parse(horario.horaCierre);
    var cursor = inicio;
    while (_toMin(cursor) < _toMin(fin)) {
      slots.add(cursor);
      cursor = _add(cursor, intervaloMinutos); // ahora 30m por defecto
    }
  }

  Future<void> _marcarReservasExistentes(DateTime day) async {
    slotsOcupados.clear();
    try {
      final fechaIso = DateTime(
        day.year,
        day.month,
        day.day,
      ).toIso8601String().split('T').first;
      final data = await Supabase.instance.client
          .from('reservas')
          .select()
          .eq('area_deportiva_id', areaId)
          .eq('fecha', fechaIso)
          .neq('estado', 'cancelada');
      final reservas = (data as List)
          .map((j) => Reserva.fromJson(j as Map<String, dynamic>))
          .toList();

      // Marcar slots ocupados en lugar de eliminarlos
      for (final slot in slots) {
        final sMin = _toMin(slot);
        final ocupado = reservas.any(
          (r) => sMin >= r.inicioMin && sMin < r.finMin,
        );
        if (ocupado) {
          slotsOcupados.add(slot);
        }
      }

      developer.log(
        '[ReservasVM] Marcado reservas existentes fecha=$fechaIso reservadas=${reservas.length} slotsOcupados=${slotsOcupados.length} totalSlots=${slots.length}',
      );
    } catch (e, st) {
      developer.log(
        '[ReservasVM][ERROR] _marcarReservasExistentes $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  TimeOfDay _parse(String t) {
    final p = t.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  int _toMin(TimeOfDay t) => t.hour * 60 + t.minute;
  TimeOfDay _add(TimeOfDay t, int m) {
    final total = _toMin(t) + m;
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }
}

class ReservaInsertResult {
  final bool ok;
  final String? message;
  final int? id;
  ReservaInsertResult._(this.ok, this.message, this.id);
  factory ReservaInsertResult.success({int? id}) =>
      ReservaInsertResult._(true, null, id);
  factory ReservaInsertResult.error(String msg) =>
      ReservaInsertResult._(false, msg, null);
}
