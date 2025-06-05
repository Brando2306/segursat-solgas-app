enum OfflineOperationType {
  routeRecovery,
  maintenance,
  inspection,
  incidentReport,
  routeCreation,
  routePositions,
  routeEvent;

  String get displayName {
    switch (this) {
      case OfflineOperationType.routeRecovery:
        return 'Recuperación de Ruta';
      case OfflineOperationType.maintenance:
        return 'Mantenimiento';
      case OfflineOperationType.inspection:
        return 'Inspección';
      case OfflineOperationType.incidentReport:
        return 'Reporte de Incidente';
      case OfflineOperationType.routeCreation:
        return 'Creación de Ruta';
      case OfflineOperationType.routePositions:
        return 'Posiciones de Ruta';
      case OfflineOperationType.routeEvent:
        return 'Evento de Ruta';
      default:
        return 'Operación Desconocida';
    }
  }
}
