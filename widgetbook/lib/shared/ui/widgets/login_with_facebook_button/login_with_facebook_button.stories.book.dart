// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'login_with_facebook_button.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<LoginWithFacebookButton, LoginWithFacebookButtonArgs>;
typedef _Scenario = LoginWithFacebookButtonScenario;
typedef _Defaults = LoginWithFacebookButtonDefaults;
typedef _Story = LoginWithFacebookButtonStory;
typedef _Args = LoginWithFacebookButtonArgs;
final LoginWithFacebookButtonComponent =
    Component<LoginWithFacebookButton, LoginWithFacebookButtonArgs>(
      name: meta.name ?? 'LoginWithFacebookButton',
      path: meta.path ?? 'shared/ui/widgets/login_with_facebook_button',
      docs: meta.docs ?? null,
      stories: [$Default..$generatedName = 'Default'],
    );
typedef LoginWithFacebookButtonScenario =
    Scenario<LoginWithFacebookButton, LoginWithFacebookButtonArgs>;
typedef LoginWithFacebookButtonDefaults =
    Defaults<LoginWithFacebookButton, LoginWithFacebookButtonArgs>;

class LoginWithFacebookButtonStory
    extends Story<LoginWithFacebookButton, LoginWithFacebookButtonArgs> {
  LoginWithFacebookButtonStory({
    super.name,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<LoginWithFacebookButton, LoginWithFacebookButtonArgs>?
    builder,
    super.scenarios,
  }) : super(
         builder:
             builder ??
             (context, args) => LoginWithFacebookButton(
               key: args.key,
               onPressed: args.onPressed,
             ),
       );
}

class LoginWithFacebookButtonArgs extends StoryArgs<LoginWithFacebookButton> {
  LoginWithFacebookButtonArgs({
    Arg<Key?>? key,
    required Arg<void Function()> onPressed,
  }) : this.keyArg = $initArg('key', key, null),
       this.onPressedArg = $initArg('onPressed', onPressed, null)!;

  LoginWithFacebookButtonArgs.fixed({
    Key? key,
    required void Function() onPressed,
  }) : this.keyArg = key == null ? null : Arg.fixed(key),
       this.onPressedArg = Arg.fixed(onPressed);

  final Arg<Key?>? keyArg;

  final Arg<void Function()> onPressedArg;

  Key? get key => keyArg?.value;

  void Function() get onPressed => onPressedArg.value;

  @override
  List<Arg?> get list => [keyArg, onPressedArg];
}
