import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/offline_operation.dart';
import 'package:safe_driving_app/features/offline_operations/domain/entities/operation_type.enum.dart';
import 'package:safe_driving_app/features/offline_operations/presentation/providers/offline_operations_provider.dart';
import 'package:safe_driving_app/utils/snackbars.dart';

class RouteOperationsDetailPage extends StatelessWidget {
  final String routeId;
  final List<OfflineOperation> operations;

  const RouteOperationsDetailPage({
    required this.routeId,
    required this.operations,
  });

  @override
  Widget build(BuildContext context) {
    final creationOp = operations.firstWhere(
      (op) => op.type == OfflineOperationType.routeCreation,
    );

    final positionsOps = operations
        .where(
          (op) => op.type == OfflineOperationType.routePositions,
        )
        .toList();

    final finishOp = operations.firstWhere(
      (op) => op.type == OfflineOperationType.routeFinish,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de Ruta'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _retryAllOperations(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ruta: ${creationOp.data['unit_name'] ?? routeId}',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 16),

            // Sección de creación
            _buildOperationSection(
              context,
              title: 'Creación de Ruta',
              operation: creationOp,
              icon: Icons.route,
              color: Colors.blue,
            ),

            // Sección de posiciones
            if (positionsOps.isNotEmpty)
              _buildOperationSection(
                context,
                title: 'Posiciones Pendientes (${positionsOps.length})',
                operation: positionsOps.first,
                icon: Icons.location_on,
                color: Colors.green,
                isBatch: true,
                count: positionsOps.length,
              ),

            // Sección de finalización
            if (finishOp != null)
              _buildOperationSection(
                context,
                title: 'Finalización de Ruta',
                operation: finishOp,
                icon: Icons.flag,
                color: Colors.orange,
              ),

            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _retryAllOperations(context),
                child: Text('Reintentar Todas las Operaciones'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationSection(
    BuildContext context, {
    required String title,
    required OfflineOperation operation,
    required IconData icon,
    required Color color,
    bool isBatch = false,
    int count = 1,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.subtitle1?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Spacer(),
                Text(
                  'Intentos: ${operation.retryCount}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (operation.lastError != null) ...[
              SizedBox(height: 8),
              Text(
                'Error: ${operation.lastError}',
                style: TextStyle(color: Colors.red),
              ),
            ],
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showOperationDetails(context, operation),
                    child: Text('Ver Detalles'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _retryOperation(context, operation),
                    child: Text(isBatch ? 'Reintentar $count' : 'Reintentar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retryOperation(
    BuildContext context,
    OfflineOperation operation,
  ) async {
    final provider = context.read<OfflineOperationsProvider>();
    try {
      await provider.retryRouteOperations(routeId);

      Snackbars.showSnackbarSuccess('Operación completada');
    } catch (e) {
      Snackbars.showSnackbarError('Error: ${e.toString()}');
    }
  }

  Future<void> _retryAllOperations(BuildContext context) async {
    final provider = context.read<OfflineOperationsProvider>();
    try {
      await provider.retryRouteOperations(routeId);
      Snackbars.showSnackbarSuccess('Todas las operaciones reintentadas');

      Navigator.pop(context); // Cerrar la pantalla de detalles
    } catch (e) {
      Snackbars.showSnackbarError('Error: ${e.toString()}');
    }
  }

  void _showOperationDetails(BuildContext context, OfflineOperation operation) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Detalles de Operación'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipo: ${operation.type.toString().split('.').last}'),
              Text('Intentos: ${operation.retryCount}'),
              if (operation.lastError != null)
                Text('Último error: ${operation.lastError}'),
              SizedBox(height: 16),
              Text(
                'Datos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  JsonEncoder.withIndent('  ').convert(operation.data),
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
