import 'package:flutter/material.dart';

class CategoriaData {
  final int id;
  final String nombre;
  final IconData icono;
  final String grupo;

  const CategoriaData(this.id, this.nombre, this.icono, this.grupo);
}

final List<CategoriaData> ingresoCategorias = [
  CategoriaData(1, 'Salario', Icons.work_outlined, 'Laboral'),
  CategoriaData(2, 'Horas extras', Icons.access_time_outlined, 'Laboral'),
  CategoriaData(3, 'Bonificaciones', Icons.redeem_outlined, 'Laboral'),
  CategoriaData(4, 'Comisiones', Icons.trending_up_outlined, 'Laboral'),
  CategoriaData(5, 'Aguinaldo', Icons.card_giftcard_outlined, 'Laboral'),
  CategoriaData(6, 'Vacaciones pagadas', Icons.beach_access_outlined, 'Laboral'),
  CategoriaData(7, 'Propinas', Icons.volunteer_activism_outlined, 'Laboral'),
  CategoriaData(8, 'Pensión', Icons.account_balance_outlined, 'Beneficios'),
  CategoriaData(9, 'Jubilación', Icons.elderly_outlined, 'Beneficios'),
  CategoriaData(10, 'Beca', Icons.school_outlined, 'Beneficios'),
  CategoriaData(11, 'Freelance', Icons.laptop_outlined, 'Independiente'),
  CategoriaData(12, 'Venta de productos', Icons.shopping_bag_outlined, 'Independiente'),
  CategoriaData(13, 'Venta de bienes', Icons.sell_outlined, 'Independiente'),
  CategoriaData(14, 'Negocio propio', Icons.store_outlined, 'Independiente'),
  CategoriaData(15, 'Inversiones', Icons.show_chart_outlined, 'Inversiones'),
  CategoriaData(16, 'Dividendos', Icons.monetization_on_outlined, 'Inversiones'),
  CategoriaData(17, 'Intereses bancarios', Icons.percent_outlined, 'Inversiones'),
  CategoriaData(18, 'Alquiler recibido', Icons.home_outlined, 'Extra'),
  CategoriaData(19, 'Reembolsos', Icons.refresh_outlined, 'Extra'),
  CategoriaData(20, 'Regalos recibidos', Icons.mood_outlined, 'Extra'),
  CategoriaData(21, 'Premios', Icons.emoji_events_outlined, 'Extra'),
  CategoriaData(22, 'Lotería', Icons.casino_outlined, 'Extra'),
  CategoriaData(23, 'Devolución de impuestos', Icons.request_quote_outlined, 'Extra'),
  CategoriaData(24, 'Cashback', Icons.currency_exchange_outlined, 'Extra'),
  CategoriaData(25, 'Reembolso de gastos', Icons.receipt_long_outlined, 'Extra'),
  CategoriaData(26, 'Otros ingresos', Icons.more_horiz_outlined, 'Otros'),
];

final List<CategoriaData> gastoCategorias = [
  CategoriaData(27, 'Vivienda', Icons.home_outlined, 'Hogar'),
  CategoriaData(28, 'Servicios básicos', Icons.build_outlined, 'Hogar'),
  CategoriaData(29, 'Alimentación', Icons.restaurant_outlined, 'Alimentación'),
  CategoriaData(30, 'Transporte', Icons.directions_car_outlined, 'Transporte'),
  CategoriaData(31, 'Salud', Icons.medical_services_outlined, 'Salud'),
  CategoriaData(32, 'Cuidado personal', Icons.self_improvement_outlined, 'Salud'),
  CategoriaData(33, 'Educación', Icons.school_outlined, 'Educación'),
  CategoriaData(34, 'Ropa', Icons.checkroom_outlined, 'Estilo de vida'),
  CategoriaData(35, 'Entretenimiento', Icons.movie_outlined, 'Estilo de vida'),
  CategoriaData(36, 'Tecnología', Icons.laptop_outlined, 'Estilo de vida'),
  CategoriaData(37, 'Finanzas', Icons.account_balance_outlined, 'Finanzas'),
  CategoriaData(38, 'Mascotas', Icons.pets_outlined, 'Personal'),
  CategoriaData(39, 'Familia', Icons.people_outlined, 'Personal'),
  CategoriaData(40, 'Trabajo', Icons.business_center_outlined, 'Personal'),
  CategoriaData(41, 'Otros gastos', Icons.more_horiz_outlined, 'Otros'),
];

CategoriaData? findCategoriaById(int id) {
  return ingresoCategorias.where((c) => c.id == id).firstOrNull ??
      gastoCategorias.where((c) => c.id == id).firstOrNull;
}

List<CategoriaData> getCategoriasByTipo(int idTipo) {
  return idTipo == 1 ? ingresoCategorias : gastoCategorias;
}

List<String> getGruposByTipo(int idTipo) {
  final cats = getCategoriasByTipo(idTipo);
  final grupos = cats.map((c) => c.grupo).toSet().toList();
  return grupos;
}

List<CategoriaData> getCategoriasByGrupo(int idTipo, String grupo) {
  return getCategoriasByTipo(idTipo).where((c) => c.grupo == grupo).toList();
}
