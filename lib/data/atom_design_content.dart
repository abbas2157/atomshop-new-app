import 'package:flutter/material.dart';

import 'atom_models.dart';

/// Home slider and categories exactly as in the design (canvas "Atomshop
/// App Redesign", Home and Categories). Fixed in the app for now (owner,
/// 2026-10-28); brands and products still come from the server.
///
/// Each category carries the server's category id so its product list
/// (GET api/products/category/{id}) loads the live products.

enum SlideAction { shop, why }

class DesignSlide {
  const DesignSlide({
    required this.asset,
    required this.alt,
    required this.alignment,
    required this.eyebrow,
    required this.title,
    required this.cta,
    required this.icon,
    required this.action,
  });

  final String asset;
  final String alt;

  /// Keeps the people on the right in view (design: object-position).
  final Alignment alignment;
  final String eyebrow;
  final String title;
  final String cta;
  final IconData icon;
  final SlideAction action;
}

const designSlides = [
  DesignSlide(
    asset: 'assets/images/slide-pay-in-steps.jpg',
    alt: 'A seller showing a customer an installment plan on a tablet',
    alignment: Alignment(0.56, -0.2),
    eyebrow: 'Pay in steps',
    title: 'Shop now, pay in easy monthly installments',
    cta: 'Start shopping',
    icon: Icons.shopping_bag_outlined,
    action: SlideAction.shop,
  ),
  DesignSlide(
    asset: 'assets/images/slide-verified-sellers.jpg',
    alt: 'Atomshop partners reviewing orders on a tablet',
    alignment: Alignment(0.48, -0.2),
    eyebrow: 'Verified sellers and brands',
    title: 'One platform, people you can reach',
    cta: 'Why Atomshop',
    icon: Icons.verified_user_outlined,
    action: SlideAction.why,
  ),
];

class DesignCategory {
  const DesignCategory({required this.id, required this.shortLabel, required this.label, required this.slug, required this.icon});

  /// Server category id (atomshop.pk categories table).
  final int id;

  /// Home grid label ("Mobiles").
  final String shortLabel;

  /// Shop tab and list title ("Mobile phones").
  final String label;
  final String slug;
  final IconData icon;

  /// What the category product list screen opens with.
  CatalogueItem get item => CatalogueItem(id: id, title: label, slug: slug, picture: '');
}

/// In the design's order.
const designCategories = [
  DesignCategory(id: 1, shortLabel: 'Mobiles', label: 'Mobile phones', slug: 'mobile-phone', icon: Icons.phone_iphone_outlined),
  DesignCategory(id: 14, shortLabel: 'Appliances', label: 'Home appliances', slug: 'home-appliances', icon: Icons.kitchen_outlined),
  DesignCategory(id: 4, shortLabel: 'Smart TVs', label: 'Smart TVs', slug: 'Smart-tv', icon: Icons.tv_outlined),
  DesignCategory(id: 5, shortLabel: 'Motorbikes', label: 'Motorbikes', slug: 'motorbikes', icon: Icons.two_wheeler_outlined),
  DesignCategory(id: 3, shortLabel: 'Laptops', label: 'Laptops', slug: 'laptops', icon: Icons.laptop_outlined),
  DesignCategory(id: 2, shortLabel: 'Tablets', label: 'Tablets', slug: 'tablets', icon: Icons.tablet_android_outlined),
  DesignCategory(id: 6, shortLabel: 'E-scooty', label: 'Electric scooty', slug: 'electric-scooty', icon: Icons.electric_scooter_outlined),
  DesignCategory(id: 10, shortLabel: 'Gaming', label: 'Gaming', slug: 'gaming', icon: Icons.sports_esports_outlined),
];

/// The four Atom apps (Home "The Atom ecosystem" card and the ecosystem page).
class DesignApp {
  const DesignApp({required this.name, required this.body, required this.logo});

  final String name;
  final String body;
  final String logo;
}

const designApps = [
  DesignApp(name: 'Atomshop', body: 'Shop on installments and track every payment. You are here.', logo: 'assets/images/app-atomshop.png'),
  DesignApp(name: 'AtomPay', body: 'Your purchase limit, KYC and 3-month 0% markup plans.', logo: 'assets/images/app-atompay.png'),
  DesignApp(name: 'Atom Seller', body: 'For local sellers: leads, deals and collections.', logo: 'assets/images/app-atomseller.png'),
  DesignApp(name: 'AtomBrand', body: 'For brands: storefront, stock and bulk orders.', logo: 'assets/images/app-atombrand.png'),
];
