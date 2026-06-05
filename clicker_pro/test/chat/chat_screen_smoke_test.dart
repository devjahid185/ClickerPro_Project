// test/chat/chat_screen_smoke_test.dart

import 'package:clicker_pro/features/chat/application/chat_providers.dart';
import 'package:clicker_pro/features/chat/domain/chat_group.dart';
import 'package:clicker_pro/features/chat/domain/chat_message.dart';
import 'package:clicker_pro/features/chat/domain/chat_repository.dart';
import 'package:clicker_pro/features/chat/presentation/chat_screen.dart';
import 'package:clicker_pro/features/auth/domain/user_role.dart';
import 'package:clicker_pro/features/profile/application/profile_controllers.dart';
import 'package:clicker_pro/features/profile/domain/user_model.dart';
import 'package:clicker_pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeChatRepo implements ChatRepository {
  _FakeChatRepo({this.group, this.thread = const <ChatMessage>[]});

  ChatGroup? group;
  List<ChatMessage> thread;
  final List<({String groupId, String text})> sent = [];
  int createCalls = 0;

  @override
  Future<ChatGroup?> myGroup() async => group;

  @override
  Future<ChatGroup> createGroup() async {
    createCalls++;
    final g = const ChatGroup(
      id: 'g-1',
      name: "My Studio's Team Chat",
      ownerId: 'owner-1',
    );
    group = g;
    return g;
  }

  @override
  Future<List<ChatMessage>> messages(String groupId) async => List.of(thread);

  @override
  Future<ChatMessage> send({
    required String groupId,
    required String text,
  }) async {
    sent.add((groupId: groupId, text: text));
    final saved = ChatMessage(
      id: 'srv-${sent.length}',
      groupId: groupId,
      senderId: '_self',
      text: text,
      sentAt: DateTime.now(),
    );
    thread = [...thread, saved];
    return saved;
  }
}

Future<void> _pump(WidgetTester tester, {required ChatRepository repo}) async {
  final user = UserModel(
    id: 'u-self',
    name: 'Test Self',
    email: 'self@example.com',
    role: UserRole.owner,
    phone: '0170000',
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repo),
        currentUserProvider.overrideWith(
          (ref) => Stream<UserModel?>.value(user),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ChatScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('renders no-group state with create CTA', (tester) async {
    final repo = _FakeChatRepo();
    await _pump(tester, repo: repo);

    expect(find.text('Team chat'), findsOneWidget);
    expect(find.textContaining('No team chat yet'), findsOneWidget);
    expect(find.text('Create team chat'), findsOneWidget);
  });

  testWidgets('Create team chat triggers createGroup + transitions to thread', (
    tester,
  ) async {
    final repo = _FakeChatRepo();
    await _pump(tester, repo: repo);

    expect(repo.createCalls, 0);
    await tester.tap(find.text('Create team chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(repo.createCalls, 1);
    // Empty thread message renders for the freshly-created group
    expect(find.textContaining('No messages yet'), findsOneWidget);
  });

  testWidgets('renders thread with bubbles when messages exist', (
    tester,
  ) async {
    final repo = _FakeChatRepo(
      group: const ChatGroup(
        id: 'g-1',
        name: "My Studio's Team Chat",
        ownerId: 'owner-1',
      ),
      thread: [
        ChatMessage(
          id: 'm1',
          groupId: 'g-1',
          senderId: 'staff-1',
          text: 'Hi team',
          sentAt: DateTime.now().subtract(const Duration(hours: 2)),
          senderName: 'Karim',
        ),
        ChatMessage(
          id: 'm2',
          groupId: 'g-1',
          senderId: 'staff-2',
          text: 'Welcome aboard',
          sentAt: DateTime.now(),
          senderName: 'Rahim',
        ),
      ],
    );

    await _pump(tester, repo: repo);

    expect(find.text('Hi team'), findsOneWidget);
    expect(find.text('Welcome aboard'), findsOneWidget);
    expect(find.text('Karim'), findsOneWidget);
    expect(find.text('Rahim'), findsOneWidget);
  });
}
