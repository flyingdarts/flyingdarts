import 'package:flutter/material.dart';
import 'package:keyboard/keyboard.dart';
import 'package:widgetbook/widgetbook.dart';

part 'keyboard_button.stories.book.dart';

const meta = Meta<KeyboardButton>();

final $Default = _Story(name: 'Default', args: KeyboardButtonArgs(onPressed: Arg.fixed(() => {})));
