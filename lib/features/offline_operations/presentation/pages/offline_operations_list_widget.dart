import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/presentation/providers/offline_operations_provider.dart';

class OfflineOperationsListPage extends StatefulWidget {
  final String title;
  final List<OfflineOperation> operations;
  final bool isRouteGroup;

  const OfflineOperationsListPage({
    required this.title,
    required this.operations,
    this.isRouteGroup = false,
    Key? key,
  }) : super(key: key);

  @override
  State<OfflineOperationsListPage> createState() =>
      _OfflineOperationsListPageState();
}

class _OfflineOperationsListPageState extends State<OfflineOperationsListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Consumer<OfflineOperationsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && widget.operations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Actualizando operaciones...'),
              ],
            ),
          );
        }

        // Usar las operaciones actualizadas del provider si están disponibles
        final operations = widget.isRouteGroup
            ? provider.groupedRouteOperations[
                    widget.operations.first.offlineRouteId ?? ''] ??
                []
            : widget.operations;

        if (operations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.green[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay operaciones pendientes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Todas las operaciones de ${widget.title.toLowerCase()} se han sincronizado',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadOperations(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: operations.length,
            itemBuilder: (context, index) => _buildOperationItem(
              context,
              operations[index],
              provider,
            ),
          ),
        );
      },
    );
  }

  Widget _buildOperationItem(
    BuildContext context,
    OfflineOperation operation,
    OfflineOperationsProvider provider,
  ) {
    final isSynced = operation.data['synced'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSynced
                        ? Colors.green[50]
                        : _getOperationColor(operation.type).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getOperationIcon(operation.type),
                    color: isSynced
                        ? Colors.green
                        : _getOperationColor(operation.type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        operation.type.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(operation.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isSynced) ...[
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 22),
                    onPressed: () => _handleRetry(context, operation, provider),
                    tooltip: 'Reintentar envío',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green[50],
                      foregroundColor: Colors.green[700],
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 22),
                  onPressed: () => _showOperationDetails(context, operation),
                  tooltip: 'Ver detalles',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue[700],
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.repeat,
                    'Intentos',
                    operation.retryCount.toString(),
                    valueColor: Colors.orange[700],
                  ),
                  if (operation.lastError != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.error_outline,
                      'Último Error',
                      operation.lastError!,
                      valueColor: Colors.red[700],
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getOperationIcon(OfflineOperationType type) {
    switch (type) {
      case OfflineOperationType.routeCreation:
        return Icons.route;
      case OfflineOperationType.routePositions:
        return Icons.location_on;
      case OfflineOperationType.routeFinish:
        return Icons.flag;
      case OfflineOperationType.maintenance:
        return Icons.build;
      case OfflineOperationType.inspection:
        return Icons.assignment;
      case OfflineOperationType.routeSos:
        return Icons.warning;
      case OfflineOperationType.emergencyCall:
        return Icons.phone;
      case OfflineOperationType.incidentReport:
        return Icons.report;
      case OfflineOperationType.routeStop:
        return Icons.stop;
      case OfflineOperationType.routeCancel:
        return Icons.cancel;
      default:
        return Icons.warning;
    }
  }

  Color _getOperationColor(OfflineOperationType type) {
    switch (type) {
      case OfflineOperationType.routeCreation:
        return Colors.blue;
      case OfflineOperationType.routePositions:
        return Colors.green;
      case OfflineOperationType.routeFinish:
        return Colors.orange;
      case OfflineOperationType.maintenance:
        return Colors.teal;
      case OfflineOperationType.inspection:
        return Colors.indigo;
      case OfflineOperationType.routeSos:
        return Colors.red;
      case OfflineOperationType.emergencyCall:
        return Colors.purple;
      case OfflineOperationType.incidentReport:
        return Colors.redAccent;
      case OfflineOperationType.routeStop:
        return Colors.blueGrey;
      case OfflineOperationType.routeCancel:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.w400,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _handleRetry(
    BuildContext context,
    OfflineOperation operation,
    OfflineOperationsProvider provider,
  ) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Reintentando operación...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Determinar qué método de reintento usar basado en el tipo
      await _performRetry(operation, provider);

      // Cerrar indicador de carga
      Navigator.of(context).pop();

      // Mostrar diálogo de éxito
      _showSuccessDialog(context);
    } catch (e) {
      // Cerrar indicador de carga
      Navigator.of(context).pop();

      // Mostrar diálogo de error
      _showErrorDialog(context, e.toString());
    }
  }

  Future<void> _performRetry(
      OfflineOperation operation, OfflineOperationsProvider provider) async {
    switch (operation.type) {
      case OfflineOperationType.maintenance:
        await provider.retryMaintenance(operation.id);
        break;
      // case OfflineOperationType.inspection:
      //   await provider.retryInspection(operation.id);
      //   break;
      // case OfflineOperationType.incidentReport:
      //   await provider.retryIncidentReport(operation.id);
      //   break;
      default:
        throw Exception('Tipo de operación no soportado para reintento');
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: Icon(
          Icons.check_circle,
          color: Colors.green[600],
          size: 48,
        ),
        title: const Text('¡Éxito!'),
        content: const Text(
            'La operación se completó correctamente y fue sincronizada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: Icon(
          Icons.error,
          color: Colors.red[600],
          size: 48,
        ),
        title: const Text('Error al reintentar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'No se pudo completar la operación. Se ha incrementado el contador de reintentos.'),
            const SizedBox(height: 8),
            Text(
              'Error: $error',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  String _getOperationTitle(OfflineOperationType type) {
    switch (type) {
      case OfflineOperationType.maintenance:
        return 'Mantenimiento';
      case OfflineOperationType.inspection:
        return 'Inspección';
      case OfflineOperationType.incidentReport:
        return 'Reporte de incidente';
      default:
        return 'Operación';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  void _showOperationDetails(BuildContext context, OfflineOperation operation) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Detalles de ${_getOperationTitle(operation.type)}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Tipo', _getOperationTitle(operation.type)),
                _buildDetailRow('Fecha', _formatDate(operation.createdAt)),
                _buildDetailRow('Intentos', operation.retryCount.toString()),
                if (operation.lastError != null)
                  _buildDetailRow('Último Error', operation.lastError!),
                const SizedBox(height: 16),
                const Text(
                  'Datos:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(operation.data),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
