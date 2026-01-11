// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'profile_dialog.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ProfileDialog, ProfileDialogArgs>;
typedef _Scenario = ProfileDialogScenario;
typedef _Defaults = ProfileDialogDefaults;
typedef _Story = ProfileDialogStory;
typedef _Args = ProfileDialogArgs;
final ProfileDialogComponent = Component<ProfileDialog, ProfileDialogArgs>(
  name: meta.name ?? 'ProfileDialog',
  path: meta.path ?? 'features/profile/dialog',
  docs: meta.docs ?? null,
  stories: [$Default..$generatedName = 'Default'],
);
typedef ProfileDialogScenario = Scenario<ProfileDialog, ProfileDialogArgs>;
typedef ProfileDialogDefaults = Defaults<ProfileDialog, ProfileDialogArgs>;

class ProfileDialogStory extends Story<ProfileDialog, ProfileDialogArgs> {
  ProfileDialogStory({
    super.name,
    super.setup,
    super.modes,
    ProfileDialogArgs? args,
    StoryWidgetBuilder<ProfileDialog, ProfileDialogArgs>? builder,
    super.scenarios,
  }) : super(
         args: args ?? ProfileDialogArgs(),
         builder: builder ?? (context, args) => ProfileDialog(key: args.key),
       );
}

class ProfileDialogArgs extends StoryArgs<ProfileDialog> {
  ProfileDialogArgs({Arg<Key?>? key})
    : this.keyArg = $initArg('key', key, null);

  ProfileDialogArgs.fixed({Key? key})
    : this.keyArg = key == null ? null : Arg.fixed(key);

  final Arg<Key?>? keyArg;

  Key? get key => keyArg?.value;

  @override
  List<Arg?> get list => [keyArg];
}
