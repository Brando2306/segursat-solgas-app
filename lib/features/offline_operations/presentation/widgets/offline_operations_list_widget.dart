import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/presentation/providers/offline_operations_provider.dart';
import 'package:safe_driving_app/utils/snackbars.dart';

class OfflineOperationsListPage extends StatefulWidget {
  final String title;
  final List<OfflineOperation> operations;

  const OfflineOperationsListPage({
    required this.title,
    required this.operations,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<OfflineOperationsProvider>().loadOperations(),
            tooltip: 'Actualizar',
          ),
        ],
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

        // Obtener la lista actualizada del provider basada en el tipo
        final updatedOperations = _getUpdatedOperations(provider);

        if (updatedOperations.isEmpty) {
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
            itemCount: updatedOperations.length,
            itemBuilder: (context, index) => _buildOperationItem(
              context,
              updatedOperations[index],
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
                Expanded(
                  child: Text(
                    _getOperationTitle(operation.type),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 22),
                      onPressed: () =>
                          _handleRetry(context, operation, provider),
                      tooltip: 'Reintentar envío',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green[50],
                        foregroundColor: Colors.green[700],
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 22),
                      onPressed: () => _showDeleteConfirmation(
                          context, operation.id, provider),
                      tooltip: 'Eliminar operación',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red[700],
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
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
                    Icons.access_time,
                    'Creado',
                    _formatDate(operation.createdAt),
                  ),
                  const SizedBox(height: 8),
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
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _showOperationDetails(context, operation),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ver detalles',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      case OfflineOperationType.routeRecovery:
        await provider.retryRouteCreation(context, operation.id);
        break;
      case OfflineOperationType.maintenance:
        await provider.retryMaintenance(context, operation.id);
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
      case OfflineOperationType.routeRecovery:
        return 'Recuperación de ruta';
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

  void _showDeleteConfirmation(
    BuildContext context,
    String id,
    OfflineOperationsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar esta operación pendiente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.removeOperation(id);
                Snackbars.showSnackbarSuccess(
                    'Operación eliminada correctamente');
              } catch (e) {
                Snackbars.showSnackbarError('Error al eliminar: $e');
              }
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _prettyPrintJson(Map<String, dynamic> json) {
    final encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }

  List<OfflineOperation> _getUpdatedOperations(
      OfflineOperationsProvider provider) {
    // Retornar la lista actualizada basada en el título
    switch (widget.title) {
      case 'Recuperaciones de Ruta':
        return provider.routeRecoveryOperations;
      case 'Mantenimientos':
        return provider.maintenanceOperations;
      case 'Posiciones de Ruta':
        return provider.routePositionsOperations;
      case 'Inspecciones':
        return provider.inspectionOperations;
      default:
        return widget.operations;
    }
  }
}
