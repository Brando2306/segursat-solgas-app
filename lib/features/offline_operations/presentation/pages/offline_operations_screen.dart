import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:safe_driving_app/core/constants/storage_keys.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/presentation/pages/route_groups_list_screen.dart';
import 'package:safe_driving_app/features/offline_operations/presentation/providers/offline_operations_provider.dart';
import 'package:safe_driving_app/features/offline_operations/presentation/pages/offline_operations_list_widget.dart';
import 'package:safe_driving_app/utils/snackbars.dart';

class OfflineOperationsPage extends StatefulWidget {
  const OfflineOperationsPage({super.key});

  @override
  State<OfflineOperationsPage> createState() => _OfflineOperationsPageState();
}

class _OfflineOperationsPageState extends State<OfflineOperationsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => context.read<OfflineOperationsProvider>().loadOperations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Operaciones Pendientes'),
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
          // log(provider.operations
          //     .map((op) =>
          //         "ID: ${op.id}, OfflineRouteId: ${op.offlineRouteId}, Tipo: ${op.type.displayName}, Fecha: ${_formatDate(op.createdAt)}, Datos: ${op.data}")
          //     .toList()
          //     .toString());

          final routeGroups = provider.groupedRouteOperations;

          if (provider.isLoading && provider.operations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando operaciones...'),
                ],
              ),
            );
          }

          // Si no hay operaciones pendientes
          if (provider.operations.isEmpty) {
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
                    'Todas las operaciones se han sincronizado correctamente',
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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // _buildDebugCard(context, provider),
                if (routeGroups.isNotEmpty)
                  _buildRouteOperationsSection(context, routeGroups),
                _buildSection(context,
                    title: 'Mantenimientos',
                    operations: provider.maintenanceOperations,
                    onRetry: (String id) async {
                  await provider.retryMaintenance(id);
                },
                    icon: Icons.build,
                    color:
                        _getOperationColor(OfflineOperationType.maintenance)),
                _buildSection(
                  context,
                  title: 'Inspecciones',
                  operations: provider.inspectionOperations,
                  onRetry: (String id) async {
                    await provider.retryInspection(id);
                  },
                  icon: Icons.assignment,
                  color: _getOperationColor(OfflineOperationType.inspection),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDebugCard(
      BuildContext context, OfflineOperationsProvider provider) {
    return Card(
      color: Colors.yellow[50],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DEBUG: Primeras 20 operaciones offline',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...provider.operations
                .take(20)
                .map((op) => GestureDetector(
                      onTap: () => _showDeleteConfirmation(context, op.id),
                      child: Container(
                        margin: EdgeInsets.all(8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.black)),
                        child: Column(
                          children: [
                            Text(
                              '- ${op.offlineRouteId} |  id: ${op.id}',
                              style: const TextStyle(fontSize: 8),
                            ),
                            Text(
                              '- ${op.type.displayName} | ${_formatDate(op.createdAt)}',
                              style: const TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteOperationsSection(
      BuildContext context, Map<String, List<OfflineOperation>> routeGroups) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  // child: Icon(icon, color: color, size: 20),
                  child: Icon(Icons.route, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Rutas Pendientes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${routeGroups.length}',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...routeGroups.entries.take(2).map((entry) {
              final offlineId = entry.key;
              final operations = entry.value;
              return _buildRouteGroupCard(
                context,
                'Ruta iniciada: ${_formatGroupDate(offlineId)}',
                operations,
                offlineId: offlineId,
              );
            }).toList(),
            if (routeGroups.length > 2) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RouteGroupsListPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text('Ver ${routeGroups.length - 2} más'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    textStyle: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
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

  Widget _buildRouteGroupCard(
      BuildContext context, String title, List<OfflineOperation> operations,
      {required String offlineId}) {
    final provider = context.read<OfflineOperationsProvider>();

    // 1. Buscar operaciones relevantes
    final creationOp = operations.firstWhere(
      (op) => op.type == OfflineOperationType.routeCreation,
      orElse: () => OfflineOperation(
        type: OfflineOperationType.routeCreation,
        data: {},
        offlineRouteId: offlineId,
      ),
    );

    // 2. Obtener TODAS las posiciones agrupadas (ahora vienen en una sola operación)
    final positionOp = operations.firstWhere(
      (op) => op.type == OfflineOperationType.routePositions,
      orElse: () => OfflineOperation(
        type: OfflineOperationType.routePositions,
        data: {'positions': []},
        offlineRouteId: offlineId,
      ),
    );

    // 3. Buscar operación SOS (para rutas que tengan emergencias)
    final sosOp = operations.firstWhere(
      (op) => op.type == OfflineOperationType.routeSos,
      orElse: () => OfflineOperation(
        type: OfflineOperationType.routeSos,
        data: {},
        offlineRouteId: offlineId,
      ),
    );

    // 4. Buscar operación emergencyCall (para rutas que tengan llamadas de emergencia)
    final emergencyCallOp = operations.firstWhere(
      (op) => op.type == OfflineOperationType.emergencyCall,
      orElse: () => OfflineOperation(
        type: OfflineOperationType.emergencyCall,
        data: {},
        offlineRouteId: offlineId,
      ),
    );

    // 5. Buscar operación routeCancel (para rutas que hayan sido canceladas)
    final cancelOp = operations.firstWhere(
      (op) => op.type == OfflineOperationType.routeCancel,
      orElse: () => OfflineOperation(
        type: OfflineOperationType.routeCancel,
        data: {},
        offlineRouteId: offlineId,
      ),
    );

    // 6. Buscar operación de finalización (puede que no exista si la ruta no se ha completado)
    final finishOp = operations.firstWhere(
      (op) => op.type == OfflineOperationType.routeFinish,
      orElse: () => OfflineOperation(
        type: OfflineOperationType.routeFinish,
        data: {},
        offlineRouteId: offlineId,
      ),
    );

    // 7. Buscar operación de incidente (puede haber varias, aquí solo la primera)
    final incidentOps = operations
        .where((op) => op.type == OfflineOperationType.incidentReport)
        .toList();

    // 8. Buscar operación de ruta stop (puede haber varias, aquí solo la primera)
    final stopOps = operations
        .where((op) => op.type == OfflineOperationType.routeStop)
        .toList();

    // Calcular total de posiciones pendientes
    final pendingPositions = (positionOp.data['positions'] as List).length;
    final isPositionsSynced = positionOp.data['synced'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      margin: const EdgeInsets.only(top: 8),
      child: ExpansionTile(
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.grey[50],
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.route,
            color: Colors.blue,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Creación de ruta
                _buildOperationItem(
                  context: context,
                  operation: creationOp,
                  title: 'Creación de ruta',
                  icon: Icons.route,
                  color: Colors.blue,
                  isSynced: creationOp.data['synced'] == true,
                  onRetry: (id) => provider.retryOperationById(id),
                ),

                // Posiciones pendientes (¡Ahora muestra el total!)
                if (pendingPositions > 0)
                  _buildOperationItem(
                    context: context,
                    operation: positionOp,
                    title: '$pendingPositions posiciones pendientes',
                    icon: Icons.location_on,
                    color: Colors.green,
                    isSynced: isPositionsSynced,
                    onRetry: (id) => provider.retryRoutePositions(id),
                  ),

                // Evento SOS
                if (sosOp.data.isNotEmpty)
                  _buildOperationItem(
                    context: context,
                    operation: sosOp,
                    title: 'Alerta de emergencia enviada',
                    icon: Icons.warning,
                    color: Colors.red,
                    isSynced: sosOp.data['synced'] == true,
                    onRetry: (id) => provider.retryOperationById(id),
                  ),

                // Llamada de emergencia
                if (emergencyCallOp.data.isNotEmpty)
                  _buildOperationItem(
                    context: context,
                    operation: emergencyCallOp,
                    title: 'Llamada a emergencia',
                    icon: Icons.phone,
                    color: Colors.purple,
                    isSynced: emergencyCallOp.data['synced'] == true,
                    onRetry: (id) => provider.retryOperationById(id),
                  ),

                for (int i = 0; i < incidentOps.length; i++)
                  _buildOperationItem(
                    context: context,
                    operation: incidentOps[i],
                    title: 'Incidente reportado #${i + 1}',
                    icon: Icons.report,
                    color: Colors.redAccent,
                    isSynced: incidentOps[i].data['synced'] == true,
                    onRetry: (id) => provider.retryOperationById(id),
                  ),

                for (int i = 0; i < stopOps.length; i++)
                  _buildOperationItem(
                    context: context,
                    operation: stopOps[i],
                    title: 'Parada de ruta #${i + 1}',
                    icon: Icons.stop,
                    color: Colors.blueGrey,
                    isSynced: stopOps[i].data['synced'] == true,
                    onRetry: (id) => provider.retryOperationById(id),
                  ),

                // // Cancelación de ruta
                if (cancelOp.data.isNotEmpty)
                  _buildOperationItem(
                    context: context,
                    operation: cancelOp,
                    title: 'Cancelación de ruta',
                    icon: Icons.cancel,
                    color: Colors.orange,
                    isSynced: cancelOp.data['synced'] == true,
                    onRetry: (id) => provider.retryOperationById(id),
                  ),

                // Finalización de ruta
                if (finishOp.data.isNotEmpty)
                  _buildOperationItem(
                    context: context,
                    operation: finishOp,
                    title: 'Finalización de ruta',
                    icon: Icons.flag,
                    color: Colors.orange,
                    isSynced: finishOp.data['synced'] == true,
                    onRetry: (id) => provider.retryOperationById(id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<OfflineOperation> operations,
    required Future<void> Function(String) onRetry,
    required IconData icon,
    required Color color,
  }) {
    if (operations.isEmpty) return const SizedBox();

    final previewOps =
        operations.length > 2 ? operations.sublist(0, 2) : operations;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${operations.length}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...previewOps.map((op) => _buildOperationItem(
                  context: context,
                  operation: op,
                  title: op.type.displayName,
                  icon: _getOperationIcon(op.type),
                  color: _getOperationColor(op.type),
                  isSynced: op.data['synced'] == true,
                  onRetry: onRetry,
                )),
            if (operations.length > 2) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OfflineOperationsListPage(
                          title: title,
                          operations: operations,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text('Ver ${operations.length - 2} más'),
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    textStyle: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
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
      default:
        return Colors.grey;
    }
  }

  Widget _buildOperationItem({
    required BuildContext context,
    required OfflineOperation operation,
    required String title,
    required IconData icon,
    required Color color,
    bool isSynced = false,
    Future<void> Function(String)? onRetry,
  }) {
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
            // Icono con estado de sincronización
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

            // Información de la operación
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

            // Botón de reintento (solo si no está sincronizado)
            if (!isSynced && onRetry != null)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => onRetry(operation.id),
                tooltip: 'Reintentar',
                color: color,
              ),

            // IconButton(
            //   icon: const Icon(Icons.delete, size: 20),
            //   onPressed: () => _showDeleteConfirmation(context, operation.id),
            //   tooltip: 'Eliminar',
            //   color: Colors.red,
            // ),
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

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirmar eliminación'),
        content: const Text(
            '¿Estás seguro de eliminar esta operación pendiente? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context
                    .read<OfflineOperationsProvider>()
                    .removeOperation(id);

                Snackbars.showSnackbarSuccess(
                    'Operación eliminada correctamente');
              } catch (e) {
                Snackbars.showSnackbarError('Error al eliminar: $e');
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
