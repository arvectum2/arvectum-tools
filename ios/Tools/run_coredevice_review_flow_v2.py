#!/Users/master/.venvs/pymobiledevice3/bin/python
"""
Final App Review physical-device capture for Фото под размер 0.4.2 (2).

Implements the iOS Physical Device Review Capture workflow:
CoreDevice userspace tunnel -> DisplayService raw HEVC ->
UniversalHIDService interaction -> ScreenCaptureService checkpoints.

Preconditions:
- physical iPhone 13 is USB-connected and unlocked;
- build 0.4.2 (2) is installed and has passed iOS developer verification;
- network notifications are suppressed before capture.
"""
import asyncio, contextlib
from pathlib import Path

from pymobiledevice3.remote.userspace_tunnel import UserspaceRsdTunnel
from pymobiledevice3.remote.core_device.display_service import DisplayService
from pymobiledevice3.remote.core_device.screen_stream import open_media_receiver, depacketize_hevc
from pymobiledevice3.remote.core_device.hid_service import (
    UniversalHIDServiceService,
    TOUCHSCREEN_STATE_CONTACT,
    TOUCHSCREEN_STATE_RELEASE,
)
from pymobiledevice3.remote.core_device.screen_capture_service import ScreenCaptureService
from pymobiledevice3.remote.core_device.app_service import AppServiceService

ROOT=Path("/Users/master/arvectum-tools/ios/review-video/final")
ROOT.mkdir(parents=True,exist_ok=True)
RAW=ROOT/"photo-pod-razmer-0.4.2-2-AppReview.hevc"
FPS_FILE=ROOT/"capture-fps.txt"
UDID="00008110-001C51810A12401E"
BUNDLE="ru.arvectum.tools.tosize"
W,H=1170,2532
TOUCH_SERVICE_ID=257
MAX_DURATION=110.0

WEIGHT=ROOT/"01-weight-result.png"
PIXELS=ROOT/"02-pixels-result.png"
PASSPORT_SETTINGS=ROOT/"03-passport-settings.png"
PASSPORT_CROP=ROOT/"04-passport-crop.png"
PASSPORT=ROOT/"05-passport-result.png"

def hid_xy(px,py):
    return round(px/W*65535), round(py/H*65535)

async def tap(hid,px,py,after=.4):
    x,y=hid_xy(px,py)
    print("TAP",px,py,"=>",x,y,flush=True)
    await hid.send_touchscreen(TOUCHSCREEN_STATE_CONTACT,x,y,service_id=TOUCH_SERVICE_ID)
    await asyncio.sleep(.09)
    await hid.send_touchscreen(TOUCHSCREEN_STATE_RELEASE,x,y,service_id=TOUCH_SERVICE_ID)
    await asyncio.sleep(after)

async def screenshot(rsd,path):
    async with ScreenCaptureService(rsd) as sc:
        resp=await asyncio.wait_for(sc.capture_screenshot(),timeout=10)
        path.write_bytes(resp["image"])
        print("SCREENSHOT",path.name,len(resp["image"]),flush=True)

async def record_stream(rsd,ready,stop):
    RAW.unlink(missing_ok=True)
    sender_ip=rsd.service.address[0]
    packets=nals_count=frames=0
    last_seq=None
    fu=bytearray()
    async with DisplayService(rsd) as display:
        transport,receiver_ip=open_media_receiver(display,(4*1024*1024,1*1024*1024))
        try:
            ans=await asyncio.wait_for(
                display.start_video_stream(
                    receiver_ip=receiver_ip,
                    receiver_port=transport.port,
                    sender_ip=sender_ip,
                    display_id=1,
                ),timeout=15
            )
            cfg=ans["connection"].get("streamConfig",{})
            fps=cfg.get("Framerate") or 30
            FPS_FILE.write_text(str(fps))
            print("STREAM_STARTED","size",cfg.get("CustomWidth"),cfg.get("CustomHeight"),
                  "fps",fps,flush=True)
            ready.set()
            loop=asyncio.get_running_loop()
            deadline=loop.time()+MAX_DURATION
            with RAW.open("wb") as fp:
                while loop.time()<deadline and not stop.is_set():
                    try:
                        data=await asyncio.wait_for(transport.recv(65535),timeout=.75)
                    except asyncio.TimeoutError:
                        continue
                    if len(data)<12:
                        continue
                    pt=data[1]&0x7F
                    if 64<=pt<=95:
                        continue
                    marker=(data[1]>>7)&1
                    cc=data[0]&0x0F
                    hlen=12+cc*4
                    if data[0]&0x10:
                        if len(data)<hlen+4:
                            continue
                        ext_len=int.from_bytes(data[hlen+2:hlen+4],"big")
                        hlen+=4+ext_len*4
                    if hlen>=len(data):
                        continue
                    seq=int.from_bytes(data[2:4],"big")
                    if last_seq is not None and seq!=((last_seq+1)&0xFFFF):
                        fu.clear()
                    last_seq=seq
                    out=[]
                    depacketize_hevc(data[hlen:],fu,out)
                    for nal in out:
                        fp.write(b"\x00\x00\x00\x01"+nal)
                        nals_count+=1
                    packets+=1
                    if marker:
                        frames+=1
            print("STREAM_CAPTURED",packets,"packets",nals_count,"nals",
                  frames,"frames",RAW.stat().st_size,"bytes",flush=True)
        finally:
            with contextlib.suppress(Exception):
                await asyncio.wait_for(DisplayService.stop_all_streams(rsd),timeout=8)
            transport.close()

async def main():
    for p in (WEIGHT,PIXELS,PASSPORT_SETTINGS,PASSPORT_CROP,PASSPORT):
        p.unlink(missing_ok=True)

    async with UserspaceRsdTunnel(
        serial=UDID,autopair=False,remotepairing_fallback=False
    ) as rsd:
        print("RSD_OK",rsd.udid,rsd.product_version,flush=True)
        with contextlib.suppress(Exception):
            await asyncio.wait_for(DisplayService.stop_all_streams(rsd),timeout=8)

        ready=asyncio.Event()
        stop=asyncio.Event()
        rec=asyncio.create_task(record_stream(rsd,ready,stop))
        await asyncio.wait_for(ready.wait(),timeout=20)
        await asyncio.sleep(1.0)

        # Start the recording before the physical app launch.
        async with AppServiceService(rsd) as app:
            launched=await asyncio.wait_for(
                app.launch_application(BUNDLE,kill_existing=True),timeout=15
            )
            print("APP_LAUNCHED",launched,flush=True)
            await asyncio.sleep(2.4)

        async with UniversalHIDServiceService(rsd) as hid:
            # Select one neutral screenshot through Apple's system photo picker.
            await tap(hid,585,820,after=1.4)
            await tap(hid,190,1180,after=2.2)

            # 1) Maximum file size = 500 KB.
            await tap(hid,340,1020,after=.7)
            await tap(hid,585,1175,after=4.2)
            await screenshot(rsd,WEIGHT)
            await asyncio.sleep(1.8)

            # 2) Long side = 600 px.
            await tap(hid,585,400,after=1.2)
            await tap(hid,585,1175,after=4.2)
            await screenshot(rsd,PIXELS)
            await asyncio.sleep(1.8)

            # 3) Passport technical crop and export contract.
            await tap(hid,950,400,after=1.2)
            await screenshot(rsd,PASSPORT_SETTINGS)
            await tap(hid,585,1235,after=2.0)
            await screenshot(rsd,PASSPORT_CROP)
            await asyncio.sleep(1.0)
            await tap(hid,585,2310,after=4.5)
            await screenshot(rsd,PASSPORT)
            await asyncio.sleep(3.0)

        stop.set()
        await rec
        print("FLOW_DONE",flush=True)

asyncio.run(main())
