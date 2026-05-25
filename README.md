# Telegram Clone

Flutter-клон Telegram с авторизацией по номеру телефона, списком чатов,
экраном контактов, личными сообщениями и Firestore-синхронизацией.

## Что готово

- Интерфейс ближе к мобильному Telegram: чистый phone sign-in, синий app bar,
  drawer, компактный список чатов, аватары, bubble-сообщения и нижний composer.
- Firebase Auth по номеру телефона через SMS-код.
- Профили пользователей в `users`, чтобы можно было находить контакт по номеру.
- Личные чаты между двумя зарегистрированными пользователями.
- Сообщения хранятся в `chats/{chatId}/messages` и обновляются real-time.
- Локальный demo mode остается: если Firebase еще не настроен, вход работает с
  любым номером формата `+...` и кодом `123456`.

## Запуск

```bash
flutter pub get
flutter run
```

## Firebase: пошагово

1. Создай проект в Firebase Console.
2. Добавь Android-приложение:
   - package name: `com.example.telegram_clone`
   - если поменяешь `applicationId` в `android/app/build.gradle.kts`, такой же
     package name укажи в Firebase.
3. Настрой FlutterFire:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Выбери свой Firebase project и Android. Команда обновит
`lib/firebase_options.dart`.

4. Добавь SHA-1 и SHA-256 для Android:

```powershell
cd android
.\gradlew signingReport
```

В выводе найди `Variant: debug`, скопируй `SHA1` и `SHA-256`.
Firebase Console -> Project settings -> General -> Your apps -> Android app ->
SHA certificate fingerprints -> Add fingerprint. Добавь оба значения.

Для release-сборки добавь SHA-1/SHA-256 уже от release keystore или из Google
Play Console, если используешь Play App Signing.

5. Включи вход по номеру:
   - Firebase Console -> Authentication -> Sign-in method.
   - Включи `Phone`.
   - Для тестов добавь test phone number и code, чтобы не тратить SMS-квоту.

6. Создай базу:
   - Firebase Console -> Firestore Database -> Create database.
   - Выбери регион.
   - Можно выбрать Production mode, потом сразу задеплоить правила ниже.

7. Установи Firebase CLI и войди:

```bash
npm install -g firebase-tools
firebase login
firebase use --add
```

8. Задеплой правила Firestore:

```bash
firebase deploy --only firestore:rules
```

## Структура Firestore

- `users/{uid}`: `displayName`, `phoneNumber`, `phoneSearchKey`, `avatarColor`.
- `chats/{chatId}`: `type`, `members`, `memberNames`, `memberPhones`,
  `lastMessage`, `lastMessageAt`.
- `chats/{chatId}/messages/{messageId}`: `senderId`, `senderName`, `text`,
  `sentAt`, `isEdited`, `isRead`.

## Можно ли писать контактам?

Да. Сейчас работает так: человек заходит в приложение по номеру телефона, его
профиль сохраняется в `users`, после этого другой пользователь может открыть
`Contacts` или `Find by Phone Number` и начать личный чат.

Это не импорт всей телефонной книги устройства. Для настоящего импорта контактов
как в Telegram нужно отдельно добавить пакет `flutter_contacts`, разрешения
Android/iOS и сверку номеров телефона с `users.phoneSearchKey`.
