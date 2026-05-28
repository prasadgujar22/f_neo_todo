import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notifications/app_notification_scheduler.dart';
import 'notifications/notification_models.dart';
import 'platform/due_date_picker.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _viteSupabaseUrl = String.fromEnvironment('VITE_SUPABASE_URL');
const _viteSupabaseAnonKey = String.fromEnvironment('VITE_SUPABASE_ANON_KEY');
const _phoneLayoutWidth = 620.0;

String get _configuredSupabaseUrl =>
    _supabaseUrl.isNotEmpty ? _supabaseUrl : _viteSupabaseUrl;

String get _configuredSupabaseAnonKey =>
    _supabaseAnonKey.isNotEmpty ? _supabaseAnonKey : _viteSupabaseAnonKey;

bool get _isSupabaseConfigured =>
    _configuredSupabaseUrl.isNotEmpty && _configuredSupabaseAnonKey.isNotEmpty;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_isSupabaseConfigured) {
    await Supabase.initialize(
      url: _configuredSupabaseUrl,
      anonKey: _configuredSupabaseAnonKey,
    );
  }
  runApp(const NeoTodoApp());
}

class NeoTodoApp extends StatelessWidget {
  const NeoTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6D28D9);

    return MaterialApp(
      title: 'Neo To-Do',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildTheme(Brightness.light, seed),
      darkTheme: _buildTheme(Brightness.dark, seed),
      home: const TodoHomePage(),
    );
  }
}

ThemeData _buildTheme(Brightness brightness, Color seed) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: colorScheme.surfaceContainerLow,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      prefixIconColor: colorScheme.onSurfaceVariant,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(
        color: colorScheme.onInverseSurface,
        fontSize: 12,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

enum TodoPriority {
  low('Low'),
  medium('Med'),
  high('High');

  const TodoPriority(this.label);

  final String label;

  TodoPriority get next {
    final values = TodoPriority.values;
    return values[(index + 1) % values.length];
  }
}

enum TodoSortMode {
  manual('Manual', Icons.drag_indicator),
  dueAsc('Due earliest', Icons.arrow_upward),
  dueDesc('Due latest', Icons.arrow_downward);

  const TodoSortMode(this.label, this.icon);

  final String label;
  final IconData icon;
}

class TodoItem {
  const TodoItem({
    required this.id,
    required this.text,
    required this.priority,
    required this.createdAt,
    required this.sortOrder,
    this.completed = false,
    this.dueDate,
    this.groupId,
  });

  final String id;
  final String text;
  final TodoPriority priority;
  final DateTime createdAt;
  final int sortOrder;
  final bool completed;
  final DateTime? dueDate;
  final String? groupId;

  TodoItem copyWith({
    String? text,
    TodoPriority? priority,
    DateTime? createdAt,
    int? sortOrder,
    bool? completed,
    DateTime? dueDate,
    String? groupId,
    bool clearDueDate = false,
    bool clearGroup = false,
  }) {
    return TodoItem(
      id: id,
      text: text ?? this.text,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
      completed: completed ?? this.completed,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      groupId: clearGroup ? null : groupId ?? this.groupId,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'text': text,
    'priority': priority.name,
    'createdAt': createdAt.toIso8601String(),
    'sortOrder': sortOrder,
    'completed': completed,
    'dueDate': dueDate?.toIso8601String(),
    'groupId': groupId,
  };

  static TodoItem? fromJson(Object? value) {
    if (value is! Map) return null;
    final text = '${value['text'] ?? ''}'.trim();
    if (text.isEmpty) return null;
    return TodoItem(
      id: '${value['id'] ?? DateTime.now().microsecondsSinceEpoch}',
      text: text,
      priority: TodoPriority.values.firstWhere(
        (priority) => priority.name == value['priority'],
        orElse: () => TodoPriority.medium,
      ),
      createdAt:
          DateTime.tryParse('${value['createdAt'] ?? ''}') ?? DateTime.now(),
      sortOrder:
          int.tryParse('${value['sortOrder'] ?? ''}') ??
          DateTime.now().microsecondsSinceEpoch,
      completed: value['completed'] == true,
      dueDate: DateTime.tryParse('${value['dueDate'] ?? ''}'),
      groupId: value['groupId'] == null || value['groupId'] == ''
          ? null
          : '${value['groupId']}',
    );
  }
}

class TodoGroup {
  const TodoGroup({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;

  TodoGroup copyWith({String? title}) {
    return TodoGroup(id: id, title: title ?? this.title, createdAt: createdAt);
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
  };

  static TodoGroup? fromJson(Object? value) {
    if (value is! Map) return null;
    final title = '${value['title'] ?? ''}'.trim();
    if (title.isEmpty) return null;
    return TodoGroup(
      id: '${value['id'] ?? DateTime.now().microsecondsSinceEpoch}',
      title: title,
      createdAt:
          DateTime.tryParse('${value['createdAt'] ?? ''}') ?? DateTime.now(),
    );
  }
}

class _UndoSnapshot {
  const _UndoSnapshot({
    required this.message,
    required this.todos,
    required this.groups,
  });

  final String message;
  final List<TodoItem> todos;
  final List<TodoGroup> groups;
}

class _RemoteTodoState {
  const _RemoteTodoState({
    required this.todos,
    required this.groups,
    required this.initialized,
    required this.updatedAt,
  });

  final List<TodoItem> todos;
  final List<TodoGroup> groups;
  final bool initialized;
  final String? updatedAt;

  bool get hasContent => todos.isNotEmpty || groups.isNotEmpty;
}

class _RemoteStateConflictException implements Exception {
  const _RemoteStateConflictException();

  @override
  String toString() {
    return 'Remote tasks changed on another device. Refresh to load the latest tasks before saving again.';
  }
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage>
    with WidgetsBindingObserver {
  static const _storageKey = 'neo_todo_flutter.state.v1';
  static const _ungroupedKey = 'ungrouped';

  final _taskController = TextEditingController();
  final _groupController = TextEditingController();
  final _notificationScheduler = AppNotificationScheduler();
  final SupabaseClient? _supabase = _isSupabaseConfigured
      ? Supabase.instance.client
      : null;
  final List<TodoItem> _todos = [
    TodoItem(
      id: 'sample-domain',
      text: 'Port todo domain model to Dart',
      priority: TodoPriority.high,
      createdAt: DateTime.now(),
      sortOrder: 0,
      dueDate: DateTime.now().add(const Duration(hours: 2)),
    ),
    TodoItem(
      id: 'sample-notifications',
      text: 'Wire native notification scheduler',
      priority: TodoPriority.medium,
      createdAt: DateTime.now(),
      sortOrder: 1,
    ),
    TodoItem(
      id: 'sample-sync',
      text: 'Reuse Supabase sync contract',
      priority: TodoPriority.low,
      createdAt: DateTime.now(),
      sortOrder: 2,
      completed: true,
    ),
  ];
  final List<TodoGroup> _groups = [];
  final Set<String> _collapsedGroups = <String>{};
  final Map<String, TodoSortMode> _groupSortModes = <String, TodoSortMode>{};

  TodoPriority _selectedPriority = TodoPriority.medium;
  String? _selectedGroupId;
  DateTime? _newTodoDueDate;
  _UndoSnapshot? _undo;
  bool _notificationsEnabled = false;
  NotificationPermissionState _notificationPermission =
      NotificationPermissionState.unknown;
  NotificationCapability _notificationCapability =
      NotificationCapability.unsupported;
  String? _draggingTodoId;
  StreamSubscription<AuthState>? _authSubscription;
  Session? _session;
  Timer? _remoteSaveDebounce;
  Future<void> _remoteSaveQueue = Future.value();
  String _syncStatus = _isSupabaseConfigured ? 'Connecting...' : 'Local mode';
  String _syncError = '';
  String? _remoteUpdatedAt;
  bool _authBusy = false;
  bool _remoteReady = false;
  bool _userMutated = false;
  int _saveRun = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLocalState();
    _initializeNotifications();
    _initializeSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _remoteSaveDebounce?.cancel();
    _taskController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final groups = (decoded['groups'] as List? ?? const [])
          .map(TodoGroup.fromJson)
          .nonNulls
          .toList();
      final groupIds = groups.map((group) => group.id).toSet();
      final todos = (decoded['todos'] as List? ?? const [])
          .map(TodoItem.fromJson)
          .nonNulls
          .map(
            (todo) => groupIds.contains(todo.groupId)
                ? todo
                : todo.copyWith(clearGroup: true),
          )
          .toList();
      final collapsedGroups = (decoded['collapsedGroups'] as List? ?? const [])
          .map((id) => '$id')
          .where(groupIds.contains)
          .toSet();
      final groupSortModes = <String, TodoSortMode>{};
      final rawSortModes = decoded['groupSortModes'];
      if (rawSortModes is Map) {
        for (final entry in rawSortModes.entries) {
          final key = '${entry.key}';
          if (key != _ungroupedKey && !groupIds.contains(key)) continue;
          groupSortModes[key] = TodoSortMode.values.firstWhere(
            (mode) => mode.name == entry.value,
            orElse: () => TodoSortMode.dueAsc,
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _groups
          ..clear()
          ..addAll(groups);
        _todos
          ..clear()
          ..addAll(todos);
        _collapsedGroups
          ..clear()
          ..addAll(collapsedGroups);
        _groupSortModes
          ..clear()
          ..addAll(groupSortModes);
      });
      await _reconcileNotifications();
    } catch (_) {
      // Ignore invalid local state and keep the bundled starter tasks.
    }
  }

  Future<void> _saveLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'todos': _todos.map((todo) => todo.toJson()).toList(),
        'groups': _groups.map((group) => group.toJson()).toList(),
        'collapsedGroups': _collapsedGroups.toList(),
        'groupSortModes': _groupSortModes.map(
          (key, mode) => MapEntry(key, mode.name),
        ),
      }),
    );
  }

  void _persistAndSync({bool reconcileNotifications = false}) {
    _saveLocalState();
    if (reconcileNotifications) _reconcileNotifications();
    _userMutated = true;
    _scheduleRemoteSave();
  }

  void _persistAndReconcile() {
    _persistAndSync(reconcileNotifications: true);
  }

  void _captureUndo(String message) {
    _undo = _UndoSnapshot(
      message: message,
      todos: List<TodoItem>.of(_todos),
      groups: List<TodoGroup>.of(_groups),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reconcileNotifications();
    }
  }

  Future<void> _initializeNotifications() async {
    await _notificationScheduler.initialize();
    if (!mounted) return;

    setState(() {
      _notificationCapability = _notificationScheduler.capability;
      _notificationPermission = _notificationScheduler.permissionState;
      _notificationsEnabled =
          _notificationPermission == NotificationPermissionState.granted;
    });
    await _reconcileNotifications();
  }

  Future<void> _setNotificationsEnabled(bool enabled) async {
    if (!enabled) {
      setState(() => _notificationsEnabled = false);
      await _reconcileNotifications();
      return;
    }

    final permission = await _notificationScheduler.requestPermission();
    if (!mounted) return;

    setState(() {
      _notificationPermission = permission;
      _notificationCapability = _notificationScheduler.capability;
      _notificationsEnabled = permission == NotificationPermissionState.granted;
    });
    await _reconcileNotifications();
  }

  void _initializeSync() {
    final supabase = _supabase;
    if (supabase == null) return;

    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final nextSession = data.session;
      setState(() {
        _session = nextSession;
        _authBusy = false;
        if (nextSession == null) {
          _syncStatus = 'Local mode';
          _syncError = '';
          _remoteUpdatedAt = null;
          _remoteReady = false;
        }
      });
      if (nextSession != null) {
        _loadRemoteForSession(nextSession);
      }
    });

    final currentSession = supabase.auth.currentSession;
    setState(() {
      _session = currentSession;
      _authBusy = false;
      _syncStatus = currentSession == null ? 'Local mode' : 'Connecting...';
    });
    if (currentSession != null) {
      _loadRemoteForSession(currentSession);
    }
  }

  Future<void> _signInWithGoogle() async {
    final supabase = _supabase;
    if (supabase == null) return;
    setState(() {
      _authBusy = true;
      _syncError = '';
    });

    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? _currentWebRedirectUrl() : null,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _authBusy = false;
        _syncStatus = 'Auth failed';
        _syncError = '$error';
      });
    }
  }

  Future<void> _signOut() async {
    final supabase = _supabase;
    if (supabase == null) return;
    setState(() {
      _authBusy = true;
      _syncError = '';
    });
    try {
      await supabase.auth.signOut(scope: SignOutScope.local);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _authBusy = false;
        _syncStatus = 'Sign out failed';
        _syncError = '$error';
      });
    }
  }

  Future<void> _loadRemoteForSession(Session session) async {
    setState(() {
      _syncStatus = 'Syncing...';
      _syncError = '';
      _remoteReady = false;
    });

    try {
      final remote = await _loadRemoteTodoState(session.user.id);
      if (!mounted || _session?.user.id != session.user.id) return;

      final hasLocalState = _todos.isNotEmpty || _groups.isNotEmpty;
      if (remote.initialized || remote.hasContent) {
        setState(() {
          _userMutated = false;
          _remoteUpdatedAt = remote.updatedAt;
          _groups
            ..clear()
            ..addAll(remote.groups);
          _todos
            ..clear()
            ..addAll(remote.todos);
          _selectedGroupId =
              _groups.any((group) => group.id == _selectedGroupId)
              ? _selectedGroupId
              : null;
        });
        await _saveLocalState();
        await _reconcileNotifications();
      } else if (hasLocalState) {
        _userMutated = true;
        final saved = await _saveRemoteTodoState(session.user.id, null);
        _remoteUpdatedAt = saved;
      }

      if (!mounted || _session?.user.id != session.user.id) return;
      setState(() {
        _remoteReady = true;
        _syncStatus = 'Synced';
        _syncError = '';
      });
    } catch (error) {
      if (!mounted || _session?.user.id != session.user.id) return;
      setState(() {
        _syncStatus = 'Sync failed';
        _syncError = '$error';
      });
    }
  }

  void _scheduleRemoteSave() {
    final session = _session;
    if (_supabase == null || session == null || !_remoteReady) return;
    _remoteSaveDebounce?.cancel();
    _remoteSaveDebounce = Timer(const Duration(milliseconds: 700), () {
      _saveRemoteAfterMutation(session.user.id);
    });
  }

  Future<void> _saveRemoteAfterMutation(String userId) async {
    if (!_userMutated) return;
    final saveRun = _saveRun + 1;
    _saveRun = saveRun;
    setState(() {
      _syncStatus = 'Saving...';
      _syncError = '';
    });

    _remoteSaveQueue = _remoteSaveQueue.catchError((_) {}).then((_) async {
      final updatedAt = await _saveRemoteTodoState(userId, _remoteUpdatedAt);
      _remoteUpdatedAt = updatedAt;
    });

    try {
      await _remoteSaveQueue;
      if (!mounted || _saveRun != saveRun) return;
      setState(() {
        _userMutated = false;
        _syncStatus = 'Synced';
        _syncError = '';
      });
    } on _RemoteStateConflictException catch (error) {
      if (!mounted || _saveRun != saveRun) return;
      setState(() {
        _syncStatus = 'Remote changed';
        _syncError = error.toString();
      });
    } catch (error) {
      if (!mounted || _saveRun != saveRun) return;
      setState(() {
        _syncStatus = 'Sync failed';
        _syncError = '$error';
      });
    }
  }

  Future<_RemoteTodoState> _loadRemoteTodoState(String userId) async {
    final supabase = _supabase;
    if (supabase == null) {
      return const _RemoteTodoState(
        todos: [],
        groups: [],
        initialized: false,
        updatedAt: null,
      );
    }

    final results = await Future.wait([
      supabase
          .from('todo_sync_state')
          .select('initialized,updated_at')
          .eq('user_id', userId)
          .maybeSingle(),
      supabase
          .from('groups')
          .select('id,title,created_at,position')
          .eq('user_id', userId)
          .order('position')
          .order('created_at'),
      supabase
          .from('todos')
          .select(
            'id,text,completed,created_at,group_id,due_date,priority,position',
          )
          .eq('user_id', userId)
          .order('position')
          .order('created_at'),
    ]);

    final syncState = results[0] as Map<String, dynamic>?;
    final groups = (results[1] as List<dynamic>)
        .map(_groupFromRemote)
        .nonNulls
        .toList();
    final groupIds = groups.map((group) => group.id).toSet();
    final todos = (results[2] as List<dynamic>)
        .map(_todoFromRemote)
        .nonNulls
        .map(
          (todo) => groupIds.contains(todo.groupId)
              ? todo
              : todo.copyWith(clearGroup: true),
        )
        .toList();

    return _RemoteTodoState(
      initialized: syncState?['initialized'] == true,
      updatedAt: syncState?['updated_at'] as String?,
      groups: groups,
      todos: todos,
    );
  }

  Future<String?> _saveRemoteTodoState(
    String userId,
    String? expectedUpdatedAt,
  ) async {
    final supabase = _supabase;
    if (supabase == null) return null;

    final groupIds = _groups.map((group) => group.id).toSet();
    final response = await supabase.rpc(
      'save_todo_state',
      params: {
        'p_expected_updated_at': expectedUpdatedAt,
        'p_groups': [
          for (var index = 0; index < _groups.length; index += 1)
            _groupToRemote(_groups[index], userId, index),
        ],
        'p_todos': [
          for (var index = 0; index < _todos.length; index += 1)
            _todoToRemote(
              groupIds.contains(_todos[index].groupId)
                  ? _todos[index]
                  : _todos[index].copyWith(clearGroup: true),
              userId,
              index,
            ),
        ],
      },
    );

    final rows = response is List ? response : const [];
    final savedState = rows.isNotEmpty && rows.first is Map
        ? rows.first as Map
        : const {};
    if (savedState['status'] == 'conflict') {
      throw const _RemoteStateConflictException();
    }
    final updatedAt = savedState['updated_at'];
    return updatedAt == null ? null : '$updatedAt';
  }

  TodoGroup? _groupFromRemote(Object? value) {
    if (value is! Map) return null;
    final title = '${value['title'] ?? ''}'.trim();
    if (title.isEmpty) return null;
    return TodoGroup(
      id: '${value['id'] ?? DateTime.now().microsecondsSinceEpoch}',
      title: title,
      createdAt:
          DateTime.tryParse('${value['created_at'] ?? ''}') ?? DateTime.now(),
    );
  }

  TodoItem? _todoFromRemote(Object? value) {
    if (value is! Map) return null;
    final text = '${value['text'] ?? ''}'.trim();
    if (text.isEmpty) return null;
    return TodoItem(
      id: '${value['id'] ?? DateTime.now().microsecondsSinceEpoch}',
      text: text,
      priority: TodoPriority.values.firstWhere(
        (priority) => priority.name == value['priority'],
        orElse: () => TodoPriority.medium,
      ),
      createdAt:
          DateTime.tryParse('${value['created_at'] ?? ''}') ?? DateTime.now(),
      sortOrder: int.tryParse('${value['position'] ?? ''}') ?? 0,
      completed: value['completed'] == true,
      dueDate: DateTime.tryParse('${value['due_date'] ?? ''}'),
      groupId: value['group_id'] == null || value['group_id'] == ''
          ? null
          : '${value['group_id']}',
    );
  }

  Map<String, Object?> _groupToRemote(
    TodoGroup group,
    String userId,
    int position,
  ) {
    return {
      'id': group.id,
      'user_id': userId,
      'title': group.title,
      'created_at': group.createdAt.toIso8601String(),
      'position': position,
    };
  }

  Map<String, Object?> _todoToRemote(
    TodoItem todo,
    String userId,
    int position,
  ) {
    return {
      'id': todo.id,
      'user_id': userId,
      'group_id': todo.groupId,
      'text': todo.text,
      'completed': todo.completed,
      'created_at': todo.createdAt.toIso8601String(),
      'due_date': todo.dueDate?.toIso8601String(),
      'priority': todo.priority.name,
      'position': position,
    };
  }

  void _addTodo() {
    final text = _taskController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _todos.insert(
        0,
        TodoItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: text,
          priority: _selectedPriority,
          createdAt: DateTime.now(),
          sortOrder: _nextSortOrder(_selectedGroupId),
          dueDate: _newTodoDueDate,
          groupId: _selectedGroupId,
        ),
      );
      _taskController.clear();
      _selectedPriority = TodoPriority.medium;
      _newTodoDueDate = null;
    });
    _persistAndReconcile();
  }

  void _updateTodo(String id, TodoItem Function(TodoItem todo) update) {
    setState(() {
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index == -1) return;
      _todos[index] = update(_todos[index]);
    });
    _persistAndReconcile();
  }

  void _deleteTodo(String id) {
    setState(() {
      _captureUndo('Task deleted');
      _todos.removeWhere((todo) => todo.id == id);
    });
    _notificationScheduler.cancel(id);
    _persistAndReconcile();
  }

  void _clearCompleted() {
    if (_completedCount == 0) return;
    setState(() {
      _captureUndo('Completed tasks cleared');
      _todos.removeWhere((todo) => todo.completed);
    });
    _persistAndReconcile();
  }

  void _restoreUndo() {
    final undo = _undo;
    if (undo == null) return;
    setState(() {
      _todos
        ..clear()
        ..addAll(undo.todos);
      _groups
        ..clear()
        ..addAll(undo.groups);
      _undo = null;
    });
    _persistAndReconcile();
  }

  void _dismissUndo() {
    setState(() => _undo = null);
  }

  void _createGroup() {
    final title = _groupController.text.trim();
    if (title.isEmpty) return;
    final group = TodoGroup(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      createdAt: DateTime.now(),
    );
    setState(() {
      _groups.add(group);
      _selectedGroupId = group.id;
      _groupController.clear();
    });
    _persistAndSync();
  }

  void _renameGroup(String groupId, String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      final index = _groups.indexWhere((group) => group.id == groupId);
      if (index == -1) return;
      _groups[index] = _groups[index].copyWith(title: trimmed);
    });
    _persistAndSync();
  }

  void _deleteGroup(String groupId) {
    setState(() {
      _captureUndo('Group deleted');
      _groups.removeWhere((group) => group.id == groupId);
      for (var index = 0; index < _todos.length; index += 1) {
        if (_todos[index].groupId == groupId) {
          _todos[index] = _todos[index].copyWith(clearGroup: true);
        }
      }
      _collapsedGroups.remove(groupId);
      if (_selectedGroupId == groupId) _selectedGroupId = null;
    });
    _persistAndReconcile();
  }

  void _toggleGroupCollapsed(String groupId) {
    setState(() {
      if (!_collapsedGroups.add(groupId)) {
        _collapsedGroups.remove(groupId);
      }
    });
    _saveLocalState();
  }

  void _startDraggingTodo(TodoItem todo) {
    setState(() {
      _draggingTodoId = todo.id;
      _groupSortModes[_groupKey(todo.groupId)] = TodoSortMode.manual;
    });
    _persistAndSync();
  }

  void _finishDraggingTodo() {
    if (_draggingTodoId == null) return;
    setState(() => _draggingTodoId = null);
  }

  void _setGroupSortMode(String? groupId, TodoSortMode mode) {
    setState(() => _groupSortModes[_groupKey(groupId)] = mode);
    _saveLocalState();
  }

  void _moveTodo(
    TodoItem draggedTodo,
    String? targetGroupId,
    String? beforeId,
  ) {
    setState(() {
      _groupSortModes[_groupKey(draggedTodo.groupId)] = TodoSortMode.manual;
      _groupSortModes[_groupKey(targetGroupId)] = TodoSortMode.manual;

      final targetTodos =
          _todos
              .where(
                (todo) =>
                    todo.id != draggedTodo.id && todo.groupId == targetGroupId,
              )
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      var insertIndex = beforeId == null
          ? targetTodos.length
          : targetTodos.indexWhere((todo) => todo.id == beforeId);
      if (insertIndex == -1) insertIndex = targetTodos.length;

      final movedTodo = draggedTodo.copyWith(
        groupId: targetGroupId,
        clearGroup: targetGroupId == null,
      );
      targetTodos.insert(insertIndex, movedTodo);

      for (var index = 0; index < targetTodos.length; index += 1) {
        final orderedTodo = targetTodos[index].copyWith(sortOrder: index);
        final sourceIndex = _todos.indexWhere(
          (todo) => todo.id == orderedTodo.id,
        );
        if (sourceIndex == -1) {
          final draggedIndex = _todos.indexWhere(
            (todo) => todo.id == draggedTodo.id,
          );
          if (draggedIndex != -1) _todos[draggedIndex] = orderedTodo;
        } else {
          _todos[sourceIndex] = orderedTodo;
        }
      }
    });
    _persistAndReconcile();
  }

  int _nextSortOrder(String? groupId) {
    final matchingOrders = _todos
        .where((todo) => todo.groupId == groupId)
        .map((todo) => todo.sortOrder);
    if (matchingOrders.isEmpty) return 0;
    return matchingOrders.reduce((a, b) => a > b ? a : b) + 1;
  }

  String _groupKey(String? groupId) => groupId ?? _ungroupedKey;

  String _currentWebRedirectUrl() {
    final origin = Uri.base.origin;
    return origin.endsWith('/') ? origin : '$origin/';
  }

  Future<DateTime?> _chooseDueDate(DateTime? currentValue) async {
    final now = DateTime.now();
    final initialDate = currentValue ?? now;
    final minimumDate = DateTime(now.year - 1);
    final maximumDate = DateTime(now.year + 5);
    if (kIsWeb && isNativeWebDueDatePickerAvailable) {
      return chooseNativeWebDueDate(
        initialDate: initialDate,
        minimumDate: minimumDate,
        maximumDate: maximumDate,
      );
    }

    final platform = Theme.of(context).platform;
    final useCupertinoPicker =
        !kIsWeb &&
        (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS);
    if (useCupertinoPicker) {
      return _chooseCupertinoDueDate(
        initialDate: initialDate,
        minimumDate: minimumDate,
        maximumDate: maximumDate,
      );
    }

    if (kIsWeb) {
      return _chooseWebFallbackDueDate(
        initialDate: initialDate,
        minimumDate: minimumDate,
        maximumDate: maximumDate,
      );
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minimumDate,
      lastDate: maximumDate,
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null || !mounted) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<DateTime?> _chooseWebFallbackDueDate({
    required DateTime initialDate,
    required DateTime minimumDate,
    required DateTime maximumDate,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    var selectedDate = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );
    // Use a fixed base date so the time picker only scrolls through time.
    var selectedTime = DateTime(2000, 1, 1, initialDate.hour, initialDate.minute);

    return showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Due date'),
              contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CalendarDatePicker(
                      initialDate: selectedDate,
                      firstDate: minimumDate,
                      lastDate: maximumDate,
                      onDateChanged: (date) {
                        setDialogState(() => selectedDate = date);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TIME',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 160,
                            child: CupertinoTheme(
                              data: CupertinoThemeData(
                                brightness: Theme.of(ctx).brightness,
                                primaryColor: colorScheme.primary,
                                textTheme: CupertinoTextThemeData(
                                  dateTimePickerTextStyle: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              child: CupertinoDatePicker(
                                mode: CupertinoDatePickerMode.time,
                                initialDateTime: selectedTime,
                                use24hFormat:
                                    MediaQuery.alwaysUse24HourFormatOf(ctx),
                                onDateTimeChanged: (newTime) {
                                  selectedTime = newTime;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      ctx,
                      DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      ),
                    );
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _chooseCupertinoDueDate({
    required DateTime initialDate,
    required DateTime minimumDate,
    required DateTime maximumDate,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    var selectedDate = initialDate.isBefore(minimumDate)
        ? minimumDate
        : initialDate.isAfter(maximumDate)
        ? maximumDate
        : initialDate;

    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) {
        return SafeArea(
          top: false,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: SizedBox(
              height: 340,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const Spacer(),
                        Text(
                          'Due date',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: () => Navigator.pop(context, selectedDate),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  Expanded(
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        brightness: Theme.of(context).brightness,
                        primaryColor: colorScheme.primary,
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.dateAndTime,
                        initialDateTime: selectedDate,
                        minimumDate: minimumDate,
                        maximumDate: maximumDate,
                        use24hFormat: MediaQuery.alwaysUse24HourFormatOf(
                          context,
                        ),
                        onDateTimeChanged: (date) => selectedDate = date,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickNewTodoDueDate() async {
    final dueDate = await _chooseDueDate(_newTodoDueDate);
    if (dueDate == null || !mounted) return;
    setState(() => _newTodoDueDate = dueDate);
  }

  Future<void> _pickDueDate(TodoItem todo) async {
    final dueDate = await _chooseDueDate(todo.dueDate);
    if (dueDate == null || !mounted) return;
    _updateTodo(todo.id, (current) => current.copyWith(dueDate: dueDate));
  }

  Future<void> _reconcileNotifications() async {
    final requests = _notificationsEnabled
        ? _todos
              .where((todo) {
                final dueDate = todo.dueDate;
                return !todo.completed &&
                    dueDate != null &&
                    dueDate.isAfter(DateTime.now());
              })
              .map(
                (todo) => TodoNotificationRequest(
                  todoId: todo.id,
                  title: 'Task due',
                  body: todo.text,
                  dueDate: todo.dueDate!,
                ),
              )
        : const Iterable<TodoNotificationRequest>.empty();

    await _notificationScheduler.reconcile(requests);
  }

  int get _activeCount => _todos.where((todo) => !todo.completed).length;

  int get _completedCount => _todos.length - _activeCount;

  String get _notificationStatusText {
    if (_notificationPermission == NotificationPermissionState.denied) {
      return 'Permission denied';
    }
    return switch (_notificationCapability) {
      NotificationCapability.nativeScheduled => 'Scheduled by macOS',
      NotificationCapability.webWhileOpen => 'Works while this tab is open',
      NotificationCapability.unsupported => 'Unsupported here',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.10),
                colorScheme.surfaceContainerHighest,
              ),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 18,
              vertical: compact ? 20 : 30,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _AppHeader(),
                    const SizedBox(height: 16),
                    _LiveTodoCard(
                      notificationsEnabled: _notificationsEnabled,
                      taskController: _taskController,
                      groupController: _groupController,
                      selectedPriority: _selectedPriority,
                      selectedGroupId: _selectedGroupId,
                      newTodoDueDate: _newTodoDueDate,
                      todos: _todos,
                      groups: _groups,
                      collapsedGroups: _collapsedGroups,
                      groupSortModes: _groupSortModes,
                      draggingTodoId: _draggingTodoId,
                      undo: _undo,
                      total: _todos.length,
                      active: _activeCount,
                      completed: _completedCount,
                      isSyncConfigured: _supabase != null,
                      syncStatus: _syncStatus,
                      syncError: _syncError,
                      userEmail: _session?.user.email,
                      authBusy: _authBusy,
                      onSignIn: _signInWithGoogle,
                      onSignOut: _signOut,
                      onNotificationsChanged: (value) {
                        _setNotificationsEnabled(value);
                      },
                      notificationStatus: _notificationStatusText,
                      onPriorityChanged: (priority) {
                        setState(() => _selectedPriority = priority);
                      },
                      onGroupChanged: (groupId) {
                        setState(() => _selectedGroupId = groupId);
                      },
                      onCreateGroup: _createGroup,
                      onRenameGroup: _renameGroup,
                      onDeleteGroup: _deleteGroup,
                      onToggleGroupCollapsed: _toggleGroupCollapsed,
                      onMoveTodo: _moveTodo,
                      onStartDraggingTodo: _startDraggingTodo,
                      onFinishDraggingTodo: _finishDraggingTodo,
                      onGroupSortModeChanged: _setGroupSortMode,
                      onRestoreUndo: _restoreUndo,
                      onDismissUndo: _dismissUndo,
                      onPickNewTodoDueDate: _pickNewTodoDueDate,
                      onClearNewTodoDueDate: () {
                        setState(() => _newTodoDueDate = null);
                      },
                      onSubmitted: _addTodo,
                      onToggleComplete: (todo) {
                        _updateTodo(
                          todo.id,
                          (current) =>
                              current.copyWith(completed: !current.completed),
                        );
                      },
                      onTextChanged: (todo, text) {
                        _updateTodo(
                          todo.id,
                          (current) => current.copyWith(text: text),
                        );
                      },
                      onPriorityCycle: (todo) {
                        _updateTodo(
                          todo.id,
                          (current) =>
                              current.copyWith(priority: current.priority.next),
                        );
                      },
                      onPickDueDate: _pickDueDate,
                      onClearDueDate: (todo) {
                        _updateTodo(
                          todo.id,
                          (current) => current.copyWith(clearDueDate: true),
                        );
                      },
                      onDelete: _deleteTodo,
                      onClearCompleted: _clearCompleted,
                    ),
                    const _AppVersion(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppVersion extends StatelessWidget {
  const _AppVersion();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Text(
        'v0.2.0-flutter',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Neo To-Do',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _formatToday(),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveTodoCard extends StatelessWidget {
  const _LiveTodoCard({
    required this.notificationsEnabled,
    required this.taskController,
    required this.groupController,
    required this.selectedPriority,
    required this.selectedGroupId,
    required this.newTodoDueDate,
    required this.todos,
    required this.groups,
    required this.collapsedGroups,
    required this.groupSortModes,
    required this.draggingTodoId,
    required this.undo,
    required this.total,
    required this.active,
    required this.completed,
    required this.isSyncConfigured,
    required this.syncStatus,
    required this.syncError,
    required this.userEmail,
    required this.authBusy,
    required this.onSignIn,
    required this.onSignOut,
    required this.onNotificationsChanged,
    required this.notificationStatus,
    required this.onPriorityChanged,
    required this.onGroupChanged,
    required this.onCreateGroup,
    required this.onRenameGroup,
    required this.onDeleteGroup,
    required this.onToggleGroupCollapsed,
    required this.onMoveTodo,
    required this.onStartDraggingTodo,
    required this.onFinishDraggingTodo,
    required this.onGroupSortModeChanged,
    required this.onRestoreUndo,
    required this.onDismissUndo,
    required this.onPickNewTodoDueDate,
    required this.onClearNewTodoDueDate,
    required this.onSubmitted,
    required this.onToggleComplete,
    required this.onTextChanged,
    required this.onPriorityCycle,
    required this.onPickDueDate,
    required this.onClearDueDate,
    required this.onDelete,
    required this.onClearCompleted,
  });

  final bool notificationsEnabled;
  final TextEditingController taskController;
  final TextEditingController groupController;
  final TodoPriority selectedPriority;
  final String? selectedGroupId;
  final DateTime? newTodoDueDate;
  final List<TodoItem> todos;
  final List<TodoGroup> groups;
  final Set<String> collapsedGroups;
  final Map<String, TodoSortMode> groupSortModes;
  final String? draggingTodoId;
  final _UndoSnapshot? undo;
  final int total;
  final int active;
  final int completed;
  final bool isSyncConfigured;
  final String syncStatus;
  final String syncError;
  final String? userEmail;
  final bool authBusy;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final ValueChanged<bool> onNotificationsChanged;
  final String notificationStatus;
  final ValueChanged<TodoPriority> onPriorityChanged;
  final ValueChanged<String?> onGroupChanged;
  final VoidCallback onCreateGroup;
  final void Function(String groupId, String title) onRenameGroup;
  final ValueChanged<String> onDeleteGroup;
  final ValueChanged<String> onToggleGroupCollapsed;
  final void Function(TodoItem todo, String? groupId, String? beforeId)
  onMoveTodo;
  final ValueChanged<TodoItem> onStartDraggingTodo;
  final VoidCallback onFinishDraggingTodo;
  final void Function(String? groupId, TodoSortMode mode)
  onGroupSortModeChanged;
  final VoidCallback onRestoreUndo;
  final VoidCallback onDismissUndo;
  final VoidCallback onPickNewTodoDueDate;
  final VoidCallback onClearNewTodoDueDate;
  final VoidCallback onSubmitted;
  final ValueChanged<TodoItem> onToggleComplete;
  final void Function(TodoItem todo, String text) onTextChanged;
  final ValueChanged<TodoItem> onPriorityCycle;
  final ValueChanged<TodoItem> onPickDueDate;
  final ValueChanged<TodoItem> onClearDueDate;
  final ValueChanged<String> onDelete;
  final VoidCallback onClearCompleted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < _phoneLayoutWidth;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.07),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 96,
            spreadRadius: -8,
            offset: const Offset(0, 36),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SyncBar(
              isConfigured: isSyncConfigured,
              status: syncStatus,
              error: syncError,
              userEmail: userEmail,
              busy: authBusy,
              onSignIn: onSignIn,
              onSignOut: onSignOut,
            ),
            const SizedBox(height: 12),
            _NotificationBar(
              enabled: notificationsEnabled,
              statusText: notificationStatus,
              onChanged: onNotificationsChanged,
            ),
            const SizedBox(height: 16),
            _TaskComposer(
              controller: taskController,
              groupController: groupController,
              selectedPriority: selectedPriority,
              selectedGroupId: selectedGroupId,
              dueDate: newTodoDueDate,
              groups: groups,
              onPriorityChanged: onPriorityChanged,
              onGroupChanged: onGroupChanged,
              onCreateGroup: onCreateGroup,
              onPickDueDate: onPickNewTodoDueDate,
              onClearDueDate: onClearNewTodoDueDate,
              onSubmitted: onSubmitted,
            ),
            const SizedBox(height: 14),
            if (undo != null) ...[
              _UndoBar(
                message: undo!.message,
                onUndo: onRestoreUndo,
                onDismiss: onDismissUndo,
              ),
              const SizedBox(height: 12),
            ],
            _GroupedTodoList(
              todos: todos,
              groups: groups,
              collapsedGroups: collapsedGroups,
              groupSortModes: groupSortModes,
              draggingTodoId: draggingTodoId,
              onToggleComplete: onToggleComplete,
              onTextChanged: onTextChanged,
              onPriorityCycle: onPriorityCycle,
              onPickDueDate: onPickDueDate,
              onClearDueDate: onClearDueDate,
              onDelete: onDelete,
              onRenameGroup: onRenameGroup,
              onDeleteGroup: onDeleteGroup,
              onToggleGroupCollapsed: onToggleGroupCollapsed,
              onMoveTodo: onMoveTodo,
              onStartDraggingTodo: onStartDraggingTodo,
              onFinishDraggingTodo: onFinishDraggingTodo,
              onGroupSortModeChanged: onGroupSortModeChanged,
            ),
            const SizedBox(height: 8),
            _FooterStats(
              total: total,
              active: active,
              completed: completed,
              onClearCompleted: onClearCompleted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncBar extends StatelessWidget {
  const _SyncBar({
    required this.isConfigured,
    required this.status,
    required this.error,
    required this.userEmail,
    required this.busy,
    required this.onSignIn,
    required this.onSignOut,
  });

  final bool isConfigured;
  final String status;
  final String error;
  final String? userEmail;
  final bool busy;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final signedIn = userEmail != null;
    final statusText = !isConfigured
        ? 'Local mode'
        : signedIn
        ? 'Signed in as $userEmail'
        : status;
    final statusColor = signedIn ? Colors.green : colorScheme.onSurfaceVariant;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final authButton = FilledButton(
      onPressed: !isConfigured || busy
          ? null
          : signedIn
          ? onSignOut
          : onSignIn,
      style: FilledButton.styleFrom(
        backgroundColor: signedIn ? Colors.transparent : colorScheme.primary,
        foregroundColor: signedIn
            ? colorScheme.onSurfaceVariant
            : colorScheme.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size(compact ? double.infinity : 170, 34),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: signedIn ? colorScheme.outlineVariant : Colors.transparent,
          ),
        ),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
      child: Text(
        !isConfigured
            ? 'Local'
            : busy
            ? 'Please wait'
            : signedIn
            ? 'Sign out'
            : 'Continue with Google',
      ),
    );
    final statusRow = Row(
      children: [
        _StatusDot(color: statusColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusText,
                overflow: compact
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (error.isNotEmpty)
                Text(
                  error,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        if (signedIn && !compact)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              status,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [statusRow, const SizedBox(height: 10), authButton],
              )
            : Row(
                children: [
                  Expanded(child: statusRow),
                  authButton,
                ],
              ),
      ),
    );
  }
}

class _NotificationBar extends StatelessWidget {
  const _NotificationBar({
    required this.enabled,
    required this.statusText,
    required this.onChanged,
  });

  final bool enabled;
  final String statusText;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final statusRow = Row(
      children: [
        _StatusDot(
          color: enabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                enabled ? 'Due notifications on' : 'Due notifications off',
                overflow: compact
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                statusText,
                overflow: compact
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final actionButton = OutlinedButton(
      onPressed: statusText == 'Unsupported here'
          ? null
          : () => onChanged(!enabled),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        minimumSize: Size(compact ? double.infinity : 90, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: compact ? 0.22 : 0.45),
        ),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
      child: Text(enabled ? 'Disable' : 'Enable'),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [statusRow, const SizedBox(height: 8), actionButton],
              )
            : Row(
                children: [
                  Expanded(child: statusRow),
                  actionButton,
                ],
              ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.16), spreadRadius: 3),
        ],
      ),
    );
  }
}

class _FooterStats extends StatelessWidget {
  const _FooterStats({
    required this.total,
    required this.active,
    required this.completed,
    required this.onClearCompleted,
  });

  final int total;
  final int active;
  final int completed;
  final VoidCallback onClearCompleted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _StatChip(
                  label: 'Total',
                  value: total,
                  color: colorScheme.onSurfaceVariant,
                ),
                _StatChip(
                  label: 'Active',
                  value: active,
                  color: colorScheme.primary,
                ),
                _StatChip(
                  label: 'Done',
                  value: completed,
                  color: const Color(0xFF16A34A),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: completed == 0 ? null : onClearCompleted,
              icon: const Icon(Icons.delete_sweep_outlined, size: 16),
              label: const Text('Clear done'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text.rich(
        TextSpan(
          text: '$value ',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
          children: [
            TextSpan(
              text: label,
              style: TextStyle(
                color: color.withValues(alpha: 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskComposer extends StatelessWidget {
  const _TaskComposer({
    required this.controller,
    required this.groupController,
    required this.selectedPriority,
    required this.selectedGroupId,
    required this.dueDate,
    required this.groups,
    required this.onPriorityChanged,
    required this.onGroupChanged,
    required this.onCreateGroup,
    required this.onPickDueDate,
    required this.onClearDueDate,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final TextEditingController groupController;
  final TodoPriority selectedPriority;
  final String? selectedGroupId;
  final DateTime? dueDate;
  final List<TodoGroup> groups;
  final ValueChanged<TodoPriority> onPriorityChanged;
  final ValueChanged<String?> onGroupChanged;
  final VoidCallback onCreateGroup;
  final VoidCallback onPickDueDate;
  final VoidCallback onClearDueDate;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final phone = constraints.maxWidth < _phoneLayoutWidth;
        final taskField = TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'What needs to be done?'),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmitted(),
        );
        final priorityField = DropdownButtonFormField<TodoPriority>(
          initialValue: selectedPriority,
          decoration: const InputDecoration(),
          items: TodoPriority.values
              .map(
                (priority) => DropdownMenuItem(
                  value: priority,
                  child: Text(priority.label),
                ),
              )
              .toList(),
          onChanged: (priority) {
            if (priority != null) onPriorityChanged(priority);
          },
        );
        final groupField = DropdownButtonFormField<String?>(
          initialValue: selectedGroupId,
          decoration: const InputDecoration(),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('No group'),
            ),
            ...groups.map(
              (group) => DropdownMenuItem<String?>(
                value: group.id,
                child: Text(group.title),
              ),
            ),
          ],
          onChanged: onGroupChanged,
        );
        const newGroupControlHeight = 48.0;
        final newGroupField = TextField(
          controller: groupController,
          decoration: const InputDecoration(
            constraints: BoxConstraints.tightFor(height: newGroupControlHeight),
            hintText: 'New group',
            prefixIcon: Icon(Icons.create_new_folder_outlined),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onCreateGroup(),
        );
        final newGroupButton = SizedBox(
          width: 118,
          height: newGroupControlHeight,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onCreateGroup,
            icon: const Icon(Icons.add),
            label: const Text('Create'),
          ),
        );
        final addButton = SizedBox(
          width: 104,
          height: compact ? 46 : 44,
          child: FilledButton.icon(
            onPressed: onSubmitted,
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        );
        final dueButton = _ComposerDueButton(
          dueDate: dueDate,
          onPickDueDate: onPickDueDate,
          onClearDueDate: onClearDueDate,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ComposerField(label: 'Task', child: taskField),
              const SizedBox(height: 10),
              _ComposerField(label: 'Priority', child: priorityField),
              const SizedBox(height: 10),
              if (groups.isNotEmpty) ...[
                _ComposerField(label: 'Group', child: groupField),
                const SizedBox(height: 10),
              ],
              _ComposerField(label: 'Due date', child: dueButton),
              const SizedBox(height: 10),
              addButton,
              const SizedBox(height: 10),
              if (phone) ...[
                newGroupField,
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: newGroupButton),
              ] else
                SizedBox(
                  height: newGroupControlHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: newGroupField),
                      const SizedBox(width: 10),
                      newGroupButton,
                    ],
                  ),
                ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ComposerField(label: 'Task', child: taskField),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 118,
                  child: _ComposerField(
                    label: 'Priority',
                    child: priorityField,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 192,
                  child: _ComposerField(label: 'Due date', child: dueButton),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 17),
                  child: addButton,
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: newGroupControlHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (groups.isNotEmpty) ...[
                    SizedBox(width: 220, child: groupField),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: newGroupField),
                  const SizedBox(width: 12),
                  newGroupButton,
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ComposerField extends StatelessWidget {
  const _ComposerField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _UndoBar extends StatelessWidget {
  const _UndoBar({
    required this.message,
    required this.onUndo,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onUndo;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.10),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(onPressed: onUndo, child: const Text('Undo')),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupedTodoList extends StatelessWidget {
  const _GroupedTodoList({
    required this.todos,
    required this.groups,
    required this.collapsedGroups,
    required this.groupSortModes,
    required this.draggingTodoId,
    required this.onToggleComplete,
    required this.onTextChanged,
    required this.onPriorityCycle,
    required this.onPickDueDate,
    required this.onClearDueDate,
    required this.onDelete,
    required this.onRenameGroup,
    required this.onDeleteGroup,
    required this.onToggleGroupCollapsed,
    required this.onMoveTodo,
    required this.onStartDraggingTodo,
    required this.onFinishDraggingTodo,
    required this.onGroupSortModeChanged,
  });

  final List<TodoItem> todos;
  final List<TodoGroup> groups;
  final Set<String> collapsedGroups;
  final Map<String, TodoSortMode> groupSortModes;
  final String? draggingTodoId;
  final ValueChanged<TodoItem> onToggleComplete;
  final void Function(TodoItem todo, String text) onTextChanged;
  final ValueChanged<TodoItem> onPriorityCycle;
  final ValueChanged<TodoItem> onPickDueDate;
  final ValueChanged<TodoItem> onClearDueDate;
  final ValueChanged<String> onDelete;
  final void Function(String groupId, String title) onRenameGroup;
  final ValueChanged<String> onDeleteGroup;
  final ValueChanged<String> onToggleGroupCollapsed;
  final void Function(TodoItem todo, String? groupId, String? beforeId)
  onMoveTodo;
  final ValueChanged<TodoItem> onStartDraggingTodo;
  final VoidCallback onFinishDraggingTodo;
  final void Function(String? groupId, TodoSortMode mode)
  onGroupSortModeChanged;

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty && groups.isEmpty) return const _EmptyState();

    final groupIds = groups.map((group) => group.id).toSet();
    final sections = <Widget>[
      for (final group in groups)
        _GroupSection(
          group: group,
          todos: _sortedTodos(
            todos.where((todo) => todo.groupId == group.id).toList(),
            _sortModeFor(group.id),
          ),
          sortMode: _sortModeFor(group.id),
          sortingEnabled: draggingTodoId == null,
          collapsed: collapsedGroups.contains(group.id),
          onToggleCollapsed: () => onToggleGroupCollapsed(group.id),
          onRename: (title) => onRenameGroup(group.id, title),
          onDeleteGroup: () => onDeleteGroup(group.id),
          onMoveTodoHere: (todo) => onMoveTodo(todo, group.id, null),
          onMoveTodo: (todo, beforeId) => onMoveTodo(todo, group.id, beforeId),
          onSortModeChanged: (mode) => onGroupSortModeChanged(group.id, mode),
          onStartDraggingTodo: onStartDraggingTodo,
          onFinishDraggingTodo: onFinishDraggingTodo,
          onToggleComplete: onToggleComplete,
          onTextChanged: onTextChanged,
          onPriorityCycle: onPriorityCycle,
          onPickDueDate: onPickDueDate,
          onClearDueDate: onClearDueDate,
          onDelete: onDelete,
        ),
      _GroupSection(
        group: null,
        todos: _sortedTodos(
          todos
              .where(
                (todo) =>
                    todo.groupId == null || !groupIds.contains(todo.groupId),
              )
              .toList(),
          _sortModeFor(null),
        ),
        sortMode: _sortModeFor(null),
        sortingEnabled: draggingTodoId == null,
        collapsed: collapsedGroups.contains('ungrouped'),
        onToggleCollapsed: () => onToggleGroupCollapsed('ungrouped'),
        onRename: null,
        onDeleteGroup: null,
        onMoveTodoHere: (todo) => onMoveTodo(todo, null, null),
        onMoveTodo: (todo, beforeId) => onMoveTodo(todo, null, beforeId),
        onSortModeChanged: (mode) => onGroupSortModeChanged(null, mode),
        onStartDraggingTodo: onStartDraggingTodo,
        onFinishDraggingTodo: onFinishDraggingTodo,
        onToggleComplete: onToggleComplete,
        onTextChanged: onTextChanged,
        onPriorityCycle: onPriorityCycle,
        onPickDueDate: onPickDueDate,
        onClearDueDate: onClearDueDate,
        onDelete: onDelete,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections) ...[
          section,
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  TodoSortMode _sortModeFor(String? groupId) {
    return groupSortModes[groupId ?? _TodoHomePageState._ungroupedKey] ??
        TodoSortMode.dueAsc;
  }

  List<TodoItem> _sortedTodos(List<TodoItem> input, TodoSortMode mode) {
    final sorted = List<TodoItem>.of(input);
    sorted.sort(
      (a, b) => switch (mode) {
        TodoSortMode.manual => a.sortOrder.compareTo(b.sortOrder),
        TodoSortMode.dueAsc => _compareDueDates(a, b),
        TodoSortMode.dueDesc => _compareDueDates(b, a),
      },
    );
    return sorted;
  }

  int _compareDueDates(TodoItem a, TodoItem b) {
    final aDue = a.dueDate;
    final bDue = b.dueDate;
    if (aDue == null && bDue == null) {
      return b.createdAt.compareTo(a.createdAt);
    }
    if (aDue == null) return 1;
    if (bDue == null) return -1;
    return aDue.compareTo(bDue);
  }
}

class _GroupSection extends StatefulWidget {
  const _GroupSection({
    required this.group,
    required this.todos,
    required this.sortMode,
    required this.sortingEnabled,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.onRename,
    required this.onDeleteGroup,
    required this.onMoveTodoHere,
    required this.onMoveTodo,
    required this.onSortModeChanged,
    required this.onStartDraggingTodo,
    required this.onFinishDraggingTodo,
    required this.onToggleComplete,
    required this.onTextChanged,
    required this.onPriorityCycle,
    required this.onPickDueDate,
    required this.onClearDueDate,
    required this.onDelete,
  });

  final TodoGroup? group;
  final List<TodoItem> todos;
  final TodoSortMode sortMode;
  final bool sortingEnabled;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<String>? onRename;
  final VoidCallback? onDeleteGroup;
  final ValueChanged<TodoItem> onMoveTodoHere;
  final void Function(TodoItem todo, String? beforeId) onMoveTodo;
  final ValueChanged<TodoSortMode> onSortModeChanged;
  final ValueChanged<TodoItem> onStartDraggingTodo;
  final VoidCallback onFinishDraggingTodo;
  final ValueChanged<TodoItem> onToggleComplete;
  final void Function(TodoItem todo, String text) onTextChanged;
  final ValueChanged<TodoItem> onPriorityCycle;
  final ValueChanged<TodoItem> onPickDueDate;
  final ValueChanged<TodoItem> onClearDueDate;
  final ValueChanged<String> onDelete;

  @override
  State<_GroupSection> createState() => _GroupSectionState();
}

class _GroupSectionState extends State<_GroupSection> {
  late final TextEditingController _titleController;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.group?.title ?? '');
  }

  @override
  void didUpdateWidget(covariant _GroupSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.group?.title != widget.group?.title) {
      _titleController.text = widget.group?.title ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _saveTitle() {
    final onRename = widget.onRename;
    if (onRename == null) return;
    onRename(_titleController.text);
    setState(() => _editing = false);
  }

  Widget _buildTitleRow(
    BuildContext context, {
    required String title,
    required bool isUngrouped,
    required bool includeControls,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          tooltip: widget.collapsed ? 'Expand group' : 'Collapse group',
          onPressed: widget.onToggleCollapsed,
          icon: Icon(
            widget.collapsed ? Icons.chevron_right : Icons.expand_more,
          ),
        ),
        Icon(
          isUngrouped ? Icons.inbox_outlined : Icons.folder_outlined,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _editing
              ? TextField(
                  controller: _titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Group name',
                  ),
                  onSubmitted: (_) => _saveTitle(),
                )
              : Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
        ),
        if (includeControls) _buildGroupControls(compact: false),
      ],
    );
  }

  Widget _buildGroupControls({required bool compact}) {
    final isUngrouped = widget.group == null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GroupSortMenu(
          value: widget.sortMode,
          enabled: widget.sortingEnabled,
          compact: compact,
          onChanged: widget.onSortModeChanged,
        ),
        const SizedBox(width: 8),
        _CountBadge(count: widget.todos.length),
        if (!isUngrouped) ...[
          IconButton(
            tooltip: _editing ? 'Save group' : 'Rename group',
            onPressed: _editing
                ? _saveTitle
                : () => setState(() {
                    _editing = true;
                    _titleController.text = widget.group?.title ?? '';
                  }),
            icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete group',
            onPressed: widget.onDeleteGroup,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = widget.group?.title ?? 'Ungrouped';
    final isUngrouped = widget.group == null;
    final targetGroupId = widget.group?.id;
    final compact = MediaQuery.sizeOf(context).width < _phoneLayoutWidth;

    return DragTarget<TodoItem>(
      onWillAcceptWithDetails: (details) =>
          details.data.groupId != targetGroupId,
      onAcceptWithDetails: (details) => widget.onMoveTodoHere(details.data),
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: hovering
                ? colorScheme.primary.withValues(alpha: 0.08)
                : isUngrouped
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.40)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
            border: Border.all(
              color: hovering
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: hovering
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 10,
                  vertical: 8,
                ),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTitleRow(
                            context,
                            title: title,
                            isUngrouped: isUngrouped,
                            includeControls: false,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (hovering)
                                const Expanded(child: _DropHereLabel())
                              else
                                const Spacer(),
                              _buildGroupControls(compact: true),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildTitleRow(
                              context,
                              title: title,
                              isUngrouped: isUngrouped,
                              includeControls: true,
                            ),
                          ),
                          if (hovering)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: _DropHereLabel(),
                            ),
                        ],
                      ),
              ),
              if (!widget.collapsed)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 8 : 10,
                    0,
                    compact ? 8 : 10,
                    compact ? 8 : 10,
                  ),
                  child: widget.todos.isEmpty
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              hovering
                                  ? 'Release to move task here.'
                                  : 'No tasks here yet.',
                              style: TextStyle(
                                color: hovering
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                                fontWeight: hovering
                                    ? FontWeight.w800
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        )
                      : _TodoList(
                          shrinkWrap: true,
                          todos: widget.todos,
                          onMoveTodo: widget.onMoveTodo,
                          onStartDraggingTodo: widget.onStartDraggingTodo,
                          onFinishDraggingTodo: widget.onFinishDraggingTodo,
                          onToggleComplete: widget.onToggleComplete,
                          onTextChanged: widget.onTextChanged,
                          onPriorityCycle: widget.onPriorityCycle,
                          onPickDueDate: widget.onPickDueDate,
                          onClearDueDate: widget.onClearDueDate,
                          onDelete: widget.onDelete,
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        child: Text(
          '$count',
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _GroupSortMenu extends StatelessWidget {
  const _GroupSortMenu({
    required this.value,
    required this.enabled,
    this.compact = false,
    required this.onChanged,
  });

  final TodoSortMode value;
  final bool enabled;
  final bool compact;
  final ValueChanged<TodoSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<TodoSortMode>(
      enabled: enabled,
      tooltip: enabled ? 'Sort group' : 'Sorting disabled while dragging',
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final mode in TodoSortMode.values)
          PopupMenuItem<TodoSortMode>(
            value: mode,
            child: Row(
              children: [
                Icon(mode.icon, size: 18),
                const SizedBox(width: 10),
                Text(mode.label),
              ],
            ),
          ),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: enabled
              ? colorScheme.surface.withValues(alpha: 0.72)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(value.icon, size: 15, color: colorScheme.primary),
              if (!compact) ...[
                const SizedBox(width: 6),
                Text(
                  value.label,
                  style: TextStyle(
                    color: enabled
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DropHereLabel extends StatelessWidget {
  const _DropHereLabel();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      'Drop here',
      style: TextStyle(
        color: colorScheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _TodoList extends StatelessWidget {
  const _TodoList({
    this.shrinkWrap = false,
    required this.todos,
    required this.onMoveTodo,
    required this.onStartDraggingTodo,
    required this.onFinishDraggingTodo,
    required this.onToggleComplete,
    required this.onTextChanged,
    required this.onPriorityCycle,
    required this.onPickDueDate,
    required this.onClearDueDate,
    required this.onDelete,
  });

  final bool shrinkWrap;
  final List<TodoItem> todos;
  final void Function(TodoItem todo, String? beforeId) onMoveTodo;
  final ValueChanged<TodoItem> onStartDraggingTodo;
  final VoidCallback onFinishDraggingTodo;
  final ValueChanged<TodoItem> onToggleComplete;
  final void Function(TodoItem todo, String text) onTextChanged;
  final ValueChanged<TodoItem> onPriorityCycle;
  final ValueChanged<TodoItem> onPickDueDate;
  final ValueChanged<TodoItem> onClearDueDate;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: todos.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == todos.length) {
          return _TodoDropTarget(
            onAccept: (todo) => onMoveTodo(todo, null),
            compact: true,
          );
        }

        final todo = todos[index];
        return Column(
          children: [
            _TodoDropTarget(
              beforeId: todo.id,
              onAccept: (dragged) => onMoveTodo(dragged, todo.id),
            ),
            const SizedBox(height: 8),
            _DraggableTodoRow(
              key: ValueKey('draggable-${todo.id}'),
              todo: todo,
              onDragStarted: () => onStartDraggingTodo(todo),
              onDragEnded: onFinishDraggingTodo,
              onToggleComplete: () => onToggleComplete(todo),
              onTextChanged: (text) => onTextChanged(todo, text),
              onPriorityCycle: () => onPriorityCycle(todo),
              onPickDueDate: () => onPickDueDate(todo),
              onClearDueDate: () => onClearDueDate(todo),
              onDelete: () => onDelete(todo.id),
            ),
          ],
        );
      },
    );
  }
}

class _TodoDropTarget extends StatelessWidget {
  const _TodoDropTarget({
    required this.onAccept,
    this.beforeId,
    this.compact = false,
  });

  final ValueChanged<TodoItem> onAccept;
  final String? beforeId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DragTarget<TodoItem>(
      onWillAcceptWithDetails: (details) => details.data.id != beforeId,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: hovering
              ? 28
              : compact
              ? 8
              : 2,
          decoration: BoxDecoration(
            color: hovering
                ? colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: hovering
                ? Border.all(color: colorScheme.primary.withValues(alpha: 0.42))
                : null,
          ),
          alignment: Alignment.center,
          child: hovering
              ? Text(
                  'Drop to reorder',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _DraggableTodoRow extends StatelessWidget {
  const _DraggableTodoRow({
    super.key,
    required this.todo,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onToggleComplete,
    required this.onTextChanged,
    required this.onPriorityCycle,
    required this.onPickDueDate,
    required this.onClearDueDate,
    required this.onDelete,
  });

  final TodoItem todo;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final VoidCallback onToggleComplete;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onPriorityCycle;
  final VoidCallback onPickDueDate;
  final VoidCallback onClearDueDate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < _phoneLayoutWidth;

    if (compact) {
      return LongPressDraggable<TodoItem>(
        data: todo,
        delay: const Duration(milliseconds: 180),
        onDragStarted: onDragStarted,
        onDragEnd: (_) => onDragEnded(),
        onDraggableCanceled: (_, _) => onDragEnded(),
        onDragCompleted: onDragEnded,
        feedback: Material(
          color: Colors.transparent,
          child: _DragTodoFeedback(todo: todo),
        ),
        childWhenDragging: Opacity(
          opacity: 0.38,
          child: _TodoRow(
            todo: todo,
            onToggleComplete: onToggleComplete,
            onTextChanged: onTextChanged,
            onPriorityCycle: onPriorityCycle,
            onPickDueDate: onPickDueDate,
            onClearDueDate: onClearDueDate,
            onDelete: onDelete,
          ),
        ),
        child: _TodoRow(
          todo: todo,
          onToggleComplete: onToggleComplete,
          onTextChanged: onTextChanged,
          onPriorityCycle: onPriorityCycle,
          onPickDueDate: onPickDueDate,
          onClearDueDate: onClearDueDate,
          onDelete: onDelete,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Draggable<TodoItem>(
          data: todo,
          onDragStarted: onDragStarted,
          onDragEnd: (_) => onDragEnded(),
          onDraggableCanceled: (_, _) => onDragEnded(),
          onDragCompleted: onDragEnded,
          feedback: Material(
            color: Colors.transparent,
            child: _DragTodoFeedback(todo: todo),
          ),
          childWhenDragging: _DragHandle(color: colorScheme.primary),
          child: _DragHandle(
            color: colorScheme.onSurfaceVariant,
            compact: compact,
          ),
        ),
        SizedBox(width: compact ? 6 : 8),
        Expanded(
          child: _TodoRow(
            todo: todo,
            onToggleComplete: onToggleComplete,
            onTextChanged: onTextChanged,
            onPriorityCycle: onPriorityCycle,
            onPickDueDate: onPickDueDate,
            onClearDueDate: onClearDueDate,
            onDelete: onDelete,
          ),
        ),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.color, this.compact = false});

  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'Drag task',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SizedBox(
          width: compact ? 32 : 38,
          height: compact ? 40 : 44,
          child: Icon(
            Icons.drag_indicator,
            color: color,
            size: compact ? 20 : 24,
          ),
        ),
      ),
    );
  }
}

class _DragTodoFeedback extends StatelessWidget {
  const _DragTodoFeedback({required this.todo});

  final TodoItem todo;

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(todo.priority);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: priorityColor),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.drag_indicator, color: priorityColor, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  todo.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerDueButton extends StatelessWidget {
  const _ComposerDueButton({
    required this.dueDate,
    required this.onPickDueDate,
    required this.onClearDueDate,
  });

  final DateTime? dueDate;
  final VoidCallback onPickDueDate;
  final VoidCallback onClearDueDate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDueDate = dueDate != null;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: hasDueDate
              ? colorScheme.primary.withValues(alpha: 0.28)
              : colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPickDueDate,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 20,
                        color: hasDueDate
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hasDueDate ? _formatDueDate(dueDate!) : 'Due date',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasDueDate
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasDueDate)
                Tooltip(
                  message: 'Clear due date',
                  child: IconButton(
                    onPressed: onClearDueDate,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodoRow extends StatefulWidget {
  const _TodoRow({
    required this.todo,
    required this.onToggleComplete,
    required this.onTextChanged,
    required this.onPriorityCycle,
    required this.onPickDueDate,
    required this.onClearDueDate,
    required this.onDelete,
  });

  final TodoItem todo;
  final VoidCallback onToggleComplete;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onPriorityCycle;
  final VoidCallback onPickDueDate;
  final VoidCallback onClearDueDate;
  final VoidCallback onDelete;

  @override
  State<_TodoRow> createState() => _TodoRowState();
}

class _TodoRowState extends State<_TodoRow> {
  late final TextEditingController _editController;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.todo.text);
  }

  @override
  void didUpdateWidget(covariant _TodoRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.todo.text != widget.todo.text) {
      _editController.text = widget.todo.text;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() {
      _editing = true;
      _editController.text = widget.todo.text;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _editController.text = widget.todo.text;
    });
  }

  void _saveEdit() {
    final nextText = _editController.text.trim();
    if (nextText.isEmpty) return;
    widget.onTextChanged(nextText);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completed = widget.todo.completed;
    final priorityColor = _priorityColor(widget.todo.priority);
    final compact = MediaQuery.sizeOf(context).width < _phoneLayoutWidth;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: completed
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerLowest,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              ColoredBox(color: priorityColor, child: const SizedBox(width: 4)),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10,
                    vertical: compact ? 8 : 10,
                  ),
                  child: compact
                      ? _buildCompactContent(context, completed)
                      : _buildDesktopContent(context, completed),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopContent(BuildContext context, bool completed) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompleteButton(
          completed: completed,
          onPressed: widget.onToggleComplete,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _TodoMainContent(
              todo: widget.todo,
              editing: _editing,
              editController: _editController,
              compact: false,
              onSubmitted: _saveEdit,
              onPriorityCycle: widget.onPriorityCycle,
              onPickDueDate: widget.onPickDueDate,
              onClearDueDate: widget.onClearDueDate,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _TodoActions(
          editing: _editing,
          onEdit: _startEdit,
          onSave: _saveEdit,
          onCancel: _cancelEdit,
          onDelete: widget.onDelete,
        ),
      ],
    );
  }

  Widget _buildCompactContent(BuildContext context, bool completed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CompleteButton(
              completed: completed,
              onPressed: widget.onToggleComplete,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _TodoTitle(
                  todo: widget.todo,
                  editing: _editing,
                  editController: _editController,
                  onSubmitted: _saveEdit,
                ),
              ),
            ),
            _TodoActions(
              editing: _editing,
              compact: true,
              onEdit: _startEdit,
              onSave: _saveEdit,
              onCancel: _cancelEdit,
              onDelete: widget.onDelete,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: _TodoMetadata(
            todo: widget.todo,
            compact: true,
            onPriorityCycle: widget.onPriorityCycle,
            onPickDueDate: widget.onPickDueDate,
            onClearDueDate: widget.onClearDueDate,
          ),
        ),
      ],
    );
  }
}

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({required this.completed, required this.onPressed});

  final bool completed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: completed ? 'Mark active' : 'Mark complete',
      child: IconButton(
        onPressed: onPressed,
        color: completed ? colorScheme.primary : null,
        icon: Icon(
          completed ? Icons.check_circle : Icons.radio_button_unchecked,
        ),
      ),
    );
  }
}

class _TodoMainContent extends StatelessWidget {
  const _TodoMainContent({
    required this.todo,
    required this.editing,
    required this.editController,
    required this.compact,
    required this.onSubmitted,
    required this.onPriorityCycle,
    required this.onPickDueDate,
    required this.onClearDueDate,
  });

  final TodoItem todo;
  final bool editing;
  final TextEditingController editController;
  final bool compact;
  final VoidCallback onSubmitted;
  final VoidCallback onPriorityCycle;
  final VoidCallback onPickDueDate;
  final VoidCallback onClearDueDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TodoTitle(
          todo: todo,
          editing: editing,
          editController: editController,
          onSubmitted: onSubmitted,
        ),
        const SizedBox(height: 9),
        _TodoMetadata(
          todo: todo,
          compact: compact,
          onPriorityCycle: onPriorityCycle,
          onPickDueDate: onPickDueDate,
          onClearDueDate: onClearDueDate,
        ),
      ],
    );
  }
}

class _TodoTitle extends StatelessWidget {
  const _TodoTitle({
    required this.todo,
    required this.editing,
    required this.editController,
    required this.onSubmitted,
  });

  final TodoItem todo;
  final bool editing;
  final TextEditingController editController;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (editing) {
      return TextField(
        key: const ValueKey('todo-edit-field'),
        controller: editController,
        autofocus: true,
        decoration: const InputDecoration(
          isDense: true,
          labelText: 'Task name',
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => onSubmitted(),
      );
    }

    return Text(
      todo.text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        decoration: todo.completed ? TextDecoration.lineThrough : null,
        color: todo.completed ? colorScheme.onSurfaceVariant : null,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.25,
      ),
    );
  }
}

class _TodoMetadata extends StatelessWidget {
  const _TodoMetadata({
    required this.todo,
    required this.compact,
    required this.onPriorityCycle,
    required this.onPickDueDate,
    required this.onClearDueDate,
  });

  final TodoItem todo;
  final bool compact;
  final VoidCallback onPriorityCycle;
  final VoidCallback onPickDueDate;
  final VoidCallback onClearDueDate;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Tooltip(
          message: 'Change priority',
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPriorityCycle,
            child: _PriorityBadge(priority: todo.priority, compact: compact),
          ),
        ),
        _DueDateChip(
          dueDate: todo.dueDate,
          compact: compact,
          onPickDueDate: onPickDueDate,
          onClearDueDate: onClearDueDate,
        ),
      ],
    );
  }
}

class _TodoActions extends StatelessWidget {
  const _TodoActions({
    required this.editing,
    this.compact = false,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    required this.onDelete,
  });

  final bool editing;
  final bool compact;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 20.0 : 24.0;
    final constraints = compact
        ? const BoxConstraints.tightFor(width: 36, height: 36)
        : null;

    if (editing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Save',
            child: IconButton(
              constraints: constraints,
              onPressed: onSave,
              icon: Icon(Icons.check, size: size),
            ),
          ),
          Tooltip(
            message: 'Cancel',
            child: IconButton(
              constraints: constraints,
              onPressed: onCancel,
              icon: Icon(Icons.close, size: size),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Edit',
          child: IconButton(
            constraints: constraints,
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined, size: size),
          ),
        ),
        Tooltip(
          message: 'Delete',
          child: IconButton(
            constraints: constraints,
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, size: size),
          ),
        ),
      ],
    );
  }
}

class _DueDateChip extends StatelessWidget {
  const _DueDateChip({
    required this.dueDate,
    this.compact = false,
    required this.onPickDueDate,
    required this.onClearDueDate,
  });

  final DateTime? dueDate;
  final bool compact;
  final VoidCallback onPickDueDate;
  final VoidCallback onClearDueDate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPickDueDate,
        child: Padding(
          padding: EdgeInsets.only(
            left: compact ? 9 : 10,
            right: compact ? 6 : 4,
            top: compact ? 5 : 3,
            bottom: compact ? 5 : 3,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 136 : 220),
                child: Text(
                  dueDate == null
                      ? 'No due date'
                      : compact
                      ? _formatCompactDueDate(dueDate!)
                      : _formatDueDate(dueDate!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Tooltip(
                message: 'Set due date',
                child: IconButton(
                  constraints: compact
                      ? const BoxConstraints.tightFor(width: 30, height: 30)
                      : null,
                  visualDensity: VisualDensity.compact,
                  onPressed: onPickDueDate,
                  icon: Icon(
                    Icons.edit_calendar_outlined,
                    size: compact ? 16 : 18,
                  ),
                ),
              ),
              if (dueDate != null)
                Tooltip(
                  message: 'Clear due date',
                  child: IconButton(
                    constraints: compact
                        ? const BoxConstraints.tightFor(width: 30, height: 30)
                        : null,
                    visualDensity: VisualDensity.compact,
                    onPressed: onClearDueDate,
                    icon: Icon(Icons.close, size: compact ? 16 : 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority, this.compact = false});

  final TodoPriority priority;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      TodoPriority.low => _priorityColor(TodoPriority.low),
      TodoPriority.medium => _priorityColor(TodoPriority.medium),
      TodoPriority.high => _priorityColor(TodoPriority.high),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 10,
          vertical: compact ? 6 : 7,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag, size: compact ? 12 : 13, color: color),
            const SizedBox(width: 5),
            Text(
              priority.label,
              style: TextStyle(
                color: color,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _priorityColor(TodoPriority priority) {
  return switch (priority) {
    TodoPriority.low => const Color(0xFF22C55E),
    TodoPriority.medium => const Color(0xFFF59E0B),
    TodoPriority.high => const Color(0xFFEF4444),
  };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.task_alt_rounded,
                size: 30,
                color: colorScheme.primary.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'All clear!',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add a task above to get started.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatToday() {
  final now = DateTime.now();
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
}

String _formatDueDate(DateTime dueDate) {
  final hour = dueDate.hour % 12 == 0 ? 12 : dueDate.hour % 12;
  final minute = dueDate.minute.toString().padLeft(2, '0');
  final period = dueDate.hour < 12 ? 'AM' : 'PM';

  return '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-'
      '${dueDate.day.toString().padLeft(2, '0')} $hour:$minute $period';
}

String _formatCompactDueDate(DateTime dueDate) {
  final hour = dueDate.hour % 12 == 0 ? 12 : dueDate.hour % 12;
  final minute = dueDate.minute.toString().padLeft(2, '0');
  final period = dueDate.hour < 12 ? 'AM' : 'PM';

  return '${_monthLabel(dueDate.month)} ${dueDate.day}, $hour:$minute $period';
}

String _monthLabel(int month) {
  const labels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return labels[(month - 1).clamp(0, 11)];
}
