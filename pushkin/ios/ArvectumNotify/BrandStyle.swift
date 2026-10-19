import SwiftUI
import UIKit

extension Color {
    static let arvectumBackground = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 4/255, green: 26/255, blue: 51/255, alpha: 1)
                : UIColor(red: 243/255, green: 245/255, blue: 247/255, alpha: 1)
        }
    )
    static let arvectumSurface = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 36/255, green: 52/255, blue: 70/255, alpha: 1)
                : .white
        }
    )

    static let arvectumPrimaryText = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? .white
                : UIColor(red: 4/255, green: 26/255, blue: 51/255, alpha: 1)
        }
    )

    static let arvectumSecondaryText = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.68)
                : UIColor(red: 4/255, green: 26/255, blue: 51/255, alpha: 0.62)
        }
    )

    static let arvectumBorder = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.12)
                : UIColor(red: 4/255, green: 26/255, blue: 51/255, alpha: 0.10)
        }
    )
}
struct ArvectumBrandHeader: View {
    let productName: String

    var body: some View {
        HStack(spacing: 12) {
            Image("ArvectumWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 104, height: 28)

            Spacer(minLength: 8)

            Text(productName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(
            Color.arvectumNavy,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }
}

struct ArvectumCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.arvectumSurface,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.arvectumBorder, lineWidth: 1)
            )
    }
}


// MARK: - UX writing and RU/EN interface copy
// Each display string has one canonical English key. Non-Russian locales keep
// the original English text; the explicit locale parameter makes testing safe.
// Do not use this for Shortcuts action identifiers or data stored on disk.
enum PushkinCopy {
    static func text(
        _ english: String,
        language: String = Locale.preferredLanguages.first ?? "en"
    ) -> String {
        guard language.lowercased().hasPrefix("ru") else { return english }
        return russian[english] ?? english
    }

    private static let russian: [String: String] = [
        "History": "История",
        "Apps": "Источники",
        "Settings": "Настройки",
        "Search notifications": "Поиск уведомлений",
        "Clear search": "Очистить поиск",
        "History is empty": "История пока пуста",
        "Connect the apps you want to track in Shortcuts. Notifications captured from those sources will appear here.": "Подключите нужные приложения через «Команды». Здесь появятся уведомления из настроенных источников.",
        "Set up PUSHKIN": "Настроить сохранение",
        "Enable PUSHKIN automation": "Открыть автоматизации",
        "Delete": "Удалить",
        "Copy": "Копировать",
        "Share": "Поделиться",
        "Couldn’t delete notification": "Не удалось удалить уведомление",
        "Please try again.": "Повторите попытку.",
        "Add app": "Подключить приложение",
        "Test capture received": "Получено тестовое уведомление",
        "Finish adding %@": "Завершите подключение %@",
        "PUSHKIN received a notification from %@. This confirms that source only; check the automation in Shortcuts.": "Пушкин получил уведомление из %@. Это подтверждает работу только этого источника. Состояние автоматизации проверьте в «Командах».",
        "Done": "Готово",
        "In Shortcuts, tap Add, then enable the new automation (imports start disabled). PUSHKIN can observe a real notification from this app, but cannot read the Shortcuts enable switch.": "Добавьте команду в «Командах» и включите автоматизацию. Пушкин не может проверить положение системного переключателя: отправьте пробное уведомление.",
        "Open Automations": "Открыть автоматизации",
        "Possible duplicate": "Возможный дубликат",
        "Delete this notification?": "Удалить уведомление?",
        "From": "Источник",
        "Notification": "Уведомление",
        "No message body": "Без текста",
        "Time": "Время",
        "Received": "Получено",
        "Copy text": "Копировать текст",
        "Empty": "Нет данных",
        "Apps & Setup": "Источники",
        "Before you start": "Перед началом",
        "PUSHKIN works through Apple Shortcuts": "Пушкин работает через «Команды»",
        "iOS does not allow PUSHKIN to read every app's notifications or turn on automations itself. You control which apps are included.": "iOS не разрешает Пушкину читать все уведомления или включать автоматизации самостоятельно. Вы выбираете источники в приложении «Команды».",
        "The base shortcut includes 1,000 entries. Only apps recognized by Shortcuts when you configure the automation can send captures.": "Базовая команда содержит 1 000 вариантов приложений. Сработать смогут только те, которые «Команды» распознали при настройке.",
        "1. Add PUSHKIN": "1. Добавьте команду",
        "Open base shortcut in Shortcuts": "Открыть базовую команду",
        "Base shortcut is unavailable": "Базовая команда недоступна",
        "Shortcuts was opened — finish setup there": "«Команды» открыты — завершите настройку",
        "Opening the preview does not mean you tapped Add or enabled the automation.": "Открытие предварительного просмотра не означает, что команда добавлена и автоматизация включена.",
        "Review the app list and tap Add in Shortcuts. You do not have to manually select all 1,000 catalog apps.": "Проверьте список приложений и нажмите «Добавить» в «Командах». Не нужно выбирать все 1 000 приложений вручную.",
        "2. Enable the automation": "2. Включите автоматизацию",
        "Open Shortcuts automations": "Открыть автоматизации «Команд»",
        "Newly imported Notification automations are disabled. Find PUSHKIN, enable it and select the automatic/immediate option if Shortcuts offers it.": "Импортированные автоматизации по умолчанию выключены. Найдите Пушкин, включите его и выберите немедленный запуск, если он доступен.",
        "Only Shortcuts knows whether an automation is enabled. PUSHKIN cannot check or change that switch.": "Статус включения доступен только в «Командах». Пушкин не может прочитать или изменить этот переключатель.",
        "3. Check a real notification": "3. Проверьте уведомление",
        "At least one capture received": "Получено хотя бы одно уведомление",
        "Captured records": "Сохранено уведомлений",
        "Observed source apps": "Замечено источников",
        "Latest": "Последнее",
        "This proves PUSHKIN received a notification from at least one source. It does not prove that all selected apps are covered or that the automation is still enabled.": "Пушкин получил уведомление хотя бы из одного источника. Это не подтверждает работу остальных приложений или текущий статус автоматизации.",
        "Waiting for first capture": "Ожидаем первое уведомление",
        "Send one real notification from an app already installed and included in Shortcuts. Return to History to check the result.": "Получите уведомление от приложения, которое включено в автоматизацию. Затем проверьте его в «Истории».",
        "When you install another app": "Когда установите новое приложение",
        "Add or manage apps": "Добавить или настроить источники",
        "An app installed after the base shortcut was imported is not automatically connected, even if it is in the 1,000-app catalog. Import its signed one-app shortcut, enable it and verify a real notification.": "Новое приложение не подключается автоматически. Добавьте для него команду, включите автоматизацию и проверьте реальное уведомление.",
        "Optional: smaller groups": "Необязательно: группы источников",
        "Plan groups of apps": "Настроить группы",
        "If you prefer multiple Notification automations, prepare a local checklist. Groups of 25 are a convenience, not an Apple limitation, and must be configured manually.": "Можно разбить приложения на группы и вручную настроить несколько автоматизаций. Группы по 25 — рекомендация для удобства, а не ограничение iOS.",
        "Privacy": "Конфиденциальность",
        "Stored on this iPhone": "Хранится на этом iPhone",
        "No account, cloud sync, ads or analytics. PUSHKIN stores your notification content on this iPhone only.": "Пушкин хранит содержимое уведомлений только на этом iPhone, без учётной записи, облачной синхронизации, рекламы и аналитики.",
        "Delete all notification history?": "Удалить всю историю уведомлений?",
        "Delete All": "Удалить всё",
        "This cannot be undone. PUSHKIN setup and app coverage stay intact.": "Восстановить историю не получится. Настройки подключения источников сохранятся.",
        "Couldn’t clear history": "Не удалось очистить историю",
        "On this iPhone": "На этом iPhone",
        "Notifications saved": "Сохранено уведомлений",
        "Notification content stays on this device": "Содержимое хранится на устройстве",
        "Everything stays on this iPhone. No account, cloud sync, ads or analytics in version 1.0.": "Данные уведомлений остаются на этом iPhone. Нет учётной записи, синхронизации с облаком, рекламы или аналитики.",
        "Delete all history": "Удалить всю историю",
        "Help & feedback": "Помощь и обратная связь",
        "Support and missing-app requests": "Поддержка и новые источники",
        "Missing an app? Send us its exact name. The most-requested apps move to the top of our update list.": "Нет нужного приложения? Сообщите его точное название — учтём при обновлении каталога.",
        "About": "О приложении",
        "Privacy policy": "Политика конфиденциальности",
        "Product": "Продукт",
        "Developer": "Для разработчика",
        "Version": "Версия",
        "Review notifications captured from apps you connected.": "Просматривайте уведомления от подключённых приложений.",
        "Diagnostics": "Диагностика",
        "Offline catalog": "Офлайн-каталог",
        "Signed app options": "Приложений в каталоге",
        "App packages opened": "Открыто пакетов приложений",
        "Add an app": "Подключение приложения",
        "Add app to PUSHKIN": "Подключить приложение",
        "Importing a signed app package opens Shortcuts but does not enable the new automation. Enable it there and check a real notification. If missing from this catalog, use the manual guide.": "Импорт пакета откроет «Команды», но не включит автоматизацию. Включите её и проверьте уведомление. Если приложения нет в каталоге, используйте ручную настройку.",
        "Optional groups": "Дополнительные группы",
        "Plan smaller groups": "Настроить группы",
        "One base shortcut can contain 1,000 app entries. Optional groups of 25 are just a planning convenience, not an iOS limit.": "Одна базовая команда может содержать 1 000 приложений. Деление на группы по 25 — лишь вариант организации, не предел iOS.",
        "Shortcuts": "Команды",
        "Newly imported automations are disabled. Turn each one on in Shortcuts; PUSHKIN cannot read its enabled state. A notification from one app does not verify every app.": "Новые автоматизации выключены по умолчанию. Включите их в «Командах». Пушкин не видит состояние переключателя; успешный тест одного приложения не подтверждает остальные.",
        "Search apps": "Поиск приложений",
        "Searches the offline catalog bundled with this version of PUSHKIN.": "Поиск по офлайн-каталогу текущей версии Пушкина.",
        "Popular apps": "Популярные приложения",
        "In PUSHKIN": "В каталоге",
        "Not in this version": "Нет в этой версии",
        "You can still add this app manually in Shortcuts.": "Приложение можно подключить вручную через «Команды».",
        "Add manually": "Добавить вручную",
        "App not listed? Add manually": "Нет приложения? Добавить вручную",
        "Manual setup takes a few more taps, but stays entirely on your iPhone and needs no PUSHKIN server.": "Ручная настройка займёт немного больше времени, но выполняется на iPhone без сервера Пушкина.",
        "Add App": "Подключить приложение",
        "Cancel": "Отмена",
        "This path is only for apps missing from the built-in catalog.": "Этот способ нужен для приложений, которых нет во встроенном каталоге.",
        "Nothing is uploaded. You create one Notification automation directly in Apple's Shortcuts app.": "Ничего не загружается на сервер. Вы создаёте автоматизацию прямо в «Командах».",
        "1. Choose the app": "1. Выберите приложение",
        "Open Shortcuts → Automation → + → Notification → App, then choose the app you want to add.": "Откройте «Команды» → «Автоматизация» → «+» → «Уведомление» → «Приложение» и выберите источник.",
        "Open Shortcuts Automations": "Открыть автоматизации",
        "You searched for": "Вы искали",
        "2. Add the PUSHKIN action": "2. Добавьте действие Пушкина",
        "Add the action PUSHKIN → Archive Notification.": "Добавьте действие PUSHKIN → Archive Notification (название действия зависит от языка системы).",
        "3. Map the notification": "3. Настройте поля",
        "Source app": "Источник",
        "Title": "Заголовок",
        "Subtitle": "Подзаголовок",
        "Message": "Сообщение",
        "When Shortcuts asks how the automation should run, choose the immediate/automatic option.": "При выборе способа запуска укажите немедленный или автоматический, если он доступен.",
        "4. Save": "4. Сохраните",
        "Save and make sure the new automation is enabled. The first matching notification should then appear in PUSHKIN automatically.": "Сохраните и проверьте, что автоматизация включена. После подходящего уведомления проверьте запись в «Истории».",
        "Help us improve the catalog": "Помогите улучшить каталог",
        "Want this app to become a one-tap option? Mention its exact name in an App Store review or send it to Arvectum support. Requested apps can be added in regular catalog updates.": "Хотите добавить приложение в каталог? Отправьте его точное название в поддержку Arvectum.",
        "Add Manually": "Добавить вручную",
    ]
}

func pc(_ english: String) -> String {
    PushkinCopy.text(english)
}
