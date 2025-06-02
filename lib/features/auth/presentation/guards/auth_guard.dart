// import 'package:safe_driving_app/features/auth/presentation/providers/auth_provider.dart';
// import 'package:safe_driving_app/features/offline_operations/domain/repositories/offline_operation_repository.dart';
// import 'package:safe_driving_app/features/route/domain/repositories/route_repository.dart';

// class AuthGuard {
//   final AuthProvider authProvider;
//   final RouteRepository routeRepository;
//   final OfflineOperationsRepository offlineRepo;

//   AuthGuard({
//     required this.authProvider,
//     required this.routeRepository,
//     required this.offlineRepo,
//   });

//   Future<String> getInitialRoute() async {
//     // 1. Verificar si está autenticado
//     final isAuthenticated = await authProvider.isAuthenticated();
//     if (!isAuthenticated) return '/startPage';

//     // 2. Verificar si tiene ruta pendiente (online/offline)
//     final hasPendingRoute = await _checkPendingRoute();
//     if (hasPendingRoute) return '/root/speedometer';

//     // 3. Si está autenticado y no tiene ruta pendiente
//     return '/menu';
//   }

//   Future<bool> _checkPendingRoute() async {
//     try {
//       // Primero verificar online
//       final lastRoute = await routeRepository.getLastActiveRoute();
//       if (lastRoute != null && lastRoute.status == RouteStatus.running) {
//         return true;
//       }
//     } catch (e) {
//       // Si falla, verificar offline
//       return await offlineRepo.hasPendingRouteOperation();
//     }
//     return false;
//   }
// }
