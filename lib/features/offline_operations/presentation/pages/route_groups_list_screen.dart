import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:safe_driving_app/core/constants/storage_keys.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/presentation/providers/offline_operations_provider.dart';
import 'package:safe_driving_app/utils/snackbars.dart';

class RouteGroupsListPage extends StatelessWidget {
  const RouteGroupsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Rutas Pendientes'),
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
      body: Consumer<OfflineOperationsProvider>(
        builder: (context, provider, _) {
          final routeGroups = provider.groupedRouteOperations;

          if (provider.isLoading && routeGroups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (routeGroups.isEmpty) {
            return const Center(
              child: Text('No hay grupos de rutas pendientes'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routeGroups.length,
            itemBuilder: (context, index) {
              final entry = routeGroups.entries.elementAt(index);
              return _RouteGroupCard(
                groupId: entry.key,
                operations: entry.value,
              );
            },
          );
        },
      ),
    );
  }
}

class _RouteGroupCard extends StatelessWidget {
  final String groupId;
  final List<OfflineOperation> operations;

  const _RouteGroupCard({
    required this.groupId,
    required this.operations,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OfflineOperationsProvider>();
    final creationOp = operations.firstWhere(
      (op) => op.type == OfflineOperationType.routeCreation,
    );

    // Obtener todas las posiciones agrupadas
    final positionOp = operations.firstWhere(
      (op) => op.type == OfflineOperationType.routePositions,
      orElse: () => OfflineOperation(
        type: OfflineOperationType.routePositions,
        data: {'positions': []},
        offlineRouteId: groupId,
      ),
    );

    final pendingPositions = (positionOp.data['positions'] as List).length;
    final isPositionsSynced = positionOp.data['synced'] == true;

    final hasSOS =
        operations.any((op) => op.type == OfflineOperationType.routeSos);
    final hasEmergency =
        operations.any((op) => op.type == OfflineOperationType.emergencyCall);
    final hasIncidents = operations
        .where((op) => op.type == OfflineOperationType.incidentReport)
        .length;
    final hasStops = operations
        .where((op) => op.type == OfflineOperationType.routeStop)
        .length;
    final isFinished =
        operations.any((op) => op.type == OfflineOperationType.routeFinish);
    final isCancelled =
        operations.any((op) => op.type == OfflineOperationType.routeCancel);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ruta iniciada: ${_formatGroupDate(creationOp.offlineRouteId ?? "")}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildOperationItem(
              context,
              creationOp,
              'Creación de ruta',
              Icons.route,
              Colors.blue,
              onRetry: () => provider.retryOperationById(creationOp.id),
            ),
            if (pendingPositions > 0)
              _buildOperationItem(
                context,
                positionOp,
                '$pendingPositions posiciones',
                Icons.location_on,
                Colors.green,
                onRetry: () => provider.retryRoutePositions(positionOp.id),
              ),
            if (hasSOS)
              _buildOperationItem(
                context,
                operations.firstWhere(
                    (op) => op.type == OfflineOperationType.routeSos),
                'Alerta SOS',
                Icons.warning,
                Colors.red,
                onRetry: () => provider.retryOperationById(operations
                    .firstWhere(
                        (op) => op.type == OfflineOperationType.routeSos)
                    .id),
              ),
            if (hasEmergency)
              _buildOperationItem(
                context,
                operations.firstWhere(
                    (op) => op.type == OfflineOperationType.emergencyCall),
                'Llamada de emergencia',
                Icons.phone,
                Colors.purple,
                onRetry: () => provider.retryOperationById(operations
                    .firstWhere(
                        (op) => op.type == OfflineOperationType.emergencyCall)
                    .id),
              ),
            if (hasIncidents > 0)
              for (final incidentOp in operations.where(
                  (op) => op.type == OfflineOperationType.incidentReport))
                _buildOperationItem(
                  context,
                  incidentOp,
                  'Reporte de incidente',
                  Icons.report,
                  Colors.redAccent,
                  onRetry: () => provider.retryOperationById(incidentOp.id),
                ),
            if (hasStops > 0)
              for (final stopOp in operations
                  .where((op) => op.type == OfflineOperationType.routeStop))
                _buildOperationItem(
                  context,
                  stopOp,
                  'Parada de ruta',
                  Icons.stop,
                  Colors.blueGrey,
                  onRetry: () => provider.retryOperationById(stopOp.id),
                ),
            if (isFinished)
              _buildOperationItem(
                context,
                operations.firstWhere(
                    (op) => op.type == OfflineOperationType.routeFinish),
                'Finalización de ruta',
                Icons.flag,
                Colors.orange,
                onRetry: () => provider.retryOperationById(operations
                    .firstWhere(
                        (op) => op.type == OfflineOperationType.routeFinish)
                    .id),
              ),
            if (isCancelled)
              _buildOperationItem(
                context,
                operations.firstWhere(
                    (op) => op.type == OfflineOperationType.routeCancel),
                'Cancelación de ruta',
                Icons.cancel,
                Colors.orange,
                onRetry: () => provider.retryOperationById(operations
                    .firstWhere(
                        (op) => op.type == OfflineOperationType.routeCancel)
                    .id),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showDetails(context),
                child: const Text('Ver detalles completos'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationItem(
    BuildContext context,
    OfflineOperation operation,
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onRetry,
  }) {
    final isSynced = operation.data['synced'] == true;

    return GestureDetector(
      onTap: () => _showOperationDetails(context, operation),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSynced ? Colors.green[50] : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSynced ? Colors.green : color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSynced
                        ? 'Sincronizado'
                        : '${operation.retryCount} ${operation.retryCount == 1 ? 'intento' : 'intentos'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSynced ? Colors.green : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (!isSynced && onRetry != null)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: onRetry,
                tooltip: 'Reintentar',
                color: color,
              ),
          ],
        ),
      ),
    );
  }

  void _showOperationDetails(BuildContext context, OfflineOperation operation) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Detalles de ${operation.type.displayName}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Tipo', operation.type.displayName),
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

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
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

  String _formatGroupDate(String offlineId) {
    final timestamp = int.tryParse(
            offlineId.replaceAll(StorageKeys.offlineRoutePrefix, '')) ??
        0;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  void _showDetails(BuildContext context) {
    // Navegar a una pantalla de detalles específica para este grupo
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _RouteGroupDetailsPage(
          groupId: groupId,
          operations: operations,
        ),
      ),
    );
  }

  Future<void> _retrySingleOperation(BuildContext context, String id) async {
    final provider = context.read<OfflineOperationsProvider>();
    try {
      await provider.retryOperationById(id);
      Snackbars.showSnackbarSuccess('Operación reintentada');
    } catch (e) {
      Snackbars.showSnackbarError('Error al reintentar: ${e.toString()}');
    }
  }

  String _formatGroupId(String groupId) {
    final timestamp =
        int.tryParse(groupId.replaceAll(StorageKeys.offlineRoutePrefix, '')) ??
            0;
    return DateTime.fromMillisecondsSinceEpoch(timestamp)
        .toString()
        .substring(0, 16);
  }
}

class _RouteGroupDetailsPage extends StatelessWidget {
  final String groupId;
  final List<OfflineOperation> operations;

  const _RouteGroupDetailsPage({
    required this.groupId,
    required this.operations,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Detalles de Grupo de Ruta'),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.route,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ruta iniciada: ${_formatGroupDate(groupId)}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contiene ${operations.length} operaciones pendientes',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...operations.map((op) => _buildOperationCard(op)).toList(),
        ],
      ),
    );
  }

  Widget _buildOperationCard(OfflineOperation operation) {
    final isSynced = operation.data['synced'] == true;
    final color = _getOperationColor(operation.type);
    final icon = _getOperationIcon(operation.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    color: isSynced ? Colors.green[50] : color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSynced ? Colors.green : color,
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
                // if (!isSynced)
                //   IconButton(
                //     icon: const Icon(Icons.refresh, size: 22),
                //     onPressed: () {},
                //     tooltip: 'Reintentar',
                //     color: color,
                //   ),
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
                  const SizedBox(height: 12),
                  const Text(
                    'Datos:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _prettyPrintJson(operation.data),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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

  String _formatGroupDate(String groupId) {
    final timestamp =
        int.tryParse(groupId.replaceAll(StorageKeys.offlineRoutePrefix, '')) ??
            0;
    return DateFormat('dd/MM/yyyy HH:mm')
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _prettyPrintJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
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
}
