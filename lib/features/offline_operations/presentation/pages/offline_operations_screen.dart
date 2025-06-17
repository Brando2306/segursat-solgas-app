import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:safe_driving_app/core/constants/storage_keys.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/presentation/pages/RouteOperationsDetailPage.dart';
import 'package:safe_driving_app/features/offline_operations/presentation/providers/offline_operations_provider.dart';
import 'package:safe_driving_app/features/offline_operations/presentation/widgets/offline_operations_list_widget.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_position_entity.dart';
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
          final routeGroups = provider.groupedRouteOperations;

          if (provider.isLoading && provider.operations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                Card(
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
                            .map((op) => Container(
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
                                        '- ${_getOperationTitle(op.type)} | ${_formatDate(op.createdAt)}',
                                        style: const TextStyle(fontSize: 8),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ],
                    ),
                  ),
                ),
                if (routeGroups.isNotEmpty)
                  _buildRouteOperationsSection(context, routeGroups),
                SizedBox(height: 16),
                _buildSection(
                  context,
                  title: 'Mantenimientos',
                  operations: provider.maintenanceOperations,
                  onRetry: (String id) async {
                    await provider.retryMaintenance(context, id);
                  },
                  icon: Icons.build,
                  color: Colors.orange,
                ),
                _buildSection(
                  context,
                  title: 'Emergencias SOS',
                  operations: provider.routeSosOperations,
                  onRetry: (String id) async {
                    await provider.retryRouteSos(context, id);
                  },
                  icon: Icons.warning,
                  color: Colors.red,
                ),
                _buildSection(
                  context,
                  title: 'Inspecciones',
                  operations: provider.inspectionOperations,
                  onRetry: (String id) async {
                    await provider.retryInspection(context, id);
                  },
                  icon: Icons.assignment,
                  color: Colors.teal,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRouteOperationsSection(
      BuildContext context, Map<String, List<OfflineOperation>> routeGroups) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rutas Pendientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...routeGroups.entries.map((entry) {
              final offlineId = entry.key;
              final operations = entry.value;

              // Extraer el timestamp del offlineId para mostrar información útil
              final timestamp = int.tryParse(offlineId.replaceAll(
                      StorageKeys.offlineRoutePrefix, '')) ??
                  0;
              final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
              final formattedDate =
                  DateFormat('dd/MM/yyyy HH:mm').format(dateTime);

              return _buildRouteGroupCard(
                context,
                'Ruta iniciada: $formattedDate',
                operations,
                offlineId: offlineId,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteGroupCard(
      BuildContext context, String title, List<OfflineOperation> operations,
      {required String offlineId}) {
    final provider = context.read<OfflineOperationsProvider>();

    // Filtrar operaciones por tipo y estado de sincronización
    final creationOp = operations.firstWhere(
      (op) => op.type == OfflineOperationType.routeCreation,
      orElse: () => OfflineOperation(
        type: OfflineOperationType.routeCreation,
        data: {},
        offlineRouteId: offlineId,
      ),
    );

    final positionOps = operations
        .where((op) => op.type == OfflineOperationType.routePositions)
        .toList();

    final finishOp = operations.firstWhere(
      (op) => op.type == OfflineOperationType.routeFinish,
      orElse: () => OfflineOperation(
        type: OfflineOperationType.routeFinish,
        data: {},
        offlineRouteId: offlineId,
      ),
    );

    // Calcular estados de sincronización
    final isCreationSynced = creationOp.data['synced'] == true;
    final arePositionsSynced = positionOps.isEmpty ||
        positionOps.every((op) => op.data['synced'] == true);
    final isFinishSynced = finishOp.data['synced'] == true;
    final isGroupSynced =
        isCreationSynced && arePositionsSynced && isFinishSynced;

    return Card(
      margin: const EdgeInsets.only(top: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con estado de sincronización
            Row(
              children: [
                Icon(
                  isGroupSynced ? Icons.check_circle : Icons.sync_problem,
                  color: isGroupSynced ? Colors.green : Colors.orange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isGroupSynced ? Colors.green : Colors.black,
                    ),
                  ),
                ),
                if (!isGroupSynced)
                  Text(
                    '${operations.where((op) => op.data['synced'] != true).length} pendientes',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
            SizedBox(height: 8),

            // Creación de ruta
            _buildOperationItem(
              context: context,
              operation: creationOp,
              title: 'Creación de ruta',
              icon: Icons.route,
              color: Colors.blue,
              isSynced: isCreationSynced,
              onRetry: (id) => provider.retryOperationById(id, context),
            ),

            // Posiciones pendientes
            if (positionOps.isNotEmpty)
              _buildOperationItem(
                context: context,
                operation: positionOps.first,
                title:
                    '${positionOps.length} ${positionOps.length == 1 ? 'posición' : 'posiciones'} pendientes',
                icon: Icons.location_on,
                color: Colors.green,
                isSynced: arePositionsSynced,
                isBatch: true,
                onRetry: (id) => provider.retryOperationById(id, context),
              ),

            // Finalización de ruta
            _buildOperationItem(
              context: context,
              operation: finishOp,
              title: 'Finalización de ruta',
              icon: Icons.flag,
              color: Colors.orange,
              isSynced: isFinishSynced,
              onRetry: (id) => provider.retryOperationById(id, context),
            ),

            // Botón para reintentar todo el grupo
            SizedBox(height: 8),
            if (!isGroupSynced)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _retryRouteGroup(context, operations, offlineId),
                  icon: Icon(Icons.refresh, size: 18),
                  label: Text('Reintentar todo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationItemGroup({
    required BuildContext context,
    required OfflineOperation operation,
    required String title,
    required IconData icon,
    required Color color,
    required bool isSynced,
    bool isBatch = false,
  }) {
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
          if (!isSynced)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _retrySingleOperation(context, operation),
              tooltip: 'Reintentar',
              color: color,
            ),
        ],
      ),
    );
  }

  Future<void> _retrySingleOperation(
      BuildContext context, OfflineOperation operation) async {
    final provider = context.read<OfflineOperationsProvider>();

    try {
      switch (operation.type) {
        case OfflineOperationType.routeCreation:
          final route = CreateRouteEntity.fromJson(operation.data);
          await provider.routeRepository.createRoute(route);
          break;
        case OfflineOperationType.routePositions:
          final positions = (operation.data['positions'] as List)
              .map((p) => RoutePositionEntity.fromJson(p))
              .toList();
          await provider.routeRepository.sendRoutePositions(positions);
          break;
        case OfflineOperationType.routeFinish:
          final finish = FinishRouteEntity.fromJson(operation.data);
          await provider.routeRepository.finishRoute(finish);
          break;
        default:
          throw Exception('Tipo de operación no soportado');
      }

      // Marcar como sincronizado
      await provider.repository.updateOperation(
        operation.copyWith(data: {...operation.data, 'synced': true}),
      );

      await provider.loadOperations();
      Snackbars.showSnackbarSuccess('Operación sincronizada correctamente');
    } catch (e) {
      Snackbars.showSnackbarError('Error al reintentar: ${e.toString()}');
    }
  }

  Future<void> _retryRouteGroup(
    BuildContext context,
    List<OfflineOperation> operations,
    String offlineId,
  ) async {
    final provider = context.read<OfflineOperationsProvider>();

    try {
      // Ordenar operaciones: creación -> posiciones -> finalización
      operations.sort((a, b) {
        if (a.type == OfflineOperationType.routeCreation) return -1;
        if (b.type == OfflineOperationType.routeCreation) return 1;
        if (a.type == OfflineOperationType.routePositions) return -1;
        if (b.type == OfflineOperationType.routePositions) return 1;
        return 0;
      });

      bool allSynced = true;

      for (final op in operations) {
        if (op.data['synced'] == true) continue;

        try {
          // Usamos el retryOperation del provider que espera la operación completa
          await provider.retryOperation(op, context);

          // Si llegamos aquí, la operación fue exitosa
          await provider.repository.updateOperation(
            op.copyWith(data: {...op.data, 'synced': true}),
          );
        } catch (e) {
          allSynced = false;
          continue;
        }
      }

      if (allSynced) {
        // Eliminar el grupo completo si todo está sincronizado
        await provider.cleanupSyncedGroup(offlineId);
      }

      Snackbars.showSnackbarSuccess(allSynced
          ? 'Todas las operaciones sincronizadas'
          : 'Algunas operaciones se sincronizaron, verifique las pendientes');
    } catch (e) {
      Snackbars.showSnackbarError('Error al reintentar: ${e.toString()}');
    }
  }

  Future<void> _cleanupSyncedGroup(
      OfflineOperationsProvider provider, String offlineId) async {
    final operations =
        await provider.repository.getOperationsByOfflineId(offlineId);

    if (operations.every((op) => op.data['synced'] == true)) {
      for (final op in operations) {
        await provider.repository.removeOperation(op.id);
      }
    }
  }

  Widget _buildRouteGroup(
      BuildContext context, String routeId, List<OfflineOperation> operations) {
    if (operations.isEmpty) {
      return SizedBox.shrink(); // O algún widget vacío
    }

    // Buscamos las operaciones (pueden no existir)
    final hasCreation =
        operations.any((op) => op.type == OfflineOperationType.routeCreation);
    final positionsOps = operations
        .where((op) => op.type == OfflineOperationType.routePositions)
        .toList();
    final hasFinish =
        operations.any((op) => op.type == OfflineOperationType.routeFinish);

    // Obtenemos el nombre de la unidad de la primera operación que lo tenga
    String routeName = routeId;
    for (var op in operations) {
      if (op.data['unit_name'] != null) {
        routeName = op.data['unit_name'];
        break;
      }
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RouteOperationsDetailPage(
              routeId: routeId,
              operations: operations,
            ),
          ),
        );
      },
      child: ExpansionTile(
        title: Text('Ruta: $routeName'),
        subtitle: Text('${operations.length} operaciones pendientes'),
        children: [
          if (hasCreation)
            _buildOperationItemRoute(
              context: context,
              operation: operations.firstWhere(
                  (op) => op.type == OfflineOperationType.routeCreation),
              title: 'Creación de ruta',
              icon: Icons.route,
              color: Colors.blue,
              onRetry: () => _retryRouteOperations(context, routeId),
            ),
          if (positionsOps.isNotEmpty)
            _buildOperationItemRoute(
              context: context,
              operation: positionsOps.first,
              title: '${positionsOps.length} posiciones pendientes',
              icon: Icons.location_on,
              color: Colors.green,
              onRetry: () => _retryRouteOperations(context, routeId),
            ),
          if (hasFinish)
            _buildOperationItemRoute(
              context: context,
              operation: operations.firstWhere(
                  (op) => op.type == OfflineOperationType.routeFinish),
              title: 'Finalización de ruta',
              icon: Icons.flag,
              color: Colors.orange,
              onRetry: () => _retryRouteOperations(context, routeId),
            ),
        ],
      ),
    );
  }

  Future<void> _retryOperation(
    BuildContext context,
    OfflineOperation operation,
  ) async {
    final provider = context.read<OfflineOperationsProvider>();
    try {
      await provider.retryRouteOperations(operation.associatedRouteId ?? '');
    } catch (e) {
      Snackbars.showSnackbarError('Error al reintentar: ${e.toString()}');
    }
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
                  title: _getOperationTitle(op.type),
                  icon: _getOperationIcon(op.type),
                  color: _getOperationColor(op.type),
                  isSynced: op.data['synced'] == true,
                  onRetry: (id) => context
                      .read<OfflineOperationsProvider>()
                      .retryOperationById(id, context),
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

  String _getOperationTitle(OfflineOperationType type) {
    switch (type) {
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
      default:
        return 'Operación';
    }
  }

  IconData _getOperationIcon(OfflineOperationType type) {
    switch (type) {
      case OfflineOperationType.routeCreation:
        return Icons.route;
      case OfflineOperationType.routePositions:
        return Icons.location_on;
      case OfflineOperationType.routeFinish:
        return Icons.flag;
      case OfflineOperationType.routeRecovery:
        return Icons.restore;
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
      case OfflineOperationType.routeRecovery:
        return Colors.purple;
      case OfflineOperationType.maintenance:
        return Colors.teal;
      case OfflineOperationType.inspection:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOperationItemRoute({
    required BuildContext context,
    required OfflineOperation operation,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onRetry,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Intentos: ${operation.retryCount}'),
          if (operation.lastError != null)
            Text(
              'Último error: ${operation.lastError}',
              style: TextStyle(color: Colors.red),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: onRetry,
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context, operation.id),
          ),
        ],
      ),
      onTap: () => _showOperationDetails(context, operation),
    );
  }

  Future<void> _retryRouteOperations(
      BuildContext context, String routeId) async {
    final provider = context.read<OfflineOperationsProvider>();
    try {
      await provider.retryRouteOperations(routeId);
      Snackbars.showSnackbarSuccess('Operaciones de ruta reintentadas');
    } catch (e) {
      Snackbars.showSnackbarError('Error: ${e.toString()}');
    }
  }

  Widget _buildOperationItem({
    required BuildContext context,
    required OfflineOperation operation,
    required String title,
    required IconData icon,
    required Color color,
    bool isSynced = false,
    bool isBatch = false,
    Future<void> Function(String)? onRetry,
  }) {
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
        ],
      ),
    );
  }

  Future<void> _handleRetry(
    BuildContext context,
    String operationId,
    Future<void> Function(String) onRetry,
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

      await onRetry(operationId);

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

  // String _getOperationTitle(OfflineOperationType type) {
  //   switch (type) {
  //     case OfflineOperationType.routeRecovery:
  //       return 'Recuperación de Ruta';
  //     case OfflineOperationType.maintenance:
  //       return 'Registro de Mantenimiento';
  //     case OfflineOperationType.routePositions:
  //       return 'Posiciones de Ruta';
  //     case OfflineOperationType.inspection:
  //       return 'Inspección';
  //     case OfflineOperationType.incidentReport:
  //       return 'Reporte de Incidente';
  //     default:
  //       return 'Operación Desconocida';
  //   }
  // }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
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
}
