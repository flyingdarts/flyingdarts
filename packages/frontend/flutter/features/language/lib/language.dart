library;

import 'package:injectable/injectable.dart';

export 'package:language/src/dialog/language_dialog.dart';
export 'package:language/src/state/language_cubit.dart';
export 'package:language/src/state/language_state.dart';

export 'language.module.dart';

// @microPackageInit => short const
@InjectableInit.microPackage()
void initMicroPackage() {} // will not be called but needed for code generation
