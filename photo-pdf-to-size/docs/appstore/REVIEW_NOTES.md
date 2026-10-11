# App Review notes — iOS 0.4.2

The app does not require registration or sign-in. All functionality is available immediately after launch.

Images are selected through the system iOS photo picker and processed locally on-device. The app has no backend, advertising SDK, analytics SDK, or account system.

There are three modes:
1. **По весу** — reduces the selected image so the output does not exceed the chosen file-size limit.
2. **По размеру** — resizes by the image's long side while preserving aspect ratio and does not enlarge smaller images.
3. **На паспорт** — provides manual 35×45 cropping and exports a JPEG at 620×797 px and 450 DPI.

The passport mode is a technical file-preparation utility only. It does not alter or validate the face, background, pose, appearance, or eligibility of the photographed person, and the app is not affiliated with a government authority.

No special test account or review credentials are required.
