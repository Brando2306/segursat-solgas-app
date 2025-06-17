// features/offline_operations/domain/entities/operation_type.enum.dart
enum OfflineOperationType {
  routeCreation, // Creación de ruta fallida
  routePositions, // Posiciones de ruta fallidas
  routeFinish, // Finalización de ruta fallida
  routeCancel, // Cancelación de ruta fallida
  routeSos, // SOS de ruta fallido
  maintenance, // Mantenimientos
  inspection, // Inspecciones
  incidentReport, // Reportes de incidente
  routeRecovery; // Recuperación de ruta

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
      case OfflineOperationType.routeFinish:
        return 'Finalización de Ruta';
      case OfflineOperationType.routeCancel:
        return 'Cancelación de Ruta';
      case OfflineOperationType.routeSos:
        return 'Emergencia SOS';
      default:
        return 'Operación Desconocida';
    }
  }
}
