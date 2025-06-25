import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_storage/get_storage.dart';
import 'package:safe_driving_app/app.dart';
import 'package:safe_driving_app/features/inspection/data/datasources/inspection_remote_datasource.dart';
import 'package:safe_driving_app/features/inspection/data/repositories/inspection_repository_impl.dart';
import 'package:safe_driving_app/features/inspection/presentation/providers/inspection_provider.dart';
import 'package:safe_driving_app/features/maintenance/data/datasources/maintenance_remote_datasource.dart';
import 'package:safe_driving_app/features/maintenance/data/repositories/maintenance_repository_impl.dart';
import 'package:safe_driving_app/features/maintenance/presentation/providers/maintenance_provider.dart';
import 'package:safe_driving_app/features/offline_operations/presentation/providers/offline_operations_provider.dart';
import 'package:safe_driving_app/features/route/presentation/providers/incident_provider.dart';
import 'package:safe_driving_app/features/speedometer/presentation/providers/select_destination_provider.dart';
import 'package:safe_driving_app/features/speedometer/presentation/providers/select_source_provider.dart';
import 'package:safe_driving_app/features/speedometer/presentation/providers/speedometer_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

// Auth
import 'package:safe_driving_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:safe_driving_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:safe_driving_app/features/auth/presentation/providers/auth_provider.dart';

// Driver
import 'package:safe_driving_app/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:safe_driving_app/features/driver/data/repositories/driver_repository_impl.dart';
import 'package:safe_driving_app/features/driver/presentation/providers/driver_provider.dart';

// Unit
import 'package:safe_driving_app/features/unit/data/datasources/unit_remote_datasource.dart';
import 'package:safe_driving_app/features/unit/data/repositories/unit_repository_impl.dart';
import 'package:safe_driving_app/features/unit/presentation/providers/unit_provider.dart';

// Route y Offline Operations
import 'package:safe_driving_app/features/route/data/datasources/route_local_data_source.dart';
import 'package:safe_driving_app/features/route/data/datasources/route_remote_data_source.dart';
import 'package:safe_driving_app/features/route/data/repositories/route_repository_impl.dart';
import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';
import 'package:safe_driving_app/features/route/presentation/providers/route_provider.dart';
import 'package:safe_driving_app/features/offline_operations/data/repositories/offline_operation_repository_impl.dart';

// Función para inicializar la base de datos
Future<Database> initializeDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'segursat.db');
  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS offline_operations (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT,
          data TEXT NOT NULL,
          retryCount INTEGER NOT NULL,
          lastError TEXT,
          routeId TEXT,
          offlineRouteId TEXT,
          synced INTEGER NOT NULL DEFAULT 0
        )
      ''');
    },
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await GetStorage.init();
  } catch (e) {
    log('Error initializing GetStorage: $e');
  }

  // Inicializar base de datos
  final database = await initializeDatabase();

  // Dependencias de Auth
  final authLocalDataSource = AuthLocalDataSourceImpl();
  final authRepository =
      AuthRepositoryImpl(localDataSource: authLocalDataSource);

  // Dependencias de Unit
  final unitRemoteDataSource = UnitRemoteDataSourceImpl();
  final unitRepository =
      UnitRepositoryImpl(remoteDataSource: unitRemoteDataSource);

  // Dependencias de Driver
  final driverRemoteDataSource = DriverRemoteDataSourceImpl();
  final driverRepository =
      DriverRepositoryImpl(remoteDataSource: driverRemoteDataSource);

  // Dependencias de Route
  final routeLocalDataSource = RouteLocalDataSource(database: database);
  // Importante: inicializar las tablas locales de rutas
  await routeLocalDataSource.init();

  final routeRemoteDataSource =
      RouteRemoteDataSourceImpl(client: http.Client(), dio: Dio());
  final offlineOperationRepo =
      OfflineOperationsRepositoryImpl(database: database);
  final RouteRepository routeRepository = RouteRepositoryImpl(
    localDataSource: routeLocalDataSource,
    remoteDataSource: routeRemoteDataSource,
    offlineOperationsRepository: offlineOperationRepo,
  );

  final maintenanceRepository = MaintenanceRepositoryImpl(
    remoteDataSource: MaintenanceRemoteDataSourceImpl(dio: Dio()),
    offlineOperationsRepository: offlineOperationRepo,
  );

  final inspectionRepository = InspectionRepositoryImpl(
    remoteDataSource: InspectionRemoteDataSourceImpl(dio: Dio()),
    offlineOperationsRepository: offlineOperationRepo,
  );

  final connectivity = Connectivity();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => UnitProvider(unitRepository: unitRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => DriverProvider(driverRepository: driverRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => RouteProvider(
            routeRepository: routeRepository,
            offlineRepo: offlineOperationRepo,
            connectivity: connectivity,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => OfflineOperationsProvider(
              repository: OfflineOperationsRepositoryImpl(
                database: database,
              ),
              routeRepository: routeRepository,
              maintenanceRepository: maintenanceRepository,
              inspectionRepository: inspectionRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => MaintenanceProvider(repository: maintenanceRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => InspectionProvider(repository: inspectionRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => SelectSourceProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SelectDestinationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SpeedometerProvider(
              routeRepository: routeRepository,
              offlineOperationsRepository: offlineOperationRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => IncidentProvider(repository: routeRepository),
        ),
      ],
      child: MyApp(),
    ),
  );
}
