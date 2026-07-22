import 'package:integration_test/integration_test.dart';

import 'app_entry_shell_test.dart' as app_entry_shell;
import 'cards_test.dart' as cards;
import 'progress_test.dart' as progress;
import 'theme_test.dart' as theme;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  app_entry_shell.main();
  cards.main();
  progress.main();
  theme.main();
}
