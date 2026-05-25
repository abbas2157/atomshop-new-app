import 'package:atompro/features/seller/leads/model/seller_leads_model.dart';
import 'package:atompro/features/seller/leads/repository/seller_leads_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sellerLeadsBundleProvider = FutureProvider.autoDispose
    .family<SellerLeadsBundle, SellerLeadsQuery>((ref, query) {
      return ref.read(sellerLeadsRepositoryProvider).getLeadsBundle(query);
    });
