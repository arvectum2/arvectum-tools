#!/usr/bin/env python3
"""Stage localized What's New for 4 iOS candidates without Apple Connect writes."""
import json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
P=R/'core/appstore/staged-2026-10-26'
LOCALES={
 'ru':'ru','en-US':'en','en-GB':'en','en-AU':'en','en-CA':'en',
 'es-ES':'es','es-MX':'es','fr-FR':'fr','de-DE':'de','it':'it',
 'ja':'ja','ko':'ko','pt-BR':'pt-BR','pt-PT':'pt-PT',
 'zh-Hans':'zh-Hans','zh-Hant':'zh-Hant'
}
NOTES={
 'photo':{
  'ru':'Теперь проще вернуться к настройкам после обработки фото. Улучшена навигация; обработка фото и PDF по-прежнему выполняется на устройстве.',
  'en':'A clearer way back to settings after processing photos. Photo and PDF files are still processed on your device.',
  'es':'Ahora es más fácil volver a los ajustes después de procesar una foto. Las fotos y los PDF siguen procesándose en tu dispositivo.',
  'fr':'Le retour aux réglages après le traitement d’une photo est plus clair. Les photos et PDF sont toujours traités sur votre appareil.',
  'de':'Nach der Fotobearbeitung kommst du leichter zu den Einstellungen zurück. Fotos und PDFs werden weiterhin auf deinem Gerät verarbeitet.',
  'it':'Tornare alle impostazioni dopo aver elaborato una foto è più semplice. Foto e PDF restano elaborati sul dispositivo.',
  'ja':'写真の処理後、設定画面へ戻りやすくなりました。写真とPDFの処理は引き続き端末上で行われます。',
  'ko':'사진 처리 후 설정으로 더 쉽게 돌아갈 수 있습니다. 사진과 PDF는 계속 기기에서 직접 처리됩니다.',
  'pt-BR':'Ficou mais fácil voltar às configurações após processar uma foto. Fotos e PDFs continuam sendo processados no dispositivo.',
  'pt-PT':'Agora é mais fácil voltar às definições depois de processar uma fotografia. As fotografias e os PDF continuam a ser processados no dispositivo.',
  'zh-Hans':'处理照片后更容易返回设置。照片和 PDF 仍在设备本地处理。',
  'zh-Hant':'處理照片後更容易返回設定。照片和 PDF 仍在裝置本機處理。'
 },
 'pushkin':{
  'ru':'Международные приложения теперь проще найти в списке быстрых подключений. Сохранение уведомлений по-прежнему требует настроенной автоматизации в «Командах».',
  'en':'Popular international apps are easier to find in the suggested setup list. Saving notifications still requires your configured Shortcuts automations.',
  'es':'Ahora es más fácil encontrar aplicaciones internacionales en la lista de configuración. Para guardar notificaciones sigue siendo necesario configurar las automatizaciones de Atajos.',
  'fr':'Les applications internationales sont plus faciles à trouver dans la liste de configuration. L’enregistrement des notifications nécessite toujours vos automatisations Raccourcis.',
  'de':'Internationale Apps findest du jetzt leichter in der Einrichtungsliste. Zum Speichern von Mitteilungen müssen weiterhin Kurzbefehle-Automationen eingerichtet sein.',
  'it':'Le app internazionali sono più facili da trovare nell’elenco di configurazione. Per salvare le notifiche occorrono comunque le automazioni di Comandi.',
  'ja':'海外の人気アプリを設定候補から探しやすくなりました。通知の保存には、引き続きショートカットのオートメーション設定が必要です。',
  'ko':'해외에서 많이 사용하는 앱을 설정 목록에서 더 쉽게 찾을 수 있습니다. 알림 저장에는 여전히 단축어 자동화 설정이 필요합니다.',
  'pt-BR':'Ficou mais fácil encontrar apps internacionais na lista de configuração. Salvar notificações ainda exige as automações configuradas no Atalhos.',
  'pt-PT':'Agora é mais fácil encontrar aplicações internacionais na lista de configuração. Guardar notificações continua a exigir as automações configuradas na app Atalhos.',
  'zh-Hans':'现在更容易在设置列表中找到常用的国际应用。保存通知仍需自行配置“快捷指令”自动化。',
  'zh-Hant':'現在更容易在設定清單中找到常用的國際應用程式。儲存通知仍需自行設定「捷徑」自動化。'
 },
 'what':{
  'ru':'Под аудиозаписью стало понятнее, как получить расшифровку. Улучшены подсказки по работе с аудио и текстом.',
  'en':'Clearer guidance on how to transcribe a saved recording. Audio and text actions are now easier to understand.',
  'es':'Instrucciones más claras para transcribir una grabación guardada. Ahora resulta más fácil entender las acciones de audio y texto.',
  'fr':'Des indications plus claires pour transcrire un enregistrement. Les actions audio et texte sont plus faciles à comprendre.',
  'de':'Klarere Hinweise zum Transkribieren gespeicherter Aufnahmen. Audio- und Textaktionen sind jetzt verständlicher.',
  'it':'Indicazioni più chiare per trascrivere una registrazione salvata. Le azioni relative ad audio e testo sono più semplici.',
  'ja':'保存した録音を文字起こしする方法がより分かりやすくなりました。音声とテキストの操作も明確になりました。',
  'ko':'저장한 녹음을 텍스트로 변환하는 방법이 더 명확해졌습니다. 오디오와 텍스트 작업을 쉽게 이해할 수 있습니다.',
  'pt-BR':'Orientações mais claras para transcrever uma gravação salva. Agora as ações de áudio e texto são mais fáceis de entender.',
  'pt-PT':'Instruções mais claras para transcrever uma gravação guardada. As ações de áudio e texto são agora mais fáceis de compreender.',
  'zh-Hans':'更清楚地说明如何转写已保存的录音，让音频和文本操作更易理解。',
  'zh-Hant':'更清楚地說明如何轉錄已儲存的錄音，讓音訊和文字操作更容易理解。'
 },
 'chickmark':{
  'ru':'Теперь собственную группу можно создать прямо при добавлении привычки. Не нужно выходить из формы или искать отдельные настройки.',
  'en':'Create a custom group right inside the new-habit form. No need to leave the form or hunt through settings.',
  'es':'Ahora puedes crear un grupo personalizado al añadir un hábito, sin salir del formulario ni buscar otra pantalla.',
  'fr':'Créez un groupe personnalisé directement lors de l’ajout d’une habitude, sans quitter le formulaire.',
  'de':'Eigene Gruppen lassen sich jetzt direkt beim Anlegen einer Gewohnheit erstellen, ohne das Formular zu verlassen.',
  'it':'Ora puoi creare un gruppo personalizzato direttamente mentre aggiungi un’abitudine, senza uscire dal modulo.',
  'ja':'新しい習慣の追加画面から、そのまま自分用のグループを作成できるようになりました。',
  'ko':'새 습관을 추가하는 화면에서 나만의 그룹을 바로 만들 수 있습니다. 다른 설정 화면으로 이동할 필요가 없습니다.',
  'pt-BR':'Agora você pode criar um grupo personalizado ao adicionar um hábito, sem sair do formulário.',
  'pt-PT':'Agora pode criar um grupo personalizado ao adicionar um hábito, sem sair do formulário.',
  'zh-Hans':'现在可以直接在添加习惯的表单中创建自定义分组，无需切换到设置。',
  'zh-Hant':'現在可以直接在新增習慣的表單中建立自訂群組，不必切換至設定。'
 }
}
patch={}
for app,variants in NOTES.items():
 current=json.loads((P/f'{app}.json').read_text())
 patch[app]={}
 for asc,lang in LOCALES.items():
  note=variants[lang]
  assert asc in current['localeData'] and note and len(note)<=4000
  patch[app][asc]={'before':current['localeData'][asc]['whatsNew'],'after':note}
  current['localeData'][asc]['whatsNew']=note
 (P/f'{app}.json').write_text(json.dumps(current,ensure_ascii=False,indent=2)+'\n')
path=P/'editorial/c17-feedback-whatsnew-overrides.json'
path.write_text(json.dumps(patch,ensure_ascii=False,indent=2)+'\n')
print('Staged 64 region-specific release notes from 12 UI languages; no Apple writes')
