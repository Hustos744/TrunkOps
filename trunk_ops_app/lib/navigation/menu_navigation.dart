// lib/navigation/menu_navigation.dart
import 'package:flutter/material.dart';

const dashboardRoute = '/dashboard';
const coverageRoute = '/coverage';
const unitsRoute = '/units';
const assetsRoute = '/assets';
const maintenanceRoute = '/maintenance';
const auditRoute = '/audit-log';
const settingsRoute = '/settings';
const scenariosRoute = '/scenarios';
// const logoutRoute = '/logout'; // Logout зробимо дією, не сторінкою

void handleMenuTap(BuildContext context, int index) {
  final current = ModalRoute.of(context)?.settings.name;

  String? targetRoute;

  switch (index) {
    case 0:
      targetRoute = dashboardRoute;
      break;
    case 1:
      targetRoute = coverageRoute;
      break;
    case 2:
      targetRoute = unitsRoute;
      break;
    case 3:
      targetRoute = assetsRoute;
      break;
    case 4:
      targetRoute = maintenanceRoute;
      break;
    case 5:
      targetRoute = scenariosRoute;
      break;
    case 6:
      targetRoute = settingsRoute;
      break;
    case 7:
      // якщо це має бути «Сповіщення», краще зробити окремий notificationsRoute
      targetRoute = auditRoute;
      break;
    case 8:
      // TODO: логіка виходу (очистка токена + перехід на LoginScreen)
      return;
  }

  if (targetRoute != null && targetRoute != current) {
    Navigator.pushReplacementNamed(context, targetRoute);
  }
}
