class Reserva {
  final int id;
  final int idUsuario;
  final int areaDeportivaId;
  final DateTime fecha; // solo fecha (00:00)
  final String horaInicio; // HH:mm:ss
  final String horaFin; // HH:mm:ss
  final String estado;
  final DateTime creadoEn;
  final String? culqiChargeId;
  final String? culqiOrderId;
  final double? montoPagado;
  final String? metodoPago;
  final String? paypalPaymentId;
  final String? paypalPayerId;

  Reserva({
    required this.id,
    required this.idUsuario,
    required this.areaDeportivaId,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.estado,
    required this.creadoEn,
    this.culqiChargeId,
    this.culqiOrderId,
    this.montoPagado,
    this.metodoPago,
    this.paypalPaymentId,
    this.paypalPayerId,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) => Reserva(
    id: json['id'] as int,
    idUsuario: json['id_usuario'] as int,
    areaDeportivaId: json['area_deportiva_id'] as int,
    fecha: DateTime.parse(json['fecha'] as String),
    horaInicio: json['hora_inicio'] as String,
    horaFin: json['hora_fin'] as String,
    estado: json['estado'] as String,
    creadoEn: DateTime.parse(json['creado_en'] as String),
    culqiChargeId: json['culqi_charge_id'] as String?,
    culqiOrderId: json['culqi_order_id'] as String?,
    montoPagado: json['monto_pagado'] == null
        ? null
        : (json['monto_pagado'] as num).toDouble(),
    metodoPago: json['metodo_pago'] as String?,
    paypalPaymentId: json['paypal_payment_id'] as String?,
    paypalPayerId: json['paypal_payer_id'] as String?,
  );

  int get inicioMin => _timeStrToMin(horaInicio);
  int get finMin => _timeStrToMin(horaFin);
}

int _timeStrToMin(String t) {
  final p = t.split(':');
  final hh = int.parse(p[0]);
  final mm = int.parse(p[1]);
  return hh * 60 + mm;
}
