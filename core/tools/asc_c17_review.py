#!/usr/bin/env python3
"""C17 App Review notes and final submit (never submit before verified localizations/images)."""
import sys,hashlib,json
import asc_c17_release as asc
NOTES={
'photo':"""Photo and PDF compression and document-photo utility, no account or payment required.
TEST: Pick a photo using Photos or Files; choose a 100KB/500KB/1MB size preset, compress, view the before/after measurements and use Share/Save. Resize by pixel dimensions under the second mode. Import a PDF from Files and compress it. Document photo mode has presets for RU/US/UK/India/Schengen/China/Canada.
PRIVACY: All user-selected photos and PDFs are compressed locally on the device; user-selected source files are never uploaded for processing. The optional metadata stripping also runs locally. This free app displays Yandex Mobile Ads; its advertising components may transmit SDK-related advertising/device data as disclosed in the App Privacy section. Declining ad data consent still displays non-personalized ads. ATT is only requested after positive user consent. Strong PDF size reduction may rasterize pages and remove selectable text; the UI informs users. Visa/passport acceptance is not guaranteed. No account or demo credentials are required.
Accessibility: native controls, labels, and Dynamic Type. No network server is needed to process a file.""",
'pushkin':"""PUSHKIN is an iPhone notification-history utility using user-configured Shortcuts notification automations, not unauthorized system notification interception.
TEST: Launch, open Apps & Setup, select a supported app, import its signed bundled Shortcut, and explicitly enable its automation in Apple Shortcuts. Trigger a real notification from that app; check PUSHKIN's History. Without Shortcuts configuration the history remains empty by design. Manual setup is available for unsupported apps; this is not universal background interception. International source suggestions (Gmail, Instagram, Discord, Signal, Uber, DoorDash) are existing offline catalog entries; Slack is not supported in this release.
Notification contents are saved locally on the iPhone, without backend/cloud analytics. No account, demo credentials, payments or other services required.""",
'what':"""UhWhat? ('Ухват') supports quick local audio, text, and video notes on iPhone, voice recording on paired Apple Watch, and transcription of saved recordings.
TEST: On the iPhone, tap Record and grant microphone permission. Stop recording, open the Library, play audio; tap Transcribe to turn saved audio into text (microphone/speech permissions as requested). Before transcription, explanatory text appears below each recording. Text notes and local video notes can also be created. A paired Apple Watch offers independent local watch recording and later delivery to iPhone; Watch tests require a paired watch and accessible device, and do not require an account. Original audio is retained independently of transcription. With speech models unavailable, transcription may require on-device model availability. No login or demo credentials.
The Watch complication and iPhone widget use only local app data; recorded notes are not uploaded to our servers.""",
'chickmark':"""ChickMark habit tracker for iPhone, with optional Apple Watch companion and widgets.
TEST: Start from the Today screen, tap Create habit, enter name and schedule, optionally type a custom group name in the form and tap New group. Save and mark the habit complete. Create a one-time reminder from the Add menu, optionally allow notifications. Manage habits opens existing groups and preferences. Optional Apple Health integration requests permissions only after the user opts in; it is not required for core functionality.
Data is stored locally with optional Apple account/iCloud synchronization; promotional native ads use their own third-party SDK disclosure and user consent. No registration, subscription, demo account or payment required.
No reviewer setup or external account is necessary for the normal habit flow."""
}
def notes():
 for app in asc.APPS:
  v=asc.version(app);vid=v['id']
  data=asc.must('GET',f'/appStoreVersions/{vid}/appStoreReviewDetail').get('data')
  if data is None:raise RuntimeError(f'No inherited reviewer contact, need manual completion for {app}')
  fields=data['attributes']
  # Never put reviewer personal contact fields into log or repo.
  patch={k:fields.get(k) for k in ('contactFirstName','contactLastName','contactEmail','contactPhone') if fields.get(k)}
  if len(patch)!=4:raise RuntimeError(f'Missing review contact {app}')
  patch.update({'demoAccountRequired':False,'notes':NOTES[app]})
  asc.must('PATCH',f'/appStoreReviewDetails/{data["id"]}',{'data':{'type':'appStoreReviewDetails','id':data['id'],'attributes':patch}})
  print('REVIEW_NOTES_SAVED',app,flush=True)
def final_check():
 for app in asc.APPS:
  version=asc.version(app)
  if version['appStoreState'] not in ('PREPARE_FOR_SUBMISSION','READY_FOR_REVIEW','WAITING_FOR_REVIEW'):raise RuntimeError(f'Unexpected version status {app}')
  rec=asc.state['apps'][app]
  if not rec.get('metadataComplete') or not rec.get('buildAttached'):
   raise RuntimeError(f'Release metadata/build incomplete {app}')
  locales=asc.attrs(asc.must('GET',f'/appStoreVersions/{version["id"]}/appStoreVersionLocalizations?limit=50'))
  if len(locales)!=16:raise RuntimeError(f'Expected 16 ASC locales for {app}, got {len(locales)}')
  assets=rec.get('screenshotsComplete',{})
  if len(assets)!=16:raise RuntimeError(f'Only {len(assets)} screenshot locales for {app}')
  expected_per_locale=1 if app=='pushkin' else 2
  if any(len(set(devs))<expected_per_locale for devs in assets.values()):
   raise RuntimeError(f'Incomplete screenshot device coverage {app}')
  r=asc.must('GET',f'/appStoreVersions/{version["id"]}/relationships/build')['data']
  if r['id']!=rec['buildId']:raise RuntimeError(f'Build relationship mismatch {app}')
  if version.get('releaseType')!='AFTER_APPROVAL':raise RuntimeError(f'Wrong releaseType {app}')
  print('FULL_PREFLIGHT_OK',app,len(locales),len(assets),flush=True)
def submit():
 final_check()
 for app,aid in asc.APPS.items():
  v=asc.version(app)
  if v['appStoreState'] in ('WAITING_FOR_REVIEW','IN_REVIEW','READY_FOR_SALE'):
   print('ALREADY_SUBMITTED',app,v['appStoreState']);continue
  subs=asc.attrs(asc.must('GET',f'/apps/{aid}/reviewSubmissions?limit=30'))
  draft=None
  for candidate in subs:
   if candidate.get('state') not in ('READY_FOR_REVIEW','DRAFT','WAITING_FOR_REVIEW'):continue
   existing=asc.must('GET',f'/reviewSubmissions/{candidate["id"]}/items?limit=100')['data']
   if any((item.get('relationships',{}).get('appStoreVersion',{}).get('data') or {}).get('id')==v['id'] for item in existing):
    draft=candidate
    break
  if draft:sid=draft['id']
  else:
   p={'data':{'type':'reviewSubmissions','attributes':{'platform':'IOS'},
     'relationships':{'app':{'data':{'type':'apps','id':aid}}}}}
   result=asc.must('POST','/reviewSubmissions',p,ok=(201,))
   sid=result['data']['id']
  current=asc.must('GET',f'/reviewSubmissions/{sid}/items?limit=200')['data']
  if not any((item.get('relationships',{}).get('appStoreVersion',{}).get('data') or {}).get('id')==v['id'] for item in current):
   p={'data':{'type':'reviewSubmissionItems','relationships':{
      'reviewSubmission':{'data':{'type':'reviewSubmissions','id':sid}},
      'appStoreVersion':{'data':{'type':'appStoreVersions','id':v['id']}}}}}
   asc.must('POST','/reviewSubmissionItems',p,ok=(201,))
  asc.must('PATCH',f'/reviewSubmissions/{sid}',{'data':{'type':'reviewSubmissions','id':sid,
    'attributes':{'submitted':True}}})
  asc.state['apps'][app]['reviewSubmissionId']=sid;asc.save()
  print('APPLE_REVIEW_SUBMITTED',app,sid,flush=True)
if __name__=='__main__':
 globals()[sys.argv[1]]()
