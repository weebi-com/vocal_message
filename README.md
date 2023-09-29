> vocal_message fork

- lot of code duplication since i used recorder example for desktop
- I kept the supa cool effect for mobile, but twisted it using recorder example
- I do not understand the use of just_audio + audioplayers
  - it would be nice to stick to audioplayers for a lighter lib
- yet the goal is to go azure sync as fast as possible, so bear with all tech debt and grin
                      // niceToHave handle progress syncing

# Documentation
azureFolderFullPath = container + folderPath + direction
ex : /audio-test/jimmy_jo/uploads // where app-user's vocal message will be saved
ex : /audio-test/jimmy_jo/downloads // where admin should save vocal message replies

azure permissions
make sure to set a role with blob contributor

# Dependencies

The project makes use of the following open source packages

- [just_audio](https://pub.dev/packages/just_audio) - To interact with audio files from application document storage.
- [font_awesome_flutter](https://pub.dev/packages/font_awesome_flutter) - Font Awesome provides a great set of Icon to use in your application.
- [permission_handler](https://pub.dev/packages/permission_handler) - A package to handle audio/storage permissions from the user.
- [path_provider](https://pub.dev/packages/path_provider) - path_provider provides path to application document and cache storage directories to store application specific data.
- [record](https://pub.dev/packages/record) - Audio recorder from microphone to a given file path with multiple codecs, bit rate and sampling rate options.
- [flutter_vibrate](https://pub.dev/packages/flutter_vibrate) - A simple plugin to control haptic feedback on iOS and android.
- [lottie](https://pub.dev/packages/lottie) - To add lottie animation to the application.
