import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/network/api_client.dart';
import 'package:findme/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The API client every repository uses; the token comes from the signed-in session.
final apiClientProvider = Provider<ApiClient>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return ApiClient(ref.watch(appConfigProvider), auth.getAccessToken);
});
