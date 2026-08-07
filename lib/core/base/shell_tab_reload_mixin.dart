// Mixin: reload when the shell tab matching [tab] becomes active.

import 'package:get/get.dart';

import '../../modules/shell/controller/shell_controller.dart';
import '../widgets/recall_scaffold.dart';
import 'base_controller.dart';

mixin ShellTabReloadMixin on BaseController {
  Worker? _shellTabWorker;

  void bindTabReload(RecallTab tab, Future<void> Function() reload) {
    final shell = Get.find<ShellController>();
    _shellTabWorker = ever(shell.currentTab, (RecallTab t) {
      if (isClosed) return;
      if (t == tab) reload();
    });
  }

  void disposeTabReload() {
    _shellTabWorker?.dispose();
    _shellTabWorker = null;
  }
}
