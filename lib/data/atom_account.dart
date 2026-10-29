import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/auth/session_manager.dart';
import '../utils/atom_format.dart';
import 'atom_design_content.dart';
import 'atom_http.dart';
import 'atom_models.dart';

/// Signed-in account data, custom orders, offers, Ask Atom, content pages
/// and notifications (docs/backend-prompt-app-v2.md, sections B–I). Every
/// money figure comes from the server; the app never works out markup,
/// totals or balances.

int _int(Object? v, [int fallback = 0]) => AtomFormat.parseAmount(v) ?? fallback;
int? _intOrNull(Object? v) => v == null ? null : AtomFormat.parseAmount(v);
String _str(Object? v) => v == null ? '' : v.toString();
Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse(v.toString());
List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) parse) => atomList(v).map(parse).toList(growable: false);

/// "Varification" (stored) → "Verification" (shown), when the server sends
/// no label.
String _label(Map<String, dynamic> j) {
  final label = _str(j['status_label']);
  if (label.isNotEmpty) return label;
  final status = _str(j['status']);
  return status == 'Varification' ? 'Verification' : status;
}

// ── Summary (Account, Overview) ───────────────────────────────────────────

class NextDue {
  const NextDue({required this.amount, required this.date, required this.label, required this.orderUuid, required this.product});

  final int amount;
  final DateTime? date;
  final String label;
  final String orderUuid;
  final String product;

  static NextDue? fromJson(Object? v) {
    final j = _map(v);
    if (j.isEmpty) return null;
    return NextDue(amount: _int(j['amount']), date: _date(j['date']), label: _str(j['label']), orderUuid: _str(j['order_uuid']), product: _str(j['product']));
  }
}

enum AtompayState { none, incomplete, pending, approved, rejected }

class AtompayStatus {
  const AtompayStatus({required this.state, required this.conditional, required this.limit, required this.available, required this.maxMonthly, required this.months, required this.url});

  final AtompayState state;
  final bool conditional;
  final int? limit;
  final int? available;
  final int? maxMonthly;
  final int? months;
  final String url;

  factory AtompayStatus.fromJson(Map<String, dynamic> j) => AtompayStatus(
        state: AtompayState.values.firstWhere((s) => s.name == j['state'], orElse: () => AtompayState.none),
        conditional: j['conditional'] == true,
        limit: _intOrNull(j['limit']),
        available: _intOrNull(j['available']),
        maxMonthly: _intOrNull(j['max_monthly']),
        months: _intOrNull(j['months']),
        url: _str(j['url']),
      );
}

class AccountSummary {
  const AccountSummary({
    required this.orders,
    required this.activePlans,
    required this.paid,
    required this.unpaid,
    required this.nextDue,
    required this.verified,
    required this.identity,
    required this.addressVisitAt,
    required this.cnicMasked,
    required this.atompay,
    required this.unreadNotifications,
  });

  final int orders;
  final int activePlans;
  final int paid;
  final int unpaid;
  final NextDue? nextDue;
  final bool verified;

  /// "atompay" or "atomshop" (who verified the identity), or empty.
  final String identity;
  final DateTime? addressVisitAt;
  final String cnicMasked;
  final AtompayStatus atompay;
  final int unreadNotifications;

  factory AccountSummary.fromJson(Map<String, dynamic> j) {
    final stats = _map(j['stats']);
    final v = _map(j['verification']);
    return AccountSummary(
      orders: _int(stats['orders']),
      activePlans: _int(stats['active_plans']),
      paid: _int(stats['paid']),
      unpaid: _int(stats['unpaid']),
      nextDue: NextDue.fromJson(j['next_due']),
      verified: v['verified'] == true,
      identity: _str(v['identity']),
      addressVisitAt: _date(v['address_visit_at']),
      cnicMasked: _str(v['cnic_masked']),
      atompay: AtompayStatus.fromJson(_map(j['atompay'])),
      unreadNotifications: _int(j['unread_notifications']),
    );
  }
}

// ── Orders and installments ───────────────────────────────────────────────

enum InstallmentStatus { paid, unpaid, overdue }

class Installment {
  const Installment({
    required this.id,
    required this.label,
    required this.amount,
    required this.paidAmount,
    required this.dueDate,
    required this.status,
    required this.paidAt,
    required this.method,
    required this.receiptUrl,
  });

  /// Null for months the server has not created rows for yet.
  final int? id;
  final String label;
  final int amount;
  final int paidAmount;
  final DateTime? dueDate;
  final InstallmentStatus status;
  final DateTime? paidAt;
  final String method;
  final String receiptUrl;

  factory Installment.fromJson(Map<String, dynamic> j) => Installment(
        id: _intOrNull(j['id']),
        label: _str(j['label']),
        amount: _int(j['amount']),
        paidAmount: _int(j['paid_amount']),
        dueDate: _date(j['due_date']),
        status: switch (_str(j['status']).toLowerCase()) {
          'paid' => InstallmentStatus.paid,
          'overdue' => InstallmentStatus.overdue,
          _ => InstallmentStatus.unpaid,
        },
        paidAt: _date(j['paid_at']),
        method: _str(j['method']),
        receiptUrl: _str(j['receipt_url']),
      );
}

class SellerContact {
  const SellerContact({required this.name, required this.businessName, required this.phone, required this.area});

  final String name;
  final String businessName;
  final String phone;
  final String area;

  /// "Ali Electronics, Johar Town".
  String get display => [businessName.isNotEmpty ? businessName : name, area].where((s) => s.isNotEmpty).join(', ');

  static SellerContact? fromJson(Object? v) {
    final j = _map(v);
    if (j.isEmpty) return null;
    return SellerContact(name: _str(j['name']), businessName: _str(j['business_name']), phone: _str(j['phone']), area: _str(j['area']));
  }
}

/// One order in a list (product order or custom order).
class OrderCard {
  const OrderCard({
    required this.uuid,
    required this.isCustom,
    required this.isAtompay,
    required this.status,
    required this.statusLabel,
    required this.product,
    required this.pictureUrl,
    required this.storage,
    required this.colour,
    required this.months,
    required this.advance,
    required this.monthly,
    required this.total,
    required this.paid,
    required this.outstanding,
    required this.createdAt,
    required this.nextDue,
    required this.orderId,
    required this.paidMonths,
    required this.seller,
    required this.schedule,
  });

  final String uuid;
  final bool isCustom;
  final bool isAtompay;

  /// As stored ("Varification"…), for logic; [statusLabel] for display.
  final String status;
  final String statusLabel;
  final String product;
  final String pictureUrl;
  final String storage;
  final String colour;
  final int months;
  final int advance;
  final int? monthly;
  final int total;
  final int paid;
  final int outstanding;
  final DateTime? createdAt;
  final NextDue? nextDue;
  final String orderId;

  /// Installments tab only.
  final int paidMonths;
  final SellerContact? seller;
  final List<Installment> schedule;

  String get title => [product, if (storage.isNotEmpty) storage].join(' · ');

  factory OrderCard.fromJson(Map<String, dynamic> j) {
    final p = _map(j['product']);
    return OrderCard(
      uuid: _str(j['uuid']),
      isCustom: j['kind'] == 'custom',
      isAtompay: j['type'] == 'atompay',
      status: _str(j['status']),
      statusLabel: _label(j),
      product: _str(p['title']),
      pictureUrl: _str(p['picture_url']),
      storage: _str(p['storage']),
      colour: _str(p['colour']),
      months: _int(j['months']),
      advance: _int(j['advance']),
      monthly: _intOrNull(j['monthly']),
      total: _int(j['total']),
      paid: _int(j['paid']),
      outstanding: _int(j['outstanding']),
      createdAt: _date(j['created_at']),
      nextDue: NextDue.fromJson(j['next_due']),
      orderId: _str(j['order_id']),
      paidMonths: _int(j['paid_months']),
      seller: SellerContact.fromJson(j['seller']),
      schedule: _list(j['schedule'], Installment.fromJson),
    );
  }
}

class TimelineStep {
  const TimelineStep({required this.status, required this.label, required this.done, required this.at});

  final String status;
  final String label;
  final bool done;
  final DateTime? at;

  factory TimelineStep.fromJson(Map<String, dynamic> j) =>
      TimelineStep(status: _str(j['status']), label: _str(j['label']), done: j['done'] == true, at: _date(j['at']));
}

class OrderDetail {
  const OrderDetail({
    required this.card,
    required this.city,
    required this.area,
    required this.address,
    required this.timeline,
    required this.atompayUrl,
    this.cashPrice,
  });

  final OrderCard card;

  /// Product (or storage) cash price when ordered; null until the server sends it.
  final int? cashPrice;
  final String city;
  final String area;
  final String address;
  final List<TimelineStep> timeline;
  final String atompayUrl;

  String get deliveryLine => [address, area, city].where((s) => s.isNotEmpty).join(', ');

  factory OrderDetail.fromJson(Map<String, dynamic> j) {
    final d = _map(j['delivery']);
    return OrderDetail(
      card: OrderCard.fromJson(j),
      city: _str(d['city']),
      area: _str(d['area']),
      address: _str(d['address']),
      timeline: _list(j['timeline'], TimelineStep.fromJson),
      atompayUrl: _str(j['atompay_url']),
      cashPrice: _intOrNull(j['cash_price']),
    );
  }
}

class OrdersPage {
  const OrdersPage(this.orders, this.nextPage);

  final List<OrderCard> orders;
  final int? nextPage;
}

class InstallmentsOverview {
  const InstallmentsOverview({required this.outstanding, required this.paid, required this.activePlans, required this.nextDue, required this.plans});

  final int outstanding;
  final int paid;
  final int activePlans;
  final NextDue? nextDue;
  final List<OrderCard> plans;

  factory InstallmentsOverview.fromJson(Map<String, dynamic> j) {
    final s = _map(j['summary']);
    return InstallmentsOverview(
      outstanding: _int(s['outstanding']),
      paid: _int(s['paid']),
      activePlans: _int(s['active_plans']),
      nextDue: NextDue.fromJson(s['next_due']),
      plans: _list(j['plans'], OrderCard.fromJson),
    );
  }
}

class Payment {
  const Payment({
    required this.id,
    required this.orderUuid,
    required this.orderId,
    required this.product,
    required this.label,
    required this.amount,
    required this.paidAt,
    required this.method,
    required this.receiptUrl,
  });

  final int id;
  final String orderUuid;
  final String orderId;
  final String product;
  final String label;
  final int amount;
  final DateTime? paidAt;
  final String method;
  final String receiptUrl;

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: _int(j['id']),
        orderUuid: _str(j['order_uuid']),
        orderId: _str(j['order_id']),
        product: _str(j['product']),
        label: _str(j['label']),
        amount: _int(j['amount']),
        paidAt: _date(j['paid_at']),
        method: _str(j['method']),
        receiptUrl: _str(j['receipt_url']),
      );
}

class PaymentsPage {
  const PaymentsPage({
    required this.paid,
    required this.advance,
    required this.monthly,
    required this.outstanding,
    required this.byMethod,
    required this.orders,
    required this.payments,
    required this.nextPage,
  });

  final int paid;
  final int advance;
  final int monthly;
  final int outstanding;

  /// (method, amount, percent).
  final List<(String, int, int)> byMethod;

  /// (order uuid, chip label).
  final List<(String, String)> orders;
  final List<Payment> payments;
  final int? nextPage;

  factory PaymentsPage.fromJson(Map<String, dynamic> j) {
    final s = _map(j['summary']);
    return PaymentsPage(
      paid: _int(s['paid']),
      advance: _int(s['advance']),
      monthly: _int(s['monthly']),
      outstanding: _int(s['outstanding']),
      byMethod: [for (final m in atomList(j['by_method'])) (_str(m['method']), _int(m['amount']), _int(m['percent']))],
      orders: [for (final o in atomList(j['orders'])) (_str(o['uuid']), _str(o['label']))],
      payments: _list(j['payments'], Payment.fromJson),
      nextPage: _intOrNull(j['next_page']),
    );
  }
}

class Receipt {
  const Receipt({
    required this.payment,
    required this.receiptNo,
    required this.customer,
    required this.storage,
    required this.dueDate,
    required this.receivedBy,
    required this.pdfUrl,
  });

  final Payment payment;
  final String receiptNo;
  final String customer;
  final String storage;
  final DateTime? dueDate;
  final String receivedBy;
  final String pdfUrl;

  factory Receipt.fromJson(Map<String, dynamic> j) => Receipt(
        payment: Payment.fromJson(j),
        receiptNo: _str(j['receipt_no']),
        customer: _str(j['customer']),
        storage: _str(j['storage']),
        dueDate: _date(j['due_date']),
        receivedBy: _str(j['received_by']),
        pdfUrl: _str(j['pdf_url']),
      );
}

// ── Custom orders and offers ──────────────────────────────────────────────

class CustomQuote {
  const CustomQuote({
    required this.price,
    required this.advance,
    required this.minAdvance,
    required this.financed,
    required this.markup,
    required this.sourcingFee,
    required this.sourcingFeePercent,
    required this.total,
    required this.monthly,
    required this.months,
    required this.referenceValid,
    required this.referenceMessage,
  });

  final int price;
  final int advance;
  final int minAdvance;
  final int financed;
  final int markup;
  final int sourcingFee;
  final num sourcingFeePercent;
  final int total;
  final int monthly;
  final int months;
  final bool? referenceValid;
  final String referenceMessage;

  factory CustomQuote.fromJson(Map<String, dynamic> j) {
    final r = _map(j['reference']);
    return CustomQuote(
      price: _int(j['price']),
      advance: _int(j['advance']),
      minAdvance: _int(j['min_advance']),
      financed: _int(j['financed']),
      markup: _int(j['markup']),
      sourcingFee: _int(j['sourcing_fee']),
      sourcingFeePercent: (j['sourcing_fee_percent'] as num?) ?? 1,
      total: _int(j['total']),
      monthly: _int(j['monthly']),
      months: _int(j['months']),
      referenceValid: r.isEmpty ? null : r['valid'] == true,
      referenceMessage: _str(r['message']),
    );
  }
}

class CustomOrderPlaced {
  const CustomOrderPlaced({required this.orderId, required this.product, required this.monthly, required this.months, required this.advance, required this.total, required this.area});

  final String orderId;
  final String product;
  final int monthly;
  final int months;
  final int advance;
  final int total;
  final String area;

  factory CustomOrderPlaced.fromJson(Map<String, dynamic> j) => CustomOrderPlaced(
        orderId: _str(j['order_id']),
        product: _str(j['product']),
        monthly: _int(j['monthly']),
        months: _int(j['months']),
        advance: _int(j['advance']),
        total: _int(j['total']),
        area: _str(j['area']),
      );
}

class CustomOrderRow {
  const CustomOrderRow({required this.uuid, required this.orderId, required this.product, required this.price, required this.monthly, required this.months, required this.status, required this.statusLabel, required this.createdAt});

  final String uuid;
  final String orderId;
  final String product;
  final int price;
  final int monthly;
  final int months;
  final String status;
  final String statusLabel;
  final DateTime? createdAt;

  factory CustomOrderRow.fromJson(Map<String, dynamic> j) => CustomOrderRow(
        uuid: _str(j['uuid']),
        orderId: _str(j['order_id']),
        product: _str(j['product']),
        price: _int(j['price']),
        monthly: _int(j['monthly']),
        months: _int(j['months']),
        status: _str(j['status']),
        statusLabel: _label(j),
        createdAt: _date(j['created_at']),
      );
}

class OfferRow {
  const OfferRow({required this.uuid, required this.product, required this.area, required this.statusLabel, required this.note, required this.createdAt});

  final String uuid;
  final String product;
  final String area;
  final String statusLabel;
  final String note;
  final DateTime? createdAt;

  factory OfferRow.fromJson(Map<String, dynamic> j) => OfferRow(
        uuid: _str(j['uuid']),
        product: _str(j['product']),
        area: _str(j['area']),
        statusLabel: _label(j),
        note: _str(j['note']),
        createdAt: _date(j['created_at']),
      );
}

// ── Ask Atom ──────────────────────────────────────────────────────────────

class AskAtomPlan {
  const AskAtomPlan({required this.productId, required this.product, required this.price, required this.advance, required this.months, required this.monthly, required this.total});

  final int? productId;
  final String product;
  final int price;
  final int advance;
  final int months;
  final int monthly;
  final int total;

  static AskAtomPlan? fromJson(Object? v) {
    final j = _map(v);
    if (j.isEmpty) return null;
    return AskAtomPlan(
      productId: _intOrNull(j['product_id']),
      product: _str(j['product']),
      price: _int(j['price']),
      advance: _int(j['advance']),
      months: _int(j['months']),
      monthly: _int(j['monthly']),
      total: _int(j['total']),
    );
  }
}

/// A button under an answer. The server sends a label and a website link;
/// [type] says where the app opens it: category (with [id]), whatsapp,
/// custom_order, offer, or url (opened in the browser).
class AskAtomAction {
  const AskAtomAction({required this.label, required this.type, required this.id, required this.url});

  final String label;
  final String type;
  final int? id;
  final String url;

  factory AskAtomAction.fromJson(Map<String, dynamic> j) {
    final url = _str(j['url']);
    final sent = _str(j['type']);
    final (type, id) = sent.isNotEmpty ? (sent, _intOrNull(j['id'])) : _route(url);
    return AskAtomAction(label: _str(j['label']), type: type, id: id, url: url);
  }

  /// Website link → app screen, where the app has one.
  static (String, int?) _route(String url) {
    final u = Uri.tryParse(url);
    final path = (u?.path ?? '').toLowerCase();
    final host = (u?.host ?? '').toLowerCase();
    if (host.contains('wa.me') || host.contains('whatsapp')) return ('whatsapp', null);
    if (path.contains('custom-order')) return ('custom_order', null);
    if (path.contains('make-offer') || path.contains('make-an-offer')) return ('offer', null);
    final segments = (u?.pathSegments ?? const <String>[]).where((s) => s.isNotEmpty && s != 'public').toList();
    final onSite = host.isEmpty || host.endsWith('atomshop.pk');
    if (onSite && (path.contains('installment-calculator') || path.contains('instalment-calculator'))) return ('shop', null);
    if (onSite && segments.length == 1 && segments.first == 'shop') return ('shop', null);
    if (onSite && segments.length == 1 && segments.first == 'faqs') return ('faqs', null);
    final i = segments.indexOf('category');
    if (i >= 0 && i + 1 < segments.length) {
      final slug = segments[i + 1].toLowerCase();
      for (final c in designCategories) {
        if (c.slug.toLowerCase() == slug) return ('category', c.id);
      }
    }
    // atomshop.pk/{product-slug}: the app finds it by name.
    const pages = {'about-us', 'contact-us', 'privacy-policy', 'return-refund-policy', 'apps', 'smart-seller', 'brand-partners', 'blog', 'login', 'register', 'delete-account'};
    if (onSite && host.isNotEmpty && segments.length == 1 && !pages.contains(segments.first)) return ('search', null);
    return ('url', null);
  }

  /// "apple-iphone-17-pro" → "apple iphone 17 pro", for [type] search.
  String get searchText {
    final last = (Uri.tryParse(url)?.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? '').replaceAll(RegExp(r'[-_]+'), ' ').trim();
    return last.isNotEmpty ? last : label;
  }
}

class AskAtomReply {
  const AskAtomReply({required this.answer, required this.plan, required this.actions, required this.relatedTitle, required this.related, required this.session});

  /// Plain text; one answer line per line, bold marked as **…**.
  final String answer;
  final AskAtomPlan? plan;
  final List<AskAtomAction> actions;

  /// "People also ask"-style follow-ups; tapping one asks it.
  final String relatedTitle;
  final List<String> related;

  /// Server-signed id for an anonymous visitor's limits; send it back.
  final String session;

  factory AskAtomReply.fromJson(Map<String, dynamic> j) {
    final related = _map(j['related']);
    final text = _str(j['text']).trim();
    return AskAtomReply(
      answer: text.isNotEmpty ? text : _str(j['answer']).replaceAll(RegExp(r'<[^>]*>'), '').trim(),
      plan: AskAtomPlan.fromJson(j['plan']),
      actions: _list(j['actions'], AskAtomAction.fromJson),
      relatedTitle: _str(related['title']),
      related: (related['questions'] is List ? related['questions'] as List : const []).map(_str).where((q) => q.isNotEmpty).toList(growable: false),
      session: _str(j['session']),
    );
  }
}

class AskAtomSuggestion {
  const AskAtomSuggestion({required this.id, required this.label, required this.prompt});

  final int id;
  final String label;
  final String prompt;

  factory AskAtomSuggestion.fromJson(Map<String, dynamic> j) =>
      AskAtomSuggestion(id: _int(j['id']), label: _str(j['label']), prompt: _str(j['prompt']).isEmpty ? _str(j['label']) : _str(j['prompt']));
}

// ── Content pages ─────────────────────────────────────────────────────────

class PageSection {
  const PageSection({required this.heading, required this.paragraphs, required this.bullets});

  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;

  factory PageSection.fromJson(Map<String, dynamic> j) => PageSection(
        heading: _str(j['heading']),
        paragraphs: (j['paragraphs'] is List ? j['paragraphs'] as List : const []).map(_str).toList(growable: false),
        bullets: (j['bullets'] is List ? j['bullets'] as List : const []).map(_str).toList(growable: false),
      );
}

class FaqGroup {
  const FaqGroup(this.title, this.items);

  final String title;

  /// (question, answer).
  final List<(String, String)> items;
}

class PageContent {
  const PageContent({required this.title, required this.updatedAt, required this.intro, required this.sections, required this.faqGroups, required this.url});

  final String title;
  final DateTime? updatedAt;
  final String intro;
  final List<PageSection> sections;
  final List<FaqGroup> faqGroups;

  /// The same page on the website.
  final String url;

  factory PageContent.fromJson(Map<String, dynamic> j) => PageContent(
        title: _str(j['title']),
        updatedAt: _date(j['updated_at']),
        intro: _str(j['intro']),
        sections: _list(j['sections'], PageSection.fromJson),
        faqGroups: [
          for (final g in atomList(j['faq_groups'])) FaqGroup(_str(g['title']), [for (final i in atomList(g['items'])) (_str(i['q']), _str(i['a']))]),
        ],
        url: _str(j['url']),
      );
}

// ── Notifications (existing API, token-scoped) ────────────────────────────

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.screen,
    required this.orderId,
    required this.read,
    required this.createdAt,
    this.orderUuid = '',
    this.paymentId,
  });

  final int id;

  /// account_verified, order_status, instalment_paid, deal_closed, …
  final String type;
  final String title;
  final String body;

  /// Where a tap goes: profile, orders, instalments, …
  final String screen;
  final String orderId;
  final bool read;
  final DateTime? createdAt;

  /// The order a tap opens (api/app/orders/{uuid}), when the server sends it.
  final String orderUuid;

  /// The paid installment whose receipt a tap opens.
  final int? paymentId;

  AppNotification markedRead() => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        screen: screen,
        orderId: orderId,
        read: true,
        createdAt: createdAt,
        orderUuid: orderUuid,
        paymentId: paymentId,
      );

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    final data = _map(j['data']);
    return AppNotification(
      id: _int(j['id']),
      type: _str(j['type']),
      title: _str(j['title']),
      body: _str(j['body']),
      screen: _str(j['screen'] ?? data['screen']),
      orderId: _str(j['order_id'] ?? data['order_id']),
      read: j['is_read'] == true,
      createdAt: _date(j['created_at']),
      orderUuid: _str(j['order_uuid'] ?? data['order_uuid']),
      paymentId: _intOrNull(j['payment_id'] ?? data['payment_id']),
    );
  }
}

class NotificationsPage {
  const NotificationsPage(this.items, this.unread, this.nextPage);

  final List<AppNotification> items;
  final int unread;
  final int? nextPage;
}

// ── API ───────────────────────────────────────────────────────────────────

class AtomAccountApi {
  const AtomAccountApi(this._http);

  final AtomHttp _http;

  // Orders, installments, payments and the summary come from the existing
  // `account/my-orders`, `account/payment-history` endpoints (owner,
  // 2026-10-29: use these until `api/app/*` is built). Each figure shown is
  // a server amount or a sum of the server's own installment rows; the app
  // never works out markup.

  /// One `my-orders` answer shared by the screens that open together
  /// (Account, Overview, Installments) for a few seconds.
  static Future<Map<String, dynamic>>? _ordersCall;
  static DateTime _ordersAt = DateTime(2000);
  static String _ordersToken = '';

  Future<Map<String, dynamic>> _myOrders() async {
    final token = await SessionManager.getToken() ?? '';
    final fresh = DateTime.now().difference(_ordersAt) < const Duration(seconds: 15) && token == _ordersToken;
    final cached = _ordersCall;
    if (cached != null && fresh) return cached;
    _ordersToken = token;
    _ordersAt = DateTime.now();
    final call = _http.post('account/my-orders').then(_map);
    _ordersCall = call;
    try {
      return await call;
    } catch (_) {
      _ordersCall = null;
      rethrow;
    }
  }

  /// Drops the shared `my-orders` answer (after placing an order).
  static void forgetOrders() => _ordersCall = null;

  Future<List<_OldOrder>> _orders() async {
    final j = await _myOrders();
    final orders = [for (final o in atomList(j['orders'])) _OldOrder(o)];
    orders.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return orders;
  }

  Future<AccountSummary> summary() async {
    final j = await _myOrders();
    final orders = await _orders();
    final customer = _map(j['customer']);
    final dues = [for (final o in orders) ?o.nextDue]..sort(_byDate);
    var unread = 0;
    try {
      unread = (await notifications()).unread;
    } on AtomApiException {
      // The bell shows its own count; a missing number is not an error here.
    }
    return AccountSummary.fromJson({
      'stats': {
        'orders': orders.length,
        'active_plans': orders.where((o) => o.isActivePlan).length,
        'paid': orders.fold<int>(0, (n, o) => n + o.paid),
        'unpaid': orders.where((o) => o.isActivePlan).fold<int>(0, (n, o) => n + o.outstanding),
      },
      'next_due': dues.isEmpty ? null : dues.first,
      'verification': {
        'verified': '${customer['verified']}' == '1' || customer['verified'] == true,
        'cnic_masked': _maskCnic(_str(customer['cnic_no'])),
      },
      'atompay': const {'state': 'none'},
      'unread_notifications': unread,
    });
  }

  /// [status]: all, active, completed.
  Future<OrdersPage> orders({String status = 'all', int page = 1}) async {
    final all = await _orders();
    final shown = switch (status) {
      'active' => all.where((o) => o.isActive),
      'completed' => all.where((o) => o.isCompleted),
      _ => all,
    };
    return OrdersPage([for (final o in shown) OrderCard.fromJson(o.card())], null);
  }

  Future<OrderDetail> order(String uuid) async {
    final j = await _myOrders();
    final o = (await _orders()).where((o) => o.uuid == uuid).firstOrNull;
    if (o == null) throw const AtomApiException('We could not find this order.', statusCode: 404);
    final c = _map(j['customer']);
    return OrderDetail.fromJson({
      ...o.card(),
      'delivery': {'city': _str(c['city']), 'area': _str(c['area']), 'address': _str(c['address'])},
      'cash_price': o.cashPrice,
    });
  }

  /// [tab]: active, pending, completed.
  Future<InstallmentsOverview> installments(String tab) async {
    final all = await _orders();
    final plans = switch (tab) {
      'pending' => all.where((o) => o.isPending),
      'completed' => all.where((o) => o.isCompleted || (o.isActivePlan && o.outstanding == 0 && o.schedule.isNotEmpty)),
      _ => all.where((o) => o.isActivePlan && o.outstanding > 0),
    }.toList();
    final dues = [for (final o in all) ?o.nextDue]..sort(_byDate);
    return InstallmentsOverview.fromJson({
      'summary': {
        'outstanding': all.where((o) => o.isActivePlan).fold<int>(0, (n, o) => n + o.outstanding),
        'paid': all.fold<int>(0, (n, o) => n + o.paid),
        'active_plans': all.where((o) => o.isActivePlan).length,
        'next_due': dues.isEmpty ? null : dues.first,
      },
      'plans': [for (final o in plans) o.card()],
    });
  }

  /// Paid installments (`payment-history`), each matched to its order
  /// through the installment rows in `my-orders`.
  Future<List<Map<String, dynamic>>> _payments() async {
    final uuid = await SessionManager.getUserUuid() ?? '';
    final rows = atomList(await _http.post('account/payment-history', {'uuid': uuid}));
    final orders = await _orders();
    final byRow = <int, (_OldOrder, Map<String, dynamic>)>{
      for (final o in orders)
        for (final r in o.rows)
          if (_intOrNull(r['id']) != null) _int(r['id']): (o, r),
    };
    final out = <Map<String, dynamic>>[];
    for (final p in rows) {
      final id = _int(p['id']);
      final match = byRow[id];
      final receipt = _str(p['receipet']);
      out.add({
        'id': id,
        'order_uuid': match?.$1.uuid ?? '',
        'order_id': match?.$1.orderId ?? '',
        'product': match?.$1.product ?? '',
        'label': match == null ? 'Payment' : _str(match.$2['month']),
        'amount': _int(p['installment_price']),
        'paid_at': _monthDayYear(_str(p['payment_date']))?.toIso8601String(),
        'method': _str(p['payment_method']) == '-' ? '' : _str(p['payment_method']),
        'receipt_url': receipt == '-' ? '' : receipt,
        'due_date': match == null ? null : _str(match.$2['installment_date']),
      });
    }
    out.sort((a, b) => _str(b['paid_at']).compareTo(_str(a['paid_at'])));
    return out;
  }

  Future<PaymentsPage> payments({String? orderUuid, int page = 1}) async {
    final all = await _payments();
    final shown = orderUuid == null ? all : all.where((p) => p['order_uuid'] == orderUuid).toList();
    final paid = shown.fold<int>(0, (n, p) => n + _int(p['amount']));
    final advance = shown.where((p) => _str(p['label']).toLowerCase().contains('advance')).fold<int>(0, (n, p) => n + _int(p['amount']));
    final byMethod = <String, int>{};
    for (final p in shown) {
      final m = _str(p['method']).isEmpty ? 'Other' : _str(p['method']);
      byMethod[m] = (byMethod[m] ?? 0) + _int(p['amount']);
    }
    final orders = await _orders();
    final scoped = orderUuid == null ? orders : orders.where((o) => o.uuid == orderUuid);
    return PaymentsPage.fromJson({
      'summary': {
        'paid': paid,
        'advance': advance,
        'monthly': paid - advance,
        'outstanding': scoped.where((o) => o.isActivePlan).fold<int>(0, (n, o) => n + o.outstanding),
      },
      'by_method': [
        for (final e in byMethod.entries) {'method': e.key, 'amount': e.value, 'percent': paid == 0 ? 0 : (e.value * 100 / paid).round()},
      ],
      'orders': [
        for (final o in orders)
          if (all.any((p) => p['order_uuid'] == o.uuid)) {'uuid': o.uuid, 'label': o.product},
      ],
      'payments': shown,
    });
  }

  Future<Receipt> receipt(int id) async {
    final p = (await _payments()).where((p) => p['id'] == id).firstOrNull;
    if (p == null) throw const AtomApiException('We could not find this receipt.', statusCode: 404);
    return Receipt.fromJson({
      ...p,
      'receipt_no': '$id',
      'customer': await SessionManager.getUserName() ?? '',
      'pdf_url': p['receipt_url'],
    });
  }

  /// The receipt file the office uploaded (image or PDF), when there is one.
  Future<List<int>> receiptPdf(int id) async {
    final url = (await receipt(id)).pdfUrl;
    if (url.isEmpty) throw const AtomApiException('There is no receipt file for this payment yet.', statusCode: 404);
    return _http.bytes(url);
  }

  /// No quote endpoint on the server yet, and the app never works out
  /// markup: this only checks the inputs. The server works out the plan
  /// when the order is sent ([placeCustomOrder]).
  Future<CustomQuote> customQuote({required int price, required int advance, required int months, String referenceCode = '', int minAdvancePercent = 20}) async {
    final minAdvance = (price * minAdvancePercent / 100).ceil();
    if (advance < minAdvance) {
      throw AtomApiException('Validation Error.', statusCode: 422, data: {
        'advance': ['The advance must be at least $minAdvancePercent% of the price (${AtomFormat.rupees(minAdvance)}).'],
      });
    }
    if (advance >= price) {
      throw const AtomApiException('Validation Error.', statusCode: 422, data: {
        'advance': ['The advance must be less than the price.'],
      });
    }
    return CustomQuote(
      price: price,
      advance: advance,
      minAdvance: minAdvance,
      financed: price - advance,
      markup: 0,
      sourcingFee: 0,
      sourcingFeePercent: 1,
      total: 0,
      monthly: 0,
      months: months,
      referenceValid: null,
      referenceMessage: '',
    );
  }

  /// Whether the server quotes a custom order before it is sent.
  static const hasCustomQuote = false;

  /// Photos and links are not taken by `custom-order-calculator/store`.
  static const customOrderTakesExtras = false;

  /// `custom-order-calculator/store`: the server works out the deal and
  /// returns the order. Signed in, the order goes on the account (the
  /// server checks the uuid against the token).
  Future<CustomOrderPlaced> placeCustomOrder(Map<String, dynamic> fields, {List<String> photos = const []}) async {
    final uuid = await SessionManager.getUserUuid() ?? '';
    final token = await SessionManager.getToken() ?? '';
    final o = _map(await _http.post('custom-order-calculator/store', {
      if (uuid.isNotEmpty && token.isNotEmpty) 'uuid': uuid,
      'name': fields['full_name'],
      'phone': fields['phone'],
      'email': ?fields['email'],
      'city_id': fields['city_id'],
      'area_id': fields['area_id'],
      'address': fields['address'],
      'product_title': fields['product_title'],
      'product_price': fields['price'],
      'advance_price': fields['advance'],
      'tenure_months': fields['months'],
      if (_str(fields['reference_code']).isNotEmpty) 'supplier_reference_code_val': fields['reference_code'],
    }));
    forgetOrders();
    final total = _int(o['total_deal_price']);
    final advance = _int(o['advance_price']);
    final months = _int(o['tenure'], _int(fields['months']));
    return CustomOrderPlaced(
      orderId: _str(o['id']),
      product: _str(fields['product_title']),
      // The rest after the advance in equal months, as the server's plan is.
      monthly: months > 0 ? ((total - advance) / months).round() : 0,
      months: months,
      advance: advance,
      total: total,
      area: '',
    );
  }

  /// Orders without a catalogue picture are custom orders (product orders
  /// keep the product's picture); the old API has no other marker.
  Future<List<CustomOrderRow>> customOrders() async => [
        for (final o in await _orders())
          if (o.isCustom)
            CustomOrderRow(
              uuid: o.uuid,
              orderId: o.orderId,
              product: o.product,
              price: o.cashPrice ?? 0,
              monthly: o.monthly ?? 0,
              months: o.months,
              status: o.status,
              statusLabel: o.statusLabel,
              createdAt: o.createdAt,
            ),
      ];

  /// No list of a customer's offers on the server; they are answered on
  /// WhatsApp. The screen says so instead of showing an error.
  static const offersListed = false;

  Future<List<OfferRow>> offers() async => const [];

  /// Make an offer (`leads/create`, works for guests). Returns nothing the
  /// app needs to show beyond success.
  Future<void> makeOffer({
    required String fullName,
    required String phone,
    required int cityId,
    required int? areaId,
    required String product,
    required bool onWhatsApp,
    List<String> photos = const [],
  }) async {
    final fields = <String, dynamic>{
      'full_name': fullName,
      'contact_number': phone,
      'city_id': cityId,
      'area_id': ?areaId,
      'product': product,
      'available_on_whatsapp': onWhatsApp ? 1 : 0,
    };
    if (photos.isEmpty) {
      await _http.post('leads/create', fields);
    } else {
      await _http.postFiles('leads/create', fields, {'product_images[]': photos});
    }
  }

  Future<List<AskAtomSuggestion>> askAtomSuggestions() async => _list(await _http.get('ask-atom/suggestions'), AskAtomSuggestion.fromJson);

  static const _askSessionKey = 'ask_atom_session';

  /// POST api/app/ask-atom. Guests are counted by the session id the server
  /// issued on their first question (kept on the phone); a signed-in
  /// customer's token counts them as themselves.
  Future<AskAtomReply> askAtom({required String question, required List<(bool, String)> history, int? suggestionId}) async {
    const storage = FlutterSecureStorage();
    final session = await storage.read(key: _askSessionKey);
    final reply = AskAtomReply.fromJson(_map(await _http.post('app/ask-atom', {
      'question': question,
      if (session != null && session.isNotEmpty) 'session': session,
      'suggestion_id': ?suggestionId,
      'history': [
        for (final (fromUser, text) in history) {'role': fromUser ? 'user' : 'bot', 'text': text},
      ],
    })));
    if (reply.session.isNotEmpty && reply.session != session) await storage.write(key: _askSessionKey, value: reply.session);
    return reply;
  }

  /// about, why, faqs, privacy, refund, app-privacy.
  Future<PageContent> page(String slug) async => PageContent.fromJson(_map(await _http.get('app/pages/$slug')));

  Future<void> contact({required String name, required String phone, required String subject, required String message}) =>
      _http.post('app/contact', {'name': name, 'phone': phone, 'subject': subject, 'message': message});

  Future<NotificationsPage> notifications({int page = 1}) async {
    final j = _map(await _http.get('notifications', query: {'page': page}));
    final p = _map(j['notifications']);
    final current = _int(p['current_page'], 1);
    final last = _int(p['last_page'], 1);
    return NotificationsPage(_list(p['data'], AppNotification.fromJson), _int(j['unread_count']), current < last ? current + 1 : null);
  }

  Future<void> markNotificationRead(int id) => _http.post('notifications/$id/read');

  Future<void> markAllNotificationsRead() => _http.post('notifications/read-all');
}

final atomAccountApiProvider = Provider<AtomAccountApi>((ref) => AtomAccountApi(ref.watch(atomHttpProvider)));

// ── Orders from `account/my-orders` ───────────────────────────────────────

int _byDate(Map<String, dynamic> a, Map<String, dynamic> b) => _str(a['date']).compareTo(_str(b['date']));

/// "Oct 28, 2026".
DateTime? _monthDayYear(String s) {
  final m = RegExp(r'^([A-Za-z]{3}) (\d{1,2}), (\d{4})$').firstMatch(s.trim());
  if (m == null) return DateTime.tryParse(s);
  const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
  final month = months.indexOf(m.group(1)!.toLowerCase()) + 1;
  return month == 0 ? null : DateTime(int.parse(m.group(3)!), month, int.parse(m.group(2)!));
}

/// "35202-•••••••-1" from a stored CNIC.
String _maskCnic(String cnic) {
  final d = cnic.replaceAll(RegExp(r'\D'), '');
  return d.length == 13 ? '${d.substring(0, 5)}-•••••••-${d.substring(12)}' : '';
}

/// One order as `my-orders` sends it, read the way the app's cards want it.
class _OldOrder {
  _OldOrder(Map<String, dynamic> j)
      : uuid = _str(j['uuid']),
        orderId = _str(j['id']),
        status = _str(j['status']),
        createdAt = DateTime.tryParse(_str(j['created_at']).replaceFirst(' ', 'T')),
        product = _str(_map(j['product'])['title']),
        picture = _str(_map(j['product'])['picture']),
        cashPrice = _intOrNull(_map(j['product'])['price']),
        months = _int(j['tenure']),
        advanceAmount = _int(j['advance_price']),
        total = _int(j['total_deal_price']),
        rows = _realRows(j),
        seller = _map(j['seller']).isNotEmpty ? _map(j['seller']) : _map(j['supplier']);

  /// The order's installment rows. Before delivery the old endpoint makes
  /// rows up (no id) with its own markup formula, which can disagree with
  /// the order's total (an AtomPay order is 0% markup); those are replaced by
  /// the total after the advance in equal months, the remainder in the last
  /// month, as the product page shows the same plan.
  static List<Map<String, dynamic>> _realRows(Map<String, dynamic> j) {
    final rows = [for (final r in atomList(j['installments'])) Map<String, dynamic>.from(r)];
    if (rows.isEmpty || rows.any((r) => r['id'] != null)) return rows;
    final months = _int(j['tenure']);
    final rest = _int(j['total_deal_price']) - _int(j['advance_price']);
    if (months <= 0 || rest <= 0) return rows;
    final each = rest ~/ months;
    return [
      for (var i = 0; i < months; i++)
        {...rows[i < rows.length ? i : rows.length - 1], 'installment_price': i == months - 1 ? rest - each * (months - 1) : each, 'installment_paid_price': 0},
    ];
  }

  final String uuid;
  final String orderId;
  final String status;
  final DateTime? createdAt;
  final String product;
  final String picture;
  final int? cashPrice;
  final int months;
  final int advanceAmount;
  final int total;
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> seller;

  String get _s => status.toLowerCase();
  String get statusLabel => status == 'Varification' ? 'Verification' : status;
  bool get isCancelled => _s == 'cancelled' || _s == 'canceled' || _s == 'rejected';
  bool get isCompleted => _s == 'completed';
  bool get isClosed => isCancelled || isCompleted;
  bool get isPending => _s == 'pending' || _s == 'varification' || _s == 'verification';
  bool get isActive => !isClosed;
  bool get isActivePlan => !isClosed && !isPending;

  /// asset(null) on the server gives a URL with no file name.
  bool get isCustom {
    final last = Uri.tryParse(picture)?.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? '';
    return !last.contains('.');
  }

  bool _isAdvance(Map<String, dynamic> r) => _str(r['month']).toLowerCase().contains('advance');
  bool _isPaid(Map<String, dynamic> r) => _str(r['status']).toLowerCase() == 'paid';

  List<Map<String, dynamic>> get schedule => [
        for (final r in rows)
          {
            'id': r['id'],
            'label': _str(r['month']),
            'amount': _int(r['installment_price']),
            'paid_amount': _int(r['installment_paid_price']),
            'due_date': _str(r['installment_date']),
            'status': _status(r),
            'method': _str(r['payment_method']),
          },
      ];

  String _status(Map<String, dynamic> r) {
    if (_isPaid(r)) return 'paid';
    final due = DateTime.tryParse(_str(r['installment_date']));
    return due != null && due.isBefore(DateTime.now()) && !isPending ? 'overdue' : 'unpaid';
  }

  /// A paid row counts its full amount, as its receipt in Payment history
  /// does; an unpaid row counts any part already paid.
  int get paid => rows.fold<int>(0, (n, r) => n + (_isPaid(r) ? _int(r['installment_price']) : _int(r['installment_paid_price'])));

  /// What is still owed on the plan: the unpaid part of each server row.
  int get outstanding => rows.where((r) => !_isPaid(r)).fold<int>(0, (n, r) => n + (_int(r['installment_price']) - _int(r['installment_paid_price'])).clamp(0, 1 << 31));

  int? get monthly => rows.where((r) => !_isAdvance(r)).map((r) => _int(r['installment_price'])).firstOrNull;

  int get paidMonths => rows.where((r) => !_isAdvance(r) && _isPaid(r)).length;

  Map<String, dynamic>? get nextDue {
    if (isClosed || isPending) return null;
    final unpaid = rows.where((r) => !_isPaid(r) && !_isAdvance(r)).toList()
      ..sort((a, b) => _str(a['installment_date']).compareTo(_str(b['installment_date'])));
    if (unpaid.isEmpty) return null;
    final r = unpaid.first;
    return {
      'amount': _int(r['installment_price']) - _int(r['installment_paid_price']),
      'date': _str(r['installment_date']).isEmpty ? null : _str(r['installment_date']),
      'label': _str(r['month']),
      'order_uuid': uuid,
      'product': product,
    };
  }

  Map<String, dynamic> card() => {
        'uuid': uuid,
        'kind': isCustom ? 'custom' : 'product',
        'status': status,
        'status_label': statusLabel,
        'product': {'title': product, 'picture_url': isCustom ? '' : picture},
        'months': months,
        'advance': advanceAmount,
        'monthly': monthly,
        'total': total,
        'paid': paid,
        'outstanding': outstanding,
        'created_at': createdAt?.toIso8601String(),
        'next_due': nextDue,
        'order_id': orderId,
        'paid_months': paidMonths,
        'seller': seller.isEmpty ? null : seller,
        'schedule': schedule,
      };
}
