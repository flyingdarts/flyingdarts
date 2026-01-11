// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'language_dialog.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<LanguageDialog, LanguageDialogArgs>;
typedef _Scenario = LanguageDialogScenario;
typedef _Defaults = LanguageDialogDefaults;
typedef _Story = LanguageDialogStory;
typedef _Args = LanguageDialogArgs;
final LanguageDialogComponent = Component<LanguageDialog, LanguageDialogArgs>(
  name: meta.name ?? 'LanguageDialog',
  path: meta.path ?? 'features/language/dialog',
  docs: meta.docs ?? null,
  stories: [$Default..$generatedName = 'Default'],
);
typedef LanguageDialogScenario = Scenario<LanguageDialog, LanguageDialogArgs>;
typedef LanguageDialogDefaults = Defaults<LanguageDialog, LanguageDialogArgs>;

class LanguageDialogStory extends Story<LanguageDialog, LanguageDialogArgs> {
  LanguageDialogStory({
    super.name,
    super.setup,
    super.modes,
    LanguageDialogArgs? args,
    StoryWidgetBuilder<LanguageDialog, LanguageDialogArgs>? builder,
    super.scenarios,
  }) : super(
         args: args ?? LanguageDialogArgs(),
         builder: builder ?? (context, args) => LanguageDialog(key: args.key),
       );
}

class LanguageDialogArgs extends StoryArgs<LanguageDialog> {
  LanguageDialogArgs({Arg<Key?>? key})
    : this.keyArg = $initArg('key', key, null);

  LanguageDialogArgs.fixed({Key? key})
    : this.keyArg = key == null ? null : Arg.fixed(key);

  final Arg<Key?>? keyArg;

  Key? get key => keyArg?.value;

  @override
  List<Arg?> get list => [keyArg];
}
