enum OfflineOperationType {
  routeCreation, // Creación de ruta fallida
  routePositions, // Posiciones de ruta fallidas
  routeFinish, // Finalización de ruta fallida
  routeCancel, // Cancelación de ruta fallida
  routeSos, // SOS de ruta fallido
  maintenance, // Mantenimientos
  inspection, // Inspecciones
  incidentReport, // Reportes de incidente
  routeRecovery, // Recuperación de ruta
  emergencyCall; // Llamada de emergencia

  String get displayName {
    switch (this) {
      case OfflineOperationType.routeCreation:
        return 'Creación de ruta';
      case OfflineOperationType.routePositions:
        return 'Posiciones de ruta';
      case OfflineOperationType.routeFinish:
        return 'Finalización de ruta';
      case OfflineOperationType.routeRecovery:
        return 'Recuperación de ruta';
      case OfflineOperationType.maintenance:
        return 'Mantenimiento';
      case OfflineOperationType.inspection:
        return 'Inspección';
      case OfflineOperationType.routeSos:
        return 'Alerta SOS';
      case OfflineOperationType.emergencyCall:
        return 'Llamada de emergencia';
      case OfflineOperationType.routeCancel:
        return 'Cancelación de ruta';
      case OfflineOperationType.incidentReport:
        return 'Reporte de incidente';
      default:
        return 'Operación desconocida';
    }
  }
}
