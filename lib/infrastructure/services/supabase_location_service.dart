import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';

class SupabaseLocationService {
  SupabaseLocationService({SupabaseSessionManager? sessionManager})
    : _sessionManager = sessionManager ?? supabaseSessionManager;

  final SupabaseSessionManager _sessionManager;

  Future<NativeLocationContext> fetchLocationContext({
    String? requestedBusinessId,
  }) async {
    await _sessionManager.requireSession();
    final response = await supabase
        .schema('mediasis')
        .rpc(
          'get_native_location_context',
          params: {
            if (requestedBusinessId != null && requestedBusinessId.isNotEmpty)
              'p_requested_business_id': requestedBusinessId,
          },
        );
    if (response is! Map) {
      throw const FormatException('LOCATION_CONTEXT_INVALID');
    }
    return NativeLocationContext.fromMap(Map<String, dynamic>.from(response));
  }
}
