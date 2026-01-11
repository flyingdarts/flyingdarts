// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'keyboard_button.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<KeyboardButton, KeyboardButtonArgs>;
typedef _Scenario = KeyboardButtonScenario;
typedef _Defaults = KeyboardButtonDefaults;
typedef _Story = KeyboardButtonStory;
typedef _Args = KeyboardButtonArgs;
final KeyboardButtonComponent = Component<KeyboardButton, KeyboardButtonArgs>(
  name: meta.name ?? 'KeyboardButton',
  path: meta.path ?? 'features/keyboard/widgets',
  docs: meta.docs ?? null,
  stories: [$Default..$generatedName = 'Default'],
);
typedef KeyboardButtonScenario = Scenario<KeyboardButton, KeyboardButtonArgs>;
typedef KeyboardButtonDefaults = Defaults<KeyboardButton, KeyboardButtonArgs>;

class KeyboardButtonStory extends Story<KeyboardButton, KeyboardButtonArgs> {
  KeyboardButtonStory({
    super.name,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<KeyboardButton, KeyboardButtonArgs>? builder,
    super.scenarios,
  }) : super(
         builder:
             builder ??
             (context, args) => KeyboardButton(
               key: args.key,
               input: args.input,
               onPressed: args.onPressed,
               disabled: args.disabled,
               color: args.color,
             ),
       );
}

class KeyboardButtonArgs extends StoryArgs<KeyboardButton> {
  KeyboardButtonArgs({
    Arg<Key?>? key,
    Arg<String>? input,
    required Arg<void Function()> onPressed,
    Arg<bool>? disabled,
    Arg<Color>? color,
  }) : this.keyArg = $initArg('key', key, null),
       this.inputArg = $initArg('input', input, StringArg(''))!,
       this.onPressedArg = $initArg('onPressed', onPressed, null)!,
       this.disabledArg = $initArg('disabled', disabled, BoolArg(false))!,
       this.colorArg = $initArg(
         'color',
         color,
         ColorArg(const Color(4278190080)),
       )!;

  KeyboardButtonArgs.fixed({
    Key? key,
    String input = '',
    required void Function() onPressed,
    bool disabled = false,
    Color color = const Color(4278190080),
  }) : this.keyArg = key == null ? null : Arg.fixed(key),
       this.inputArg = Arg.fixed(input),
       this.onPressedArg = Arg.fixed(onPressed),
       this.disabledArg = Arg.fixed(disabled),
       this.colorArg = Arg.fixed(color);

  final Arg<Key?>? keyArg;

  final Arg<String> inputArg;

  final Arg<void Function()> onPressedArg;

  final Arg<bool> disabledArg;

  final Arg<Color> colorArg;

  Key? get key => keyArg?.value;

  String get input => inputArg.value;

  void Function() get onPressed => onPressedArg.value;

  bool get disabled => disabledArg.value;

  Color get color => colorArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    inputArg,
    onPressedArg,
    disabledArg,
    colorArg,
  ];
}
