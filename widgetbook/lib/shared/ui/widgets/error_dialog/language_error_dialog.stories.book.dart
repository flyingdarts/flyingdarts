// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'language_error_dialog.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<LanguageErrorDialog, LanguageErrorDialogArgs>;
typedef _Scenario = LanguageErrorDialogScenario;
typedef _Defaults = LanguageErrorDialogDefaults;
typedef _Story = LanguageErrorDialogStory;
typedef _Args = LanguageErrorDialogArgs;
final LanguageErrorDialogComponent =
    Component<LanguageErrorDialog, LanguageErrorDialogArgs>(
      name: meta.name ?? 'LanguageErrorDialog',
      path: meta.path ?? 'shared/ui/widgets/error_dialog',
      docs: meta.docs ?? null,
      stories: [$Default..$generatedName = 'Default'],
    );
typedef LanguageErrorDialogScenario =
    Scenario<LanguageErrorDialog, LanguageErrorDialogArgs>;
typedef LanguageErrorDialogDefaults =
    Defaults<LanguageErrorDialog, LanguageErrorDialogArgs>;

class LanguageErrorDialogStory
    extends Story<LanguageErrorDialog, LanguageErrorDialogArgs> {
  LanguageErrorDialogStory({
    super.name,
    super.setup,
    super.modes,
    LanguageErrorDialogArgs? args,
    StoryWidgetBuilder<LanguageErrorDialog, LanguageErrorDialogArgs>? builder,
    super.scenarios,
  }) : super(
         args: args ?? LanguageErrorDialogArgs(),
         builder:
             builder ??
             (context, args) =>
                 LanguageErrorDialog(key: args.key, error: args.error),
       );
}

class LanguageErrorDialogArgs extends StoryArgs<LanguageErrorDialog> {
  LanguageErrorDialogArgs({Arg<Key?>? key, Arg<String>? error})
    : this.keyArg = $initArg('key', key, null),
      this.errorArg = $initArg('error', error, StringArg(''))!;

  LanguageErrorDialogArgs.fixed({Key? key, String error = ''})
    : this.keyArg = key == null ? null : Arg.fixed(key),
      this.errorArg = Arg.fixed(error);

  final Arg<Key?>? keyArg;

  final Arg<String> errorArg;

  Key? get key => keyArg?.value;

  String get error => errorArg.value;

  @override
  List<Arg?> get list => [keyArg, errorArg];
}
