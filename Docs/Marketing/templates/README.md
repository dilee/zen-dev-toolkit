# Marketing screenshot templates

Composed 2880x1800 App Store marketing shots, rendered from HTML.

Regenerate after a UI change:

1. Capture panels from a Debug build (writes PNG to the app container tmp dir, path is printed):
   `ZenDevToolkit -ShowPanelOnLaunch 1 -CapturePanel 1 -DemoContent 1 -selectedTool <JSON|Base64|URL|Hash|UUID|Time|JWT> -CaptureAppearance <dark|light>`
2. Copy the captures next to these templates as `panel-<tool>-<appearance>.png`, and a wallpaper as `wallpaper.jpg`.
3. Render each template with a Chromium browser (use a browser/profile whose default page zoom is 100%):
   `"/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" --headless --disable-gpu --screenshot=out.png --window-size=1440,900 --force-device-scale-factor=2 --hide-scrollbars file://$PWD/hero.html`
