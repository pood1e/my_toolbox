import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

@DataClassName('SyncSequence')
class SyncSequenceTable extends Table with SyncSequenceTableMixin {}
