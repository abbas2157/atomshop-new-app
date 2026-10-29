import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/atom_auth.dart';
import '../../data/atom_http.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../shell/atom_nav.dart';
import '../../state/atom_account_providers.dart';
import '../../widgets/atom_leave_guard.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import '../../widgets/atom_text_field.dart';
import 'atom_account_widgets.dart';

/// Profile and verification (canvas: "Profile and verification").
class AtomProfileScreen extends ConsumerWidget {
  const AtomProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    // The form keeps its own copy once loaded; a refresh after a photo
    // upload must not wipe what is being typed.
    return me.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: (user) => _ProfileForm(user: user),
      loading: () => const AtomPage(
        title: 'Profile and verification',
        children: [
          AtomSkeleton(height: 160, radius: AtomRadius.card),
          SizedBox(height: AtomSpace.md),
          AtomSkeleton(height: 300, radius: AtomRadius.card),
        ],
      ),
      error: (e, _) => AtomPage(
        title: 'Profile',
        children: [AtomErrorState(error: e, onRetry: () => ref.invalidate(meProvider))],
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.user});

  final AtomUser user;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _father = TextEditingController(text: widget.user.fatherName);
  final _cnic = TextEditingController();
  late final _email = TextEditingController(text: widget.user.email);
  late final _alternate = TextEditingController(text: widget.user.alternatePhone);
  late final _address = TextEditingController(text: widget.user.address);
  late final _work = TextEditingController(text: widget.user.workAddress);
  late final _phone = TextEditingController(text: widget.user.phone);

  /// Father name, CNIC, email, alternate number and work address are only
  /// shown when the account endpoint can save them.
  static const _extended = AtomAuthApi.supportsExtendedProfile;
  bool _saving = false;

  /// Edited and not sent yet: leaving asks first.
  bool _dirty = false;

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  /// Which upload is running: 'photo', 'front', 'back'.
  String? _uploading;

  @override
  void dispose() {
    for (final c in [_name, _father, _cnic, _email, _alternate, _address, _work, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  void _say(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<String?> _pick() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    return file?.path;
  }

  Future<void> _upload(String what) async {
    final path = await _pick();
    if (path == null || !mounted) return;
    setState(() => _uploading = what);
    try {
      final api = ref.read(atomAuthApiProvider);
      if (what == 'photo') {
        await api.uploadPhoto(path);
      } else {
        await api.uploadCnic(front: what == 'front', path: path);
      }
      ref.invalidate(meProvider);
      _say(what == 'photo' ? 'Photo updated.' : 'CNIC photo uploaded.');
    } catch (e) {
      _say(atomMessage(e));
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  Future<void> _save() async {
    // A second tap before the button repaints must not send twice.
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(atomAuthApiProvider)
          .updateMe(
            name: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
            email: _email.text.trim(),
            fatherName: _father.text.trim().replaceAll(RegExp(r'\s+'), ' '),
            cnic: _cnic.text.trim(),
            alternatePhone: _alternate.text.trim(),
            address: _address.text.trim(),
            workAddress: _work.text.trim(),
            cityId: widget.user.city?.id,
            areaId: widget.user.area?.id,
            phone: _extended ? '' : _phone.text.trim(),
          );
      refreshAccount(ref);
      if (!mounted) return;
      _say('Your profile is saved.');
      // Saved: no "leave this form?" question on the way out.
      setState(() => _dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _say(atomMessage(e));
    }
  }

  static String? _personName(String? v, {bool required = false}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return required ? 'Enter your full name.' : null;
    if (!RegExp(r'^[\p{L} ]+$', unicode: true).hasMatch(t)) return 'Use letters and spaces only.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return AtomLeaveGuard(
      dirty: _dirty,
      child: Form(
        key: _form,
        onChanged: _markDirty,
        child: AtomPage(
          title: _extended ? 'Profile and verification' : 'Profile',
          bottom: AtomButton(label: 'Save changes', icon: Icons.check_rounded, expand: true, loading: _saving, onPressed: _saving ? null : _save),
          children: [
            _Identity(user: u, uploading: _uploading == 'photo', onChangePhoto: () => _upload('photo'), showVerification: _extended),
            const AtomGroupLabel('Personal'),
            AtomTextField(
              label: 'Full name',
              controller: _name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              validator: (v) => _personName(v, required: true),
            ),
            if (_extended) ...[
            const SizedBox(height: 14),
            AtomTextField(label: 'Father name', optional: true, controller: _father, textCapitalization: TextCapitalization.words, validator: _personName),
            const SizedBox(height: 14),
            AtomTextField(
              label: 'CNIC number',
              optional: true,
              controller: _cnic,
              hint: u.cnicMasked.isEmpty ? '35202-1234567-1' : '${u.cnicMasked} (type to change)',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13), _CnicFormatter()],
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.isEmpty) return null;
                return digits.length == 13 ? null : 'Enter the 13 digits of your CNIC.';
              },
            ),
            const SizedBox(height: 14),
            AtomTextField(
              label: 'Email',
              optional: true,
              controller: _email,
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null;
                return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t) ? null : 'Enter a valid email or leave it empty.';
              },
            ),
            ] else if (u.email.isNotEmpty) ...[
              const SizedBox(height: 14),
              _ReadOnlyField(label: 'Email', value: u.email, note: 'To change your email, contact us.', onNote: () => AtomNav.contact(context)),
            ],
            const AtomGroupLabel('Phone numbers'),
            if (_extended)
              _ReadOnlyField(label: 'Mobile', value: u.phone, note: 'To change your mobile number, contact us.', onNote: () => AtomNav.contact(context))
            else
              AtomTextField(
                label: 'Mobile number',
                controller: _phone,
                hint: '03001234567',
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')), LengthLimitingTextInputFormatter(20)],
                validator: (v) => (v ?? '').trim().length < 10 ? 'Enter your mobile number.' : null,
              ),
            if (_extended) ...[
            const SizedBox(height: 14),
            AtomTextField(
              label: 'Alternate number',
              optional: true,
              controller: _alternate,
              hint: 'Optional',
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')), LengthLimitingTextInputFormatter(20)],
            ),
            ],
            const AtomGroupLabel('Address'),
            _ReadOnlyField(label: 'City and area', value: u.place.isEmpty ? 'Not set' : u.place, note: 'Change', onNote: () => AtomNav.location(context)),
            const SizedBox(height: 14),
            AtomTextField(
              label: 'Home address',
              controller: _address,
              hint: 'House, street and block',
              maxLines: 2,
              autofillHints: const [AutofillHints.fullStreetAddress],
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your home address.' : null,
            ),
            if (_extended) ...[
            const SizedBox(height: 14),
            AtomTextField(label: 'Work or office address', optional: true, controller: _work, hint: 'Optional', maxLines: 2),
            const AtomGroupLabel('CNIC photos'),
            Row(
              children: [
                Expanded(
                  child: _CnicTile(label: 'Front', uploaded: u.cnicFrontUploaded, busy: _uploading == 'front', onTap: () => _upload('front')),
                ),
                const SizedBox(width: AtomSpace.sm),
                Expanded(
                  child: _CnicTile(label: 'Back', uploaded: u.cnicBackUploaded, busy: _uploading == 'back', onTap: () => _upload('back')),
                ),
              ],
            ),
            const SizedBox(height: AtomSpace.md),
            const AtomNotice(
              icon: Icons.lock_outline_rounded,
              text: 'Your documents are only seen by the team that verifies you. They are never shown publicly.',
            ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.user, required this.uploading, required this.onChangePhoto, this.showVerification = true});

  final AtomUser user;
  final bool uploading;
  final VoidCallback onChangePhoto;
  final bool showVerification;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AtomSpace.xs),
        Stack(
          clipBehavior: Clip.none,
          children: [
            AccountAvatar(user: user, size: 88),
            Positioned(
              right: -4,
              bottom: -4,
              child: Tooltip(
                message: 'Change photo',
                child: Material(
                  color: AtomColors.primary,
                  shape: const CircleBorder(side: BorderSide(color: AtomColors.white, width: 2)),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: uploading ? null : onChangePhoto,
                    child: SizedBox.square(
                      dimension: 40,
                      child: uploading
                          ? const Padding(
                              padding: EdgeInsets.all(11),
                              child: CircularProgressIndicator(strokeWidth: 2, color: AtomColors.white),
                            )
                          : const Icon(Icons.photo_camera_outlined, size: 18, color: AtomColors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AtomSpace.sm),
        Text(user.name, textAlign: TextAlign.center, style: AtomText.heading),
        if (user.customerId.isNotEmpty) Text('Customer ID ${user.customerId}', style: AtomText.small),
        if (showVerification) ...[
          const SizedBox(height: 6),
          user.verified ? const AtomBadge('Verified', tone: AtomTone.green, icon: Icons.check_rounded) : const AtomBadge('Not verified yet'),
        ],
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value, required this.note, required this.onNote});

  final String label;
  final String value;
  final String note;
  final VoidCallback onNote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AtomText.label),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: AtomSize.input),
          padding: const EdgeInsets.symmetric(horizontal: AtomSpace.md, vertical: 14),
          decoration: BoxDecoration(
            color: AtomColors.surface,
            borderRadius: BorderRadius.circular(AtomRadius.input),
            border: Border.all(color: AtomColors.line),
          ),
          child: Text(value, style: AtomText.body.copyWith(fontSize: 15, color: AtomColors.ink)),
        ),
        TextButton(
          onPressed: onNote,
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: const Size(44, 36)),
          child: Text(
            note,
            style: AtomText.small.copyWith(color: AtomColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _CnicTile extends StatelessWidget {
  const _CnicTile({required this.label, required this.uploaded, required this.busy, required this.onTap});

  final String label;
  final bool uploaded;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: uploaded ? 'CNIC $label uploaded. Tap to replace.' : 'Upload CNIC $label',
      excludeSemantics: true,
      child: AtomCard(
        onTap: busy ? null : onTap,
        color: AtomColors.surface,
        borderColor: uploaded ? null : AtomColors.line2,
        padding: const EdgeInsets.symmetric(vertical: AtomSpace.md, horizontal: AtomSpace.sm),
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: busy
                  ? const Center(child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2)))
                  : Icon(
                      uploaded ? Icons.check_circle_rounded : Icons.add_photo_alternate_outlined,
                      size: 32,
                      color: uploaded ? AtomColors.green : AtomColors.primary,
                    ),
            ),
            const SizedBox(height: 6),
            Text(uploaded ? '$label uploaded' : 'Add $label', textAlign: TextAlign.center, style: AtomText.label.copyWith(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// 3520212345671 → 35202-1234567-1 while typing.
class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final d = newValue.text.replaceAll(RegExp(r'\D'), '');
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 5 || i == 12) b.write('-');
      b.write(d[i]);
    }
    final text = b.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
