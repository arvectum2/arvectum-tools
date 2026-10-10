#!/usr/bin/env python3
"""Static, non-uploading audit of the built app/Watch/widget archive."""
from pathlib import Path
import plistlib,sys,json

archive=Path(sys.argv[1]) if len(sys.argv)>1 else Path('/tmp/habits-archive-smoke/HabitsByArvectum.xcarchive')
app=archive/'Products/Applications/HabitsByArvectum.app'
components={
 'iphone': app,
 'ios_widget': app/'PlugIns/HabitsByArvectumWidget.appex',
 'watch': app/'Watch/HabitsByArvectumWatch.app',
 'watch_widget': app/'Watch/HabitsByArvectumWatch.app/PlugIns/HabitsByArvectumWatchWidget.appex',
}
errors=[];info={}
for label,location in components.items():
 path=location/'Info.plist';privacy=location/'PrivacyInfo.xcprivacy'
 if not path.is_file() or not privacy.is_file():
  errors.append(label+' missing Info.plist or privacy manifest');continue
 with path.open('rb') as f: p=plistlib.load(f)
 with privacy.open('rb') as f: m=plistlib.load(f)
 info[label]={
  'bundle':p.get('CFBundleIdentifier'),
  'version':p.get('CFBundleShortVersionString'),
  'build':p.get('CFBundleVersion'),
  'privacy_tracking':m.get('NSPrivacyTracking',False),
  'privacy_collected_types':len(m.get('NSPrivacyCollectedDataTypes',[])),
 }
 if m.get('NSPrivacyTracking',False):errors.append(label+' privacy tracking declared')
 if m.get('NSPrivacyCollectedDataTypes',[]):errors.append(label+' declares collected data; review ASC responses')
 if not (location/p.get('CFBundleExecutable','')).is_file():errors.append(label+' missing executable')
for label,row in info.items():
 if row['version']!='1.3.0' or row['build']!='5':errors.append(label+' bundle version mismatch')
expected={'iphone':'ru.arvectum.tools.habits','ios_widget':'ru.arvectum.tools.habits.widget','watch':'ru.arvectum.tools.habits.watch','watch_widget':'ru.arvectum.tools.habits.watch.widget'}
for label,bid in expected.items():
 if info.get(label,{}).get('bundle')!=bid:errors.append(label+' bundle id mismatch '+str(info.get(label,{}).get('bundle')))
print(json.dumps({'archive':str(archive),'bundles':info,'errors':errors},ensure_ascii=False,indent=2))
if errors:sys.exit(1)
