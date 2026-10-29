import 'atom_account.dart';

/// The website's policy and FAQ text, word for word (atomshop.pk/privacy-policy,
/// /return-refund-policy and /faqs, copied 2026-10-29), so these screens
/// always have something to show.
///
/// The server's `api/app/pages/{slug}` wins whenever it answers; this is the
/// copy used until that endpoint is live or when it fails. Links inside the
/// website text ("Start a custom order") are left out: the app has its own
/// buttons for those. The AtomPay fee comes from the server config.
PageContent? atomSitePage(String slug, {num atompayFeePercent = 3}) => switch (slug) {
      // The website keeps its terms and privacy in one document.
      'privacy' || 'terms' => _privacyAndTerms,
      'refund' || 'returns' => _returns,
      'faqs' => _faqs(atompayFeePercent),
      _ => null,
    };

const _privacyAndTerms = PageContent(
  title: 'Privacy Policy',
  updatedAt: null,
  intro: 'Atomshop.pk is an online marketplace facilitating installment-based purchases. By using this website, you agree to abide by the terms and conditions outlined below. If you disagree, please refrain from using the platform.',
  url: 'https://atomshop.pk/privacy-policy',
  faqGroups: [],
  sections: [
    PageSection(
      heading: 'Acceptance of terms',
      paragraphs: [
        'By accessing Atomshop.pk, you acknowledge that this platform enables users to place orders for products on installments. This process requires verification and approval before fulfilment. The terms may change without prior notice, and continued use signifies acceptance.',
      ],
      bullets: [],
    ),
    PageSection(
      heading: 'Order placement & verification',
      paragraphs: [],
      bullets: [
        'Customers must provide accurate information when placing an order.',
        'Sellers on Atomshop.pk reserve the right to cancel any order after verification.',
        'If an order is rejected, the customer is responsible for collecting all submitted documents.',
        'One product can be purchased per CNIC at a time, subject to approval.',
        'Post-dated cheques may be required in some cases.',
      ],
    ),
    PageSection(
      heading: 'Eligibility',
      paragraphs: [],
      bullets: [
        'Users must be at least 18 years old and legally able to enter contracts in Pakistan.',
        'Providing false or inaccurate information may lead to account termination.',
      ],
    ),
    PageSection(
      heading: 'Account security',
      paragraphs: [],
      bullets: [
        'Users are responsible for maintaining the confidentiality of their accounts.',
        'Any unauthorised access should be reported immediately.',
        'Atomshop.pk is not liable for any loss resulting from account misuse.',
      ],
    ),
    PageSection(
      heading: 'Product delivery & warranty',
      paragraphs: [],
      bullets: [
        'Delivery is subject to vendor timelines and market conditions.',
        'Customers must sign a delivery note acknowledging receipt.',
        'Warranty claims must be made directly to the manufacturer or authorised service centres.',
        'Atomshop.pk does not provide insurance for any purchased items.',
      ],
    ),
    PageSection(
      heading: 'Pricing & availability',
      paragraphs: [],
      bullets: [
        'Prices and availability are subject to change without notice.',
        'Once an order is locked, the agreed amount will not fluctuate based on market changes.',
      ],
    ),
    PageSection(
      heading: 'Cancellations & refunds',
      paragraphs: [],
      bullets: [
        'Sellers may cancel orders at their discretion after verification.',
        'Customers must collect their documents upon order rejection.',
        'Overpayments may be adjusted in future installments or refunded within 45 days upon request.',
        'See also our Return and Refund Policy.',
      ],
    ),
    PageSection(
      heading: 'Privacy & data security',
      paragraphs: [],
      bullets: [
        'Customer data is securely stored and accessed on a need-to-know basis.',
        'Data may be shared with third-party verification agencies as required.',
        'Atomshop.pk will not access personal mobile data.',
        'You can delete your account at any time: in the Atomshop or AtomBrand app (AtomBrand: More, then Delete account), or at atomshop.pk/delete-account.',
        "Deleting a Brand Partner (AtomBrand) account removes its name, email, phone, password, sign-ins and notifications, and takes the brand's products off the store. Deleting a customer account closes it so it can no longer sign in. In both cases orders, payments and their history are kept for as long as the law requires for invoices and tax.",
        'Ask Atom: when you ask our assistant, Ask Atom, a question, we keep the question for up to 90 days to improve its answers. Before saving it we remove phone numbers, CNIC numbers and email addresses, and we do not store your IP address or link the question to your account.',
      ],
    ),
    PageSection(
      heading: 'Legal compliance & disputes',
      paragraphs: [],
      bullets: [
        'Transactions are governed by the laws of Pakistan.',
        'Any disputes will be resolved in Pakistani courts.',
        'Users should conduct due diligence before entering any agreement.',
      ],
    ),
    PageSection(
      heading: 'Customer support & grievances',
      paragraphs: [
        'For complaints or enquiries, contact us using the details below.',
        'By using Atomshop.pk, you acknowledge and agree to these terms.',
        'Questions about this policy? Email atomshoppk@gmail.com or call +92 330 2277522.',
      ],
      bullets: [],
    ),
  ],
);

const _returns = PageContent(
  title: 'Return and Refund Policy',
  updatedAt: null,
  intro: 'When you can return a product, how refunds work, and why we ask you to check every item at delivery.',
  url: 'https://atomshop.pk/return-refund-policy',
  faqGroups: [],
  sections: [
    PageSection(
      heading: 'Policy at a glance',
      paragraphs: [],
      bullets: [
        'At delivery: check your item before you sign. Later claims are not accepted.',
        '5 working days: to report issues with ACs, UPS, burners and similar products.',
        '7–10 days: business days to process an approved refund.',
      ],
    ),
    PageSection(
      heading: 'When returns are accepted',
      paragraphs: [],
      bullets: ['Returns are accepted only if you receive the wrong item or a non-functional product at the time of delivery.'],
    ),
    PageSection(
      heading: 'Condition of returned items',
      paragraphs: [],
      bullets: ['Items must be unused, unscratched and in original packaging with an invoice for return requests.'],
    ),
    PageSection(
      heading: 'Checking your item',
      paragraphs: ['Check your product before you sign the delivery note. Claims are not accepted once delivery is signed for.'],
      bullets: [
        'Check your item at delivery; claims after that will not be entertained.',
        'Certain products (ACs, UPS, burners, etc.) must be checked within 5 working days for any complaints.',
      ],
    ),
    PageSection(
      heading: 'Defects after delivery',
      paragraphs: [],
      bullets: ["If a product is defective after delivery, claim through the manufacturer's warranty."],
    ),
    PageSection(
      heading: 'Refunds',
      paragraphs: [],
      bullets: [
        'Refunds, if approved, are processed within 7–10 business days.',
        'Shipping costs are non-refundable.',
      ],
    ),
    PageSection(
      heading: 'No exchanges & cancellations',
      paragraphs: ['Received a wrong or faulty item? Contact us right away at atomshoppk@gmail.com or +92 330 2277522.'],
      bullets: [
        'No replacements or exchanges; check items at delivery.',
        'Orders can be cancelled before shipment only.',
      ],
    ),
  ],
);

PageContent _faqs(num feePercent) {
  final fee = feePercent == feePercent.roundToDouble() ? feePercent.round().toString() : feePercent.toString();
  return PageContent(
    title: 'Frequently asked questions',
    updatedAt: null,
    intro: 'Everything you need to know about buying on installments, your monthly plan, AtomPay, delivery and partnering with Atomshop.pk.',
    url: 'https://atomshop.pk/faqs',
    sections: const [],
    faqGroups: [
      const FaqGroup('Shopping', [
        ('How can I purchase products on installments?', 'You can select any product from our website or our Android/iOS app and choose an installment plan that suits you. You can also create a custom plan based on your preference.'),
        ('Can I purchase a product that is not available on the website?', 'Yes. You can select a product from the market and use our Custom Order & Installment Calculator to place an order.'),
        (
          'What documents are required for installments?',
          'To apply, you need:\n• A valid CNIC\n• Two references (personal or professional)\n• Proof of income (salary slip, bank statement, or business proof)\n• A post-dated cheque (if required)\n\nRequirements may vary based on the product and financing plan.',
        ),
        ('How long does installment approval take?', 'Approval usually takes 24–48 hours, depending on document verification and eligibility checks.'),
        ('Who can buy on installments?', 'You must be at least 18 years old and legally able to enter contracts in Pakistan. Providing false or inaccurate information may lead to account termination.'),
        ('Can I buy more than one product at a time?', 'One product can be purchased per CNIC at a time, subject to approval.'),
      ]),
      const FaqGroup('Payments & plans', [
        ('Is there any upfront payment required?', 'With Atomshop Seller Financing, yes: plans start with a minimum 20% advance, and the exact advance depends on the product and the plan you choose. AtomPay plans on eligible listed products need no advance.'),
        ('How long can I take to pay?', 'With Atomshop Seller Financing, plans run from 3 to 12 months and the rest of the price after your advance is split into equal monthly installments. AtomPay plans are always 3 months.'),
        ('How do I know my monthly amount?', 'Use the Installment Calculator to pick your advance and number of months and see an estimate. The calculator is an estimate only; our team confirms the final plan.'),
        ('Do I need a credit card?', 'No. You do not need a credit card to buy on installments with Atomshop.'),
        ('Will the price change after I order?', 'Prices and availability can change without notice, but once an order is locked, the agreed amount will not fluctuate with market changes.'),
        ('What happens if I miss an installment payment?', 'Missing payments may result in penalties, restrictions on future purchases, and legal action. Always pay on time to maintain a good credit standing.'),
        ('What if I pay more than I owe?', 'Overpayments may be adjusted in future installments or refunded within 45 days on request.'),
      ]),
      FaqGroup('AtomPay', [
        ('What is AtomPay?', 'AtomPay is the financing app in the Atom ecosystem. Verify once with your CNIC and income, get a spending limit, and use it at checkout on Atomshop.'),
        ('Is there a markup with AtomPay?', 'No. An AtomPay plan is 3 monthly payments with no advance and 0% markup. It is the only AtomPay plan. A $fee% processing fee and delivery charges apply in addition.'),
        ('Which products can I buy with AtomPay?', 'Only listed catalogue products that Atomshop has selected for AtomPay, product by product or brand by brand. Look for the AtomPay eligible badge, or use the AtomPay-eligible filter in the shop.'),
        ('Can I use AtomPay on a custom order or offer request?', 'No. AtomPay is not available on custom orders or make-an-offer requests. Those are financed by Atomshop Seller Financing.'),
        ('How do I use AtomPay on Atomshop?', 'Choose AtomPay as the financing option on an eligible product page, then complete your AtomPay profile using the same phone number as your Atomshop account. Your approved limit must cover the financed amount.'),
      ]),
      const FaqGroup('Delivery & returns', [
        ('Where do you deliver?', 'We currently deliver in Lahore only. More cities are planned.'),
        ('When will I receive my order?', 'Delivery is subject to vendor timelines and market conditions. You will be asked to sign a delivery note acknowledging receipt.'),
        ('Can I return a product?', 'Returns are accepted only if you receive the wrong item or a non-functional product at the time of delivery. Items must be unused, unscratched and in original packaging with an invoice. Please check your item at delivery.'),
        ('Can I cancel my order?', 'Orders can be cancelled before shipment only. There are no replacements or exchanges.'),
        ('Who handles warranty claims?', 'Warranty claims are made directly to the manufacturer or its authorised service centres. Atomshop.pk does not provide insurance for purchased items.'),
      ]),
      const FaqGroup('Partners', [
        ('How can I start selling on Atomshop.pk?', 'Register as a seller on our website, provide your business details, and choose a suitable plan to start selling.'),
        ('What are the benefits of selling on Atomshop.pk?', 'You get a ready-to-use SaaS platform, marketing support, and access to a large customer base looking for installment-based shopping.'),
        ('How do I receive payments for my sales?', 'Payments are transferred directly to your registered bank account as per the agreed settlement terms.'),
        ('Can I set my own installment plans?', 'Yes. Sellers have the flexibility to define their own installment structures based on their business model.'),
        ('Is there a fee for selling on Atomshop.pk?', 'Yes, a service fee applies based on the chosen SaaS plan. See the seller registration section for details.'),
        ('How can my brand partner with Atomshop?', 'Brands run their own storefront, stock, orders and bulk quotes on Atomshop through the AtomBrand app.'),
      ]),
    ],
  );
}
