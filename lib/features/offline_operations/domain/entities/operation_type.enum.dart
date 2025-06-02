enum OfflineOperationType {
  routeRecovery,
  maintenance,
  inspection,
  incidentReport;

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
    }
  }
}
