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
        title: const Text('Grupos de Rutas Pendientes'),
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
    final creationOp = operations.firstWhere(
      (op) => op.type == OfflineOperationType.routeCreation,
    );

    final positionsCount = operations
        .where((op) => op.type == OfflineOperationType.routePositions)
        .fold<int>(0, (sum, op) => sum + (op.data['positions'] as List).length);

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
            ),
            if (positionsCount > 0)
              _buildOperationItem(
                context,
                operations.firstWhere(
                    (op) => op.type == OfflineOperationType.routePositions),
                '$positionsCount posiciones',
                Icons.location_on,
                Colors.green,
              ),
            if (hasSOS)
              _buildOperationItem(
                context,
                operations.firstWhere(
                    (op) => op.type == OfflineOperationType.routeSos),
                'Alerta SOS',
                Icons.warning,
                Colors.red,
              ),
            if (hasEmergency)
              _buildOperationItem(
                context,
                operations.firstWhere(
                    (op) => op.type == OfflineOperationType.emergencyCall),
                'Llamada de emergencia',
                Icons.phone,
                Colors.purple,
              ),
            if (hasIncidents > 0)
              _buildOperationItem(
                context,
                operations.firstWhere(
                    (op) => op.type == OfflineOperationType.incidentReport),
                '$hasIncidents incidente(s)',
                Icons.report,
                Colors.redAccent,
              ),
            if (hasStops > 0)
              _buildOperationItem(
                context,
                operations.firstWhere(
                    (op) => op.type == OfflineOperationType.routeStop),
                '$hasStops parada(s)',
                Icons.stop,
                Colors.blueGrey,
              ),
            if (isFinished)
              _buildOperationItem(
                context,
                operations.firstWhere(
                    (op) => op.type == OfflineOperationType.routeFinish),
                'Finalización de ruta',
                Icons.flag,
                Colors.orange,
              ),
            if (isCancelled)
              _buildOperationItem(
                context,
                operations.firstWhere(
                    (op) => op.type == OfflineOperationType.routeCancel),
                'Cancelación de ruta',
                Icons.cancel,
                Colors.orange,
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

  String _formatGroupDate(String offlineId) {
    final timestamp = int.tryParse(
            offlineId.replaceAll(StorageKeys.offlineRoutePrefix, '')) ??
        0;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  Widget _buildOperationItem(
    BuildContext context,
    OfflineOperation operation,
    String title,
    IconData icon,
    Color color,
  ) {
    final isSynced = operation.data['synced'] == true;

    return Container(
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
          if (!isSynced)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _retrySingleOperation(context, operation.id),
              tooltip: 'Reintentar',
              color: color,
            ),
        ],
      ),
    );
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
      appBar: AppBar(
        title: const Text('Detalles de Grupo de Ruta'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...operations.map((op) => _buildOperationDetailCard(op)),
        ],
      ),
    );
  }

  Widget _buildOperationDetailCard(OfflineOperation operation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              operation.type.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fecha: ${_formatDate(operation.createdAt)}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Intentos: ${operation.retryCount}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (operation.lastError != null)
              Text(
                'Error: ${operation.lastError}',
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 12),
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
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  String _prettyPrintJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}
