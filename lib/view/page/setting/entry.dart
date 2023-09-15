import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_highlight/theme_map.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox/core/extension/colorx.dart';
import 'package:toolbox/core/extension/context/common.dart';
import 'package:toolbox/core/extension/context/snackbar.dart';
import 'package:toolbox/core/extension/locale.dart';
import 'package:toolbox/core/extension/context/dialog.dart';
import 'package:toolbox/core/extension/stringx.dart';
import 'package:toolbox/core/utils/platform/auth.dart';
import 'package:toolbox/data/res/provider.dart';
import 'package:toolbox/data/res/store.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import '../../../core/persistant_store.dart';
import '../../../core/route.dart';
import '../../../core/utils/misc.dart';
import '../../../core/utils/platform/base.dart';
import '../../../core/update.dart';
import '../../../data/model/app/net_view.dart';
import '../../../data/provider/app.dart';
import '../../../data/res/build_data.dart';
import '../../../data/res/color.dart';
import '../../../data/res/path.dart';
import '../../../data/res/ui.dart';
import '../../widget/color_picker.dart';
import '../../widget/custom_appbar.dart';
import '../../widget/future_widget.dart';
import '../../widget/input_field.dart';
import '../../widget/round_rect_card.dart';
import '../../widget/store_switch.dart';
import '../../widget/value_notifier.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final _themeKey = GlobalKey<PopupMenuButtonState<int>>();
  final _updateIntervalKey = GlobalKey<PopupMenuButtonState<int>>();
  final _maxRetryKey = GlobalKey<PopupMenuButtonState<int>>();
  final _localeKey = GlobalKey<PopupMenuButtonState<String>>();
  final _editorThemeKey = GlobalKey<PopupMenuButtonState<String>>();
  final _editorDarkThemeKey = GlobalKey<PopupMenuButtonState<String>>();
  final _keyboardTypeKey = GlobalKey<PopupMenuButtonState<int>>();
  final _rotateQuarterKey = GlobalKey<PopupMenuButtonState<int>>();
  final _netViewTypeKey = GlobalKey<PopupMenuButtonState<NetViewType>>();
  final _setting = Stores.setting;

  late S _s;
  late SharedPreferences _sp;

  final _selectedColorValue = ValueNotifier(0);
  final _nightMode = ValueNotifier(0);
  final _maxRetryCount = ValueNotifier(0);
  final _updateInterval = ValueNotifier(0);
  final _termFontSize = ValueNotifier(0.0);
  final _editorFontSize = ValueNotifier(0.0);
  final _localeCode = ValueNotifier('');
  final _editorTheme = ValueNotifier('');
  final _editorDarkTheme = ValueNotifier('');
  final _keyboardType = ValueNotifier(0);
  final _rotateQuarter = ValueNotifier(0);
  final _netViewType = ValueNotifier(NetViewType.speed);

  final _pushToken = ValueNotifier<String?>(null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _s = S.of(context)!;
    final localeSettingVal = _setting.locale.fetch();
    if (localeSettingVal.isEmpty) {
      _localeCode.value = _s.localeName;
    } else {
      _localeCode.value = localeSettingVal;
    }
  }

  @override
  void initState() {
    super.initState();
    _nightMode.value = _setting.themeMode.fetch();
    _updateInterval.value = _setting.serverStatusUpdateInterval.fetch();
    _maxRetryCount.value = _setting.maxRetryCount.fetch();
    _selectedColorValue.value = _setting.primaryColor.fetch();
    _termFontSize.value = _setting.termFontSize.fetch();
    _editorFontSize.value = _setting.editorFontSize.fetch();
    _editorTheme.value = _setting.editorTheme.fetch();
    _editorDarkTheme.value = _setting.editorDarkTheme.fetch();
    _keyboardType.value = _setting.keyboardType.fetch();
    _rotateQuarter.value = _setting.fullScreenRotateQuarter.fetch();
    _netViewType.value = _setting.netViewType.fetch();
    SharedPreferences.getInstance().then((value) => _sp = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(_s.setting),
        actions: [
          InkWell(
            onTap: () => context.showRoundDialog(
              title: Text(_s.attention),
              child: Text(_s.sureDelete(_s.all)),
              actions: [
                TextButton(
                  onPressed: () {
                    _setting.box.deleteAll(_setting.box.keys);
                    context.pop();
                    context.showSnackBar(_s.success);
                  },
                  child: Text(_s.ok, style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
            onDoubleTap: () => context.showRoundDialog(
              title: Text(_s.attention),
              child: Text(_s.sureDelete(_s.all)),
              actions: [
                TextButton(
                  onPressed: () {
                    Stores.docker.box.deleteFromDisk();
                    Stores.server.box.deleteFromDisk();
                    Stores.setting.box.deleteFromDisk();
                    Stores.history.box.deleteFromDisk();
                    Stores.snippet.box.deleteFromDisk();
                    Stores.key.box.deleteFromDisk();
                    context.pop();
                    context.showSnackBar(_s.success);
                  },
                  child: Text(_s.ok, style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
            child: const Icon(Icons.delete),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 17),
        children: [
          _buildTitle('App'),
          _buildApp(),
          _buildTitle(_s.server),
          _buildServer(),
          _buildTitle('SSH'),
          _buildSSH(),
          _buildTitle(_s.editor),
          _buildEditor(),
          _buildTitle(_s.fullScreen),
          _buildFullScreen(),
          const SizedBox(height: 37),
        ],
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 23, bottom: 17),
      child: Center(
        child: Text(
          text,
          style: UIs.textGrey,
        ),
      ),
    );
  }

  Widget _buildApp() {
    final children = [
      _buildLocale(),
      _buildThemeMode(),
      _buildAppColor(),
      //_buildLaunchPage(),
      _buildCheckUpdate(),
    ];
    if (isIOS) {
      children.add(_buildPushToken());
      children.add(_buildAutoUpdateHomeWidget());
      children.add(_buildWatchApp());
    }
    if (isAndroid) {
      children.add(_buildBgRun());
      children.add(_buildAndroidWidgetSharedPreference());
    }
    // Put this at the end, because it will make a padding if not available
    children.add(_buildBioAuth());
    return Column(
      children: children.map((e) => RoundRectCard(e)).toList(),
    );
  }

  Widget _buildFullScreen() {
    return Column(
      children: [
        _buildFullScreenSwitch(),
        _buildFullScreenJitter(),
        _buildFulScreenRotateQuarter(),
      ].map((e) => RoundRectCard(e)).toList(),
    );
  }

  Widget _buildServer() {
    return Column(
      children: [
        _buildMoveOutServerFuncBtns(),
        _buildServerOrder(),
        _buildServerDetailOrder(),
        _buildNetViewType(),
        _buildUpdateInterval(),
        _buildMaxRetry(),
        //_buildDiskIgnorePath(),
        _buildDeleteServers(),
        //if (isDesktop) _buildDoubleColumnServersPage(),
      ].map((e) => RoundRectCard(e)).toList(),
    );
  }

  Widget _buildSSH() {
    return Column(
      children: [
        _buildFont(),
        _buildTermFontSize(),
        _buildSSHVirtualKeyAutoOff(),
        // Use hardware keyboard on desktop, so there is no need to set it
        if (isMobile) _buildKeyboardType(),
        _buildSSHVirtKeys(),
        _buildSftpRmrfDir(),
      ].map((e) => RoundRectCard(e)).toList(),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        _buildEditorFontSize(),
        _buildEditorTheme(),
        _buildEditorDarkTheme(),
      ].map((e) => RoundRectCard(e)).toList(),
    );
  }

  Widget _buildCheckUpdate() {
    return Consumer<AppProvider>(
      builder: (ctx, app, __) {
        String display;
        if (app.newestBuild != null) {
          if (app.newestBuild! > BuildData.build) {
            display = _s.versionHaveUpdate(app.newestBuild!);
          } else {
            display = _s.versionUpdated(BuildData.build);
          }
        } else {
          display = _s.versionUnknownUpdate(BuildData.build);
        }
        return ListTile(
          title: Text(_s.autoCheckUpdate),
          subtitle: Text(display, style: UIs.textGrey),
          onTap: () => doUpdate(ctx, force: true),
          trailing: StoreSwitch(prop: _setting.autoCheckAppUpdate),
        );
      },
    );
  }

  Widget _buildUpdateInterval() {
    final items = List.generate(
      10,
      (index) => PopupMenuItem(
        value: index,
        child: Text('$index ${_s.second}'),
      ),
      growable: false,
    ).toList();

    return ListTile(
      title: Text(
        _s.updateServerStatusInterval,
      ),
      subtitle: Text(
        _s.willTakEeffectImmediately,
        style: UIs.textGrey,
      ),
      onTap: () {
        _updateIntervalKey.currentState?.showButtonMenu();
      },
      trailing: ValueBuilder(
        listenable: _updateInterval,
        build: () => PopupMenuButton(
          key: _updateIntervalKey,
          itemBuilder: (_) => items,
          initialValue: _updateInterval.value,
          onSelected: (int val) {
            _updateInterval.value = val;
            _setting.serverStatusUpdateInterval.put(val);
            Providers.server.startAutoRefresh();
            if (val == 0) {
              context.showSnackBar(_s.updateIntervalEqual0);
            }
          },
          child: Text(
            '${_updateInterval.value} ${_s.second}',
            style: UIs.textSize15,
          ),
        ),
      ),
    );
  }

  Widget _buildAppColor() {
    return ListTile(
      trailing: ClipOval(
        child: Container(
          color: primaryColor,
          height: 27,
          width: 27,
        ),
      ),
      title: Text(_s.primaryColorSeed),
      onTap: () async {
        final ctrl = TextEditingController(text: primaryColor.toHex);
        await context.showRoundDialog(
            title: Text(_s.primaryColorSeed),
            child: StatefulBuilder(builder: (context, setState) {
              final children = <Widget>[
                /// Plugin [dynamic_color] is not supported on iOS
                if (!isIOS)
                  ListTile(
                    title: Text(_s.followSystem),
                    trailing: StoreSwitch(
                      prop: _setting.useSystemPrimaryColor,
                      func: (_) => setState(() {}),
                    ),
                  )
              ];
              if (!_setting.useSystemPrimaryColor.fetch()) {
                children.addAll([
                  Input(
                    onSubmitted: _onSaveColor,
                    controller: ctrl,
                    hint: '#8b2252',
                    icon: Icons.colorize,
                  ),
                  ColorPicker(
                    color: primaryColor,
                    onColorChanged: (c) => ctrl.text = c.toHex,
                  )
                ]);
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: children,
              );
            }),
            actions: [
              TextButton(
                onPressed: () => _onSaveColor(ctrl.text),
                child: Text(_s.ok),
              ),
            ]);
      },
    );
  }

  void _onSaveColor(String s) {
    final color = s.hexToColor;
    if (color == null) {
      context.showSnackBar(_s.failed);
      return;
    }
    _selectedColorValue.value = color.value;
    _setting.primaryColor.put(_selectedColorValue.value);
    primaryColor = color;
    context.pop();
    context.showRestartSnackbar(btn: _s.restart, msg: _s.needRestart);
  }

  // Widget _buildLaunchPage() {
  //   final items = AppTab.values
  //       .map(
  //         (e) => PopupMenuItem(
  //           value: e.index,
  //           child: Text(tabTitleName(context, e)),
  //         ),
  //       )
  //       .toList();

  //   return ListTile(
  //     title: Text(
  //       _s.launchPage,
  //     ),
  //     onTap: () {
  //       _startPageKey.currentState?.showButtonMenu();
  //     },
  //     trailing: ValueBuilder(
  //       listenable: _launchPageIdx,
  //       build: () => PopupMenuButton(
  //         key: _startPageKey,
  //         itemBuilder: (BuildContext context) => items,
  //         initialValue: _launchPageIdx.value,
  //         onSelected: (int idx) {
  //           _launchPageIdx.value = idx;
  //           _setting.launchPage.put(_launchPageIdx.value);
  //         },
  //         child: ConstrainedBox(
  //           constraints: BoxConstraints(maxWidth: _media.size.width * 0.35),
  //           child: Text(
  //             tabTitleName(context, AppTab.values[_launchPageIdx.value]),
  //             textAlign: TextAlign.right,
  //             style: textSize15,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildMaxRetry() {
    final items = List.generate(
      10,
      (index) => PopupMenuItem(
        value: index,
        child: Text('$index ${_s.times}'),
      ),
      growable: false,
    ).toList();
    final help =
        _maxRetryCount.value == 0 ? _s.maxRetryCountEqual0 : _s.canPullRefresh;

    return ListTile(
      title: Text(
        _s.maxRetryCount,
        textAlign: TextAlign.start,
      ),
      subtitle: Text(help, style: UIs.textGrey),
      onTap: () {
        _maxRetryKey.currentState?.showButtonMenu();
      },
      trailing: ValueBuilder(
        build: () => PopupMenuButton(
          key: _maxRetryKey,
          itemBuilder: (BuildContext context) => items,
          initialValue: _maxRetryCount.value,
          onSelected: (int val) {
            _maxRetryCount.value = val;
            _setting.maxRetryCount.put(_maxRetryCount.value);
          },
          child: Text(
            '${_maxRetryCount.value} ${_s.times}',
            style: UIs.textSize15,
          ),
        ),
        listenable: _maxRetryCount,
      ),
    );
  }

  Widget _buildThemeMode() {
    final items = ThemeMode.values
        .map(
          (e) => PopupMenuItem(
            value: e.index,
            child: Text(_buildThemeModeStr(e.index)),
          ),
        )
        .toList();
    // Issue #57
    final len = ThemeMode.values.length;
    items.add(PopupMenuItem(value: len, child: Text(_buildThemeModeStr(len))));

    return ListTile(
      title: Text(
        _s.themeMode,
      ),
      onTap: () {
        _themeKey.currentState?.showButtonMenu();
      },
      trailing: ValueBuilder(
        listenable: _nightMode,
        build: () => PopupMenuButton(
          key: _themeKey,
          itemBuilder: (BuildContext context) => items,
          initialValue: _nightMode.value,
          onSelected: (int idx) {
            _nightMode.value = idx;
            _setting.themeMode.put(_nightMode.value);
          },
          child: Text(
            _buildThemeModeStr(_nightMode.value),
            style: UIs.textSize15,
          ),
        ),
      ),
    );
  }

  String _buildThemeModeStr(int n) {
    switch (n) {
      case 1:
        return _s.light;
      case 2:
        return _s.dark;
      case 3:
        return 'AMOLED';
      default:
        return _s.auto;
    }
  }

  Widget _buildPushToken() {
    return ListTile(
      title: Text(
        _s.pushToken,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.zero,
        onPressed: () {
          if (_pushToken.value != null) {
            copy2Clipboard(_pushToken.value!);
            context.showSnackBar(_s.success);
          } else {
            context.showSnackBar(_s.getPushTokenFailed);
          }
        },
      ),
      subtitle: FutureWidget<String?>(
        future: getToken(),
        loading: Text(_s.gettingToken),
        error: (error, trace) => Text('${_s.error}: $error'),
        noData: Text(_s.nullToken),
        success: (text) {
          _pushToken.value = text;
          return Text(
            text ?? _s.nullToken,
            style: UIs.textGrey,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          );
        },
      ),
    );
  }

  Widget _buildFont() {
    final fontName = getFileName(_setting.fontPath.fetch());
    return ListTile(
      title: Text(_s.font),
      trailing: Text(
        fontName ?? _s.notSelected,
        style: UIs.textSize15,
      ),
      onTap: () {
        context.showRoundDialog(
          title: Text(_s.font),
          actions: [
            TextButton(
              onPressed: () async => await _pickFontFile(),
              child: Text(_s.pickFile),
            ),
            TextButton(
              onPressed: () {
                _setting.fontPath.delete();
                context.pop();
                context.showRestartSnackbar(
                  btn: _s.restart,
                  msg: _s.needRestart,
                );
              },
              child: Text(_s.clear),
            )
          ],
        );
      },
    );
  }

  Future<void> _pickFontFile() async {
    final path = await pickOneFile();
    if (path != null) {
      // iOS can't copy file to app dir, so we need to use the original path
      if (isIOS) {
        _setting.fontPath.put(path);
      } else {
        final fontFile = File(path);
        final newPath = '${await Paths.font}/${path.split('/').last}';
        await fontFile.copy(newPath);
        _setting.fontPath.put(newPath);
      }

      context.pop();
      context.showRestartSnackbar(btn: _s.restart, msg: _s.needRestart);
      return;
    }
    context.showSnackBar(_s.failed);
  }

  Widget _buildBgRun() {
    return ListTile(
      title: Text(_s.bgRun),
      trailing: StoreSwitch(prop: _setting.bgRun),
    );
  }

  Widget _buildTermFontSize() {
    return ValueBuilder(
      listenable: _termFontSize,
      build: () => ListTile(
        title: Text(_s.fontSize),
        trailing: Text(
          _termFontSize.value.toString(),
          style: UIs.textSize15,
        ),
        onTap: () => _showFontSizeDialog(_termFontSize, _setting.termFontSize),
      ),
    );
  }

  // Widget _buildDiskIgnorePath() {
  //   final paths = _setting.diskIgnorePath.fetch();
  //   return ListTile(
  //     title: Text(_s.diskIgnorePath),
  //     trailing: Text(_s.edit, style: textSize15),
  //     onTap: () {
  //       final ctrller = TextEditingController(text: json.encode(paths));
  //       void onSubmit() {
  //         try {
  //           final list = List<String>.from(json.decode(ctrller.text));
  //           _setting.diskIgnorePath.put(list);
  //           context.pop();
  //           showSnackBar(context, Text(_s.success));
  //         } catch (e) {
  //           showSnackBar(context, Text(e.toString()));
  //         }
  //       }

  //       showRoundDialog(
  //         context: context,
  //         title: Text(_s.diskIgnorePath),
  //         child: Input(
  //           autoFocus: true,
  //           controller: ctrller,
  //           label: 'JSON',
  //           type: TextInputType.visiblePassword,
  //           maxLines: 3,
  //           onSubmitted: (_) => onSubmit(),
  //         ),
  //         actions: [
  //           TextButton(onPressed: onSubmit, child: Text(_s.ok)),
  //         ],
  //       );
  //     },
  //   );
  // }

  Widget _buildLocale() {
    final items = S.supportedLocales
        .map(
          (e) => PopupMenuItem<String>(
            value: e.code,
            child: Text(e.code),
          ),
        )
        .toList();
    return ListTile(
      title: Text(_s.language),
      onTap: () {
        _localeKey.currentState?.showButtonMenu();
      },
      trailing: ValueBuilder(
        listenable: _localeCode,
        build: () => PopupMenuButton(
          key: _localeKey,
          itemBuilder: (BuildContext context) => items,
          initialValue: _localeCode.value,
          onSelected: (String idx) {
            _localeCode.value = idx;
            _setting.locale.put(idx);
            context.showRestartSnackbar(btn: _s.restart, msg: _s.needRestart);
          },
          child: Text(
            _s.languageName,
            style: UIs.textSize15,
          ),
        ),
      ),
    );
  }

  Widget _buildSSHVirtualKeyAutoOff() {
    return ListTile(
      title: Text(_s.sshVirtualKeyAutoOff),
      subtitle: const Text('Ctrl & Alt', style: UIs.textGrey),
      trailing: StoreSwitch(prop: _setting.sshVirtualKeyAutoOff),
    );
  }

  Widget _buildEditorTheme() {
    final items = themeMap.keys.map(
      (key) {
        return PopupMenuItem<String>(
          value: key,
          child: Text(key),
        );
      },
    ).toList();
    return ListTile(
      title: Text('${_s.light} ${_s.theme.toLowerCase()}'),
      trailing: ValueBuilder(
        listenable: _editorTheme,
        build: () => PopupMenuButton(
          key: _editorThemeKey,
          itemBuilder: (BuildContext context) => items,
          initialValue: _editorTheme.value,
          onSelected: (String idx) {
            _editorTheme.value = idx;
            _setting.editorTheme.put(idx);
          },
          child: Text(
            _editorTheme.value,
            style: UIs.textSize15,
          ),
        ),
      ),
      onTap: () {
        _editorThemeKey.currentState?.showButtonMenu();
      },
    );
  }

  Widget _buildEditorDarkTheme() {
    final items = themeMap.keys.map(
      (key) {
        return PopupMenuItem<String>(
          value: key,
          child: Text(key),
        );
      },
    ).toList();
    return ListTile(
      title: Text('${_s.dark} ${_s.theme.toLowerCase()}'),
      trailing: ValueBuilder(
        listenable: _editorDarkTheme,
        build: () => PopupMenuButton(
          key: _editorDarkThemeKey,
          itemBuilder: (BuildContext context) => items,
          initialValue: _editorDarkTheme.value,
          onSelected: (String idx) {
            _editorDarkTheme.value = idx;
            _setting.editorDarkTheme.put(idx);
          },
          child: Text(
            _editorDarkTheme.value,
            style: UIs.textSize15,
          ),
        ),
      ),
      onTap: () {
        _editorDarkThemeKey.currentState?.showButtonMenu();
      },
    );
  }

  Widget _buildFullScreenSwitch() {
    return ListTile(
      title: Text(_s.fullScreen),
      trailing: StoreSwitch(
        prop: _setting.fullScreen,
        func: (_) => context.showRestartSnackbar(
          btn: _s.restart,
          msg: _s.needRestart,
        ),
      ),
    );
  }

  Widget _buildFullScreenJitter() {
    return ListTile(
      title: Text(_s.fullScreenJitter),
      subtitle: Text(_s.fullScreenJitterHelp, style: UIs.textGrey),
      trailing: StoreSwitch(prop: _setting.fullScreenJitter),
    );
  }

  Widget _buildFulScreenRotateQuarter() {
    final degrees = List.generate(4, (idx) => '${idx * 90}°').toList();
    final items = List.generate(4, (idx) {
      return PopupMenuItem<int>(
        value: idx,
        child: Text(degrees[idx]),
      );
    }).toList();

    return ListTile(
      title: Text(_s.rotateAngel),
      onTap: () {
        _rotateQuarterKey.currentState?.showButtonMenu();
      },
      trailing: ValueBuilder(
        listenable: _rotateQuarter,
        build: () => PopupMenuButton(
          key: _rotateQuarterKey,
          itemBuilder: (BuildContext context) => items,
          initialValue: _rotateQuarter.value,
          onSelected: (int idx) {
            _rotateQuarter.value = idx;
            _setting.fullScreenRotateQuarter.put(idx);
          },
          child: Text(
            degrees[_rotateQuarter.value],
            style: UIs.textSize15,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardType() {
    const List<String> names = <String>[
      'text',
      'multiline',
      'number',
      'phone',
      'datetime',
      'emailAddress',
      'url',
      'visiblePassword',
      'name',
      'address',
      'none',
    ];
    if (names.length != TextInputType.values.length) {
      // This notify me to update the code
      throw Exception('names.length != TextInputType.values.length');
    }
    final items = TextInputType.values.map(
      (key) {
        return PopupMenuItem<int>(
          value: key.index,
          child: Text(names[key.index]),
        );
      },
    ).toList();
    return ListTile(
      title: Text(_s.keyboardType),
      subtitle: Text(_s.keyboardCompatibility, style: UIs.textGrey),
      trailing: ValueBuilder(
        listenable: _keyboardType,
        build: () => PopupMenuButton<int>(
          key: _keyboardTypeKey,
          itemBuilder: (BuildContext context) => items,
          initialValue: _keyboardType.value,
          onSelected: (idx) {
            _keyboardType.value = idx;
            _setting.keyboardType.put(idx);
          },
          child: Text(
            names[_keyboardType.value],
            style: UIs.textSize15,
          ),
        ),
      ),
      onTap: () {
        _keyboardTypeKey.currentState?.showButtonMenu();
      },
    );
  }

  Widget _buildSSHVirtKeys() {
    return ListTile(
      title: Text(_s.editVirtKeys),
      trailing: const Icon(Icons.keyboard_arrow_right),
      onTap: () => AppRoute.sshVirtKeySetting().go(context),
    );
  }

  void _saveWidgetSP(String data, Map<String, String> old) {
    context.pop();
    try {
      final map = Map<String, String>.from(json.decode(data));
      final keysDel = old.keys.toSet().difference(map.keys.toSet());
      for (final key in keysDel) {
        _sp.remove(key);
      }
      map.forEach((key, value) {
        _sp.setString(key, value);
      });
      context.showSnackBar(_s.success);
    } catch (e) {
      context.showSnackBar(e.toString());
    }
  }

  Widget _buildAndroidWidgetSharedPreference() {
    return ListTile(
      title: Text(_s.homeWidgetUrlConfig),
      trailing: const Icon(Icons.keyboard_arrow_right),
      onTap: () {
        final data = <String, String>{};
        _sp.getKeys().forEach((key) {
          final val = _sp.getString(key);
          if (val != null) {
            data[key] = val;
          }
        });
        final ctrl = TextEditingController(text: json.encode(data));
        context.showRoundDialog(
          title: Text(_s.homeWidgetUrlConfig),
          child: Input(
            autoFocus: true,
            controller: ctrl,
            label: 'JSON',
            type: TextInputType.visiblePassword,
            maxLines: 7,
            onSubmitted: (p0) => _saveWidgetSP(p0, data),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _saveWidgetSP(ctrl.text, data);
              },
              child: Text(_s.ok),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNetViewType() {
    final items = NetViewType.values
        .map((e) => PopupMenuItem(
              value: e,
              child: Text(e.l10n(_s)),
            ))
        .toList();
    return ListTile(
      title: Text(_s.netViewType),
      trailing: ValueBuilder(
        listenable: _netViewType,
        build: () => PopupMenuButton<NetViewType>(
          key: _netViewTypeKey,
          itemBuilder: (BuildContext context) => items,
          initialValue: _netViewType.value,
          onSelected: (idx) {
            _netViewType.value = idx;
            _setting.netViewType.put(idx);
          },
          child: Text(
            _netViewType.value.l10n(_s),
            style: UIs.textSize15,
          ),
        ),
      ),
      onTap: () {
        _netViewTypeKey.currentState?.showButtonMenu();
      },
    );
  }

  Widget _buildAutoUpdateHomeWidget() {
    return ListTile(
      title: Text(_s.autoUpdateHomeWidget),
      subtitle: Text(_s.whenOpenApp, style: UIs.textGrey),
      trailing: StoreSwitch(prop: _setting.autoUpdateHomeWidget),
    );
  }

  Widget _buildDeleteServers() {
    return ListTile(
      title: Text(_s.deleteServers),
      trailing: const Icon(Icons.delete_forever),
      onTap: () async {
        final all = Stores.server.box.keys.map(
          (e) => TextButton(
            onPressed: () => context.showRoundDialog(
              title: Text(_s.attention),
              child: Text(_s.sureDelete(e)),
              actions: [
                TextButton(
                  onPressed: () => Providers.server.delServer(e),
                  child: Text(_s.ok),
                )
              ],
            ),
            child: Text(e),
          ),
        );
        context.showRoundDialog<List<String>>(
          title: Text(_s.choose),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: all.toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoveOutServerFuncBtns() {
    return ListTile(
      title: Text(_s.moveOutServerFuncBtns),
      subtitle: Text(_s.moveOutServerFuncBtnsHelp, style: UIs.textSize13Grey),
      trailing: StoreSwitch(prop: _setting.moveOutServerTabFuncBtns),
    );
  }

  Widget _buildServerOrder() {
    return ListTile(
      title: Text(_s.serverOrder),
      trailing: const Icon(Icons.keyboard_arrow_right),
      onTap: () => AppRoute.serverOrder().go(context),
    );
  }

  Widget _buildServerDetailOrder() {
    return ListTile(
      title: Text(_s.serverDetailOrder),
      trailing: const Icon(Icons.keyboard_arrow_right),
      onTap: () => AppRoute.serverDetailOrder().go(context),
    );
  }

  Widget _buildEditorFontSize() {
    return ValueBuilder(
      listenable: _editorFontSize,
      build: () => ListTile(
        title: Text(_s.fontSize),
        trailing: Text(
          _editorFontSize.value.toString(),
          style: UIs.textSize15,
        ),
        onTap: () =>
            _showFontSizeDialog(_editorFontSize, _setting.editorFontSize),
      ),
    );
  }

  void _showFontSizeDialog(
    ValueNotifier<double> notifier,
    StorePropertyBase<double> property,
  ) {
    final ctrller = TextEditingController(text: notifier.value.toString());
    void onSave() {
      context.pop();
      final fontSize = double.tryParse(ctrller.text);
      if (fontSize == null) {
        context.showRoundDialog(
          title: Text(_s.failed),
          child: Text('Parsed failed: ${ctrller.text}'),
        );
        return;
      }
      notifier.value = fontSize;
      property.put(fontSize);
    }

    context.showRoundDialog(
      title: Text(_s.fontSize),
      child: Input(
        controller: ctrller,
        autoFocus: true,
        type: TextInputType.number,
        icon: Icons.font_download,
        onSubmitted: (_) => onSave(),
      ),
      actions: [
        TextButton(
          onPressed: onSave,
          child: Text(_s.ok),
        ),
      ],
    );
  }

  Widget _buildSftpRmrfDir() {
    return ListTile(
      title: const Text('rm -rf'),
      subtitle: Text(_s.sftpRmrfDirSummary, style: UIs.textGrey),
      trailing: StoreSwitch(prop: _setting.sftpRmrfDir),
    );
  }

  // Widget _buildDoubleColumnServersPage() {
  //   return ListTile(
  //     title: Text(_s.doubleColumnMode),
  //     trailing: StoreSwitch(prop: _setting.doubleColumnServersPage),
  //   );
  // }

  /// Setting item for configing watchOS app
  Widget _buildWatchApp() {
    final wc = WatchConnectivity();
    return FutureWidget(
      future: wc.isPaired,
      loading: ListTile(
        title: Text('watchApp'),
        subtitle: Text(_s.serverTabLoading),
      ),
      error: (e, __) => ListTile(
        title: Text('watchApp'),
        subtitle: Text('${_s.failed}: $e'),
      ),
      success: (_) => ListTile(
        title: Text('_s.watchApp'),
        trailing: const Icon(Icons.keyboard_arrow_right),
        onTap: () => _onWatchTap(wc),
      ),
      noData: UIs.placeholder,
    );
  }

  void _onWatchTap(WatchConnectivity wc) async {
    final raw = await wc.applicationContext;
    final urls = List<String>.from(raw['urls'] ?? []);
    await context.showRoundDialog(
      title: Text(_s.edit),
      child: SizedBox(
        height: 377,
        width: 377,
        child: StatefulBuilder(builder: (context, setState) {
          return ListView.builder(
            itemBuilder: (_, idx) {
              if (idx == urls.length) {
                return ListTile(
                  title: Text(_s.add),
                  onTap: () async {
                    final url = await context.showRoundDialog<String>(
                      title: Text(_s.add),
                      child: Input(
                        autoFocus: true,
                        label: 'URL',
                        icon: Icons.link,
                        onSubmitted: (url) => context.pop(url),
                      ),
                    );
                    if (url != null) {
                      urls.add(url);
                      await wc.updateApplicationContext({'urls': urls});
                      setState(() {});
                    }
                  },
                );
              }
              final url = urls[idx];
              return ListTile(
                title: Text(url),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    urls.removeAt(idx);
                    await wc.updateApplicationContext({'urls': urls});
                    setState(() {});
                  },
                ),
              );
            },
            itemCount: urls.length + 1,
          );
        }),
      ),
    );
  }

  Widget _buildBioAuth() {
    return FutureWidget<bool>(
      future: isBioAuthAvail,
      loading: UIs.placeholder,
      error: (e, __) => ListTile(
        title: Text(_s.bioAuth),
        subtitle: Text('${_s.failed}: $e'),
      ),
      success: (can) {
        return ListTile(
          title: Text(_s.bioAuth),
          trailing: can
              ? StoreSwitch(
                  prop: Stores.setting.useBioAuth,
                  func: (val) async {
                    if (val) {
                      if (!await isBioAuthAvail) {
                        Stores.setting.useBioAuth.put(false);
                      }
                      return;
                    }
                    // Only auth when turn off (val == false)
                    final result = await authBio();
                    // If failed, turn on again
                    if (result != AuthResult.success) {
                      Stores.setting.useBioAuth.put(true);
                    }
                  },
                )
              : null,
        );
      },
      noData: UIs.placeholder,
    );
  }
}
