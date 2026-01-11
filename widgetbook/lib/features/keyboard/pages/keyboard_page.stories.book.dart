// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'keyboard_page.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<KeyboardPage, KeyboardPageArgs>;
typedef _Scenario = KeyboardPageScenario;
typedef _Defaults = KeyboardPageDefaults;
typedef _Story = KeyboardPageStory;
typedef _Args = KeyboardPageArgs;
final KeyboardPageComponent = Component<KeyboardPage, KeyboardPageArgs>(
  name: meta.name ?? 'KeyboardPage',
  path: meta.path ?? 'features/keyboard/pages',
  docs: meta.docs ?? null,
  stories: [$Default..$generatedName = 'Default'],
);
typedef KeyboardPageScenario = Scenario<KeyboardPage, KeyboardPageArgs>;
typedef KeyboardPageDefaults = Defaults<KeyboardPage, KeyboardPageArgs>;

class KeyboardPageStory extends Story<KeyboardPage, KeyboardPageArgs> {
  KeyboardPageStory({
    super.name,
    super.setup,
    super.modes,
    KeyboardPageArgs? args,
    StoryWidgetBuilder<KeyboardPage, KeyboardPageArgs>? builder,
    super.scenarios,
  }) : super(
          args: args ?? KeyboardPageArgs(),
          builder: builder ?? (context, args) => KeyboardPage(key: args.key),
        );
}

class KeyboardPageArgs extends StoryArgs<KeyboardPage> {
  KeyboardPageArgs({Arg<Key?>? key}) : this.keyArg = $initArg('key', key, null);

  KeyboardPageArgs.fixed({Key? key}) : this.keyArg = key == null ? null : Arg.fixed(key);

  final Arg<Key?>? keyArg;

  Key? get key => keyArg?.value;

  @override
  List<Arg?> get list => [keyArg];
}
