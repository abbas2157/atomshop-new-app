import 'package:flutter/foundation.dart';

/// Whether the last request reached the Atomshop server. Turns false when a
/// request fails without an answer (no route, DNS, timeout) and true again
/// on the next answer of any kind. Together with the phone's network state
/// it tells "offline" apart from "network fine, server not reachable".
final ValueNotifier<bool> atomServerReachable = ValueNotifier<bool>(true);
