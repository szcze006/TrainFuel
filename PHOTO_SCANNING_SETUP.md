# Enable TrainFUEL photo analysis (local setup)

The photo feature already uses OpenRouter and reads `MyApp/Secrets.plist` from the app bundle. An API key is **not** included in the repository.

1. Create your own private API key at https://openrouter.ai/settings/keys .
2. On your Mac, open Terminal in your TrainFuel project folder (the folder containing `trainFuel.xcodeproj`).
3. Run `bash setup-photo-scanning.sh`. Paste the key when asked. It won't appear on screen.
4. Open `trainFuel.xcodeproj` in Xcode and rebuild. If a missing-key error persists, confirm `MyApp/Secrets.plist` belongs to the MyApp target's bundle resources.
5. In the iPhone simulator, use **Choose Photo**. The simulator cannot use a real iPhone camera. On a compatible physical iPhone, **Take Photo** uses the camera.
6. OpenRouter may charge for requests. Photo nutrition estimates are approximate, not guaranteed.

Security: `MyApp/Secrets.plist` is listed in `.gitignore`; do not commit it or share it. The current app sends API requests directly from the device, so a bundled key is not secure for a production app. For production, move requests to a server endpoint to protect credentials.

The barcode lookup is a separate Open Food Facts integration and doesn't require this key.
