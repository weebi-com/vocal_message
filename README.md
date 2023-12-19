A package to sync vocal message to azure.


# features
- record audio and upload it to azure
- download audio replies from azure 
- allow user to cancel download/upload
- audio can be played/recorded when offline
- handle unsent files and allow user to send them later

# motivation
Lower the barrier for voice-based services.

# roadmap
- Add a back-office app to keep track of all vocals and to reply with ease
- Provide an AI speech-to-text model to support rollout of voice-based services in remote rural areas
- outside of scope : chat_box / chatting

# set-up & documentation 
## set-up azure
- create azure blob
- create container in azure blob
- create azure blob key with add, read, list permission
- azure permissions : to set a role with blob contributor
- azure file formats : only upload .wav audio file
- azureFolderFullPath = container + folderPath + direction, ex : 
	- /audio-test/jimmy_jo/sent_by_user // where app-user's vocal message will be saved
	- /audio-test/jimmy_jo/loaded_by_admin // where admin should save vocal message replies (.wav)

## set-up in app
- on android google play will require that you justify why ext. storage is needed

# caveat
- it is only possible to reply to a user through azure web console 
  - you will only see a user folder if they have sent at least one audio
  - drag and drop your audio in user folder and in the view set path : sent_by_user
  - user will need to update view to see the ready to download voice message

# backlog
## support needed
- split UI and logic to make it easier to integrate the package within exiting code
- split azure from UI to make it possible to use other cloud providers
- add more languages in locals to make this universal
- handle other types of files, such as __contacts__, photos and position
- check performance for x100 files and update accordingly

## niceToHave
- publish on pub.dev (migrating to sdk 3.0 for (recorder))
- notification 
- UI - use bin animation when deleting from mobile lockTimer
- UI - display syncing progress
- UI - while playing display audio waves 
  - I tried [voice_message_package](https://pub.dev/packages/voice_message_package) but it yielded unsatisfying result
    - see in for_later/amplitude.dart
    - check : https://pub.dev/packages/audio_waveforms
    - https://pub.dev/packages/flutter_audio_waveforms
- UI - while recording display audio amplitude using a [gauge chart](https://github.com/GeekyAnts/GaugesFlutter)
- UX - set a max duration to prevent users from uploading endless empty files
- UX - while playing be able to move audio cursor
- codeCourtesy - stick to audioplayers instead of just_audio + audioplayers ?
- codeCourtesy - integrate icon files directly in lib

- provide optionnal params to set in azure :
	- <Content-Encoding />
	- <Content-Language />

# disclaimer
- I kept the supa cool effect tap-release animation on mobile, but twisted it to remove chat
- also I updated recording process using recorder example
- I also used recorder example for desktop, which is easier with a mouse
- lot of code duplication there but the goal was to provide sync quickly

# build helpers
> in pubspec add and also add them in your own assets
assets:
    - assets/dustbin.json
    - assets/dustbin_grey.json
## android 
> build.gradle
minSdkVersion 21
 
> in manifest add
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.VIBRATE" />

> ([to avoid error "No signature of method:"](https://stackoverflow.com/questions/76067863/no-signature-of-method-in-flutter-project))
> in .pub-cache/hosted/pub.dev/audioplayers_android-3.0.2/android/build.gradle
> comment line 48-50 
    //lint {
    //    disable 'InvalidPackage'
    //}
## ios
> Runner.entitlements
<key>com.apple.security.device.audio-input</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.files.downloads.read-write</key>
<true/>

> info.plist
NSMicrophoneUsageDescription

## macos 
> podfile
platform :osx, '10.15'


> info.plist
> 
> macos/Runner/Release.entitlements
<key>com.apple.security.device.audio-input</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.files.downloads.read-write</key>
<true/>

# Dependencies
The project forked ruthlessly these projects : 

- [audio-chat](https://github.com/thecodepapaya/audio-chat) - Initial animation and audio rec
- [dart-azblob](https://github.com/kkazuo/dart-azblob) - To send/receive audio on/from azure, rewrote bits to pass http client and handle exception when user cancels upload/download

The project uses the following open source packages :

- [xml](https://pub.dev/packages/xml) - Parse azure blob info
- [connectivity_plus](https://pub.dev/packages/connectivity_plus) - check connectivity
- [internet_connection_checker](https://pub.dev/packages/internet_connection_checker) - check if internet is actually available

And these other open source packages, already used in audio-chat :

- [just_audio](https://pub.dev/packages/just_audio) - To interact with audio files from application document storage.
- [font_awesome_flutter](https://pub.dev/packages/font_awesome_flutter) - Font Awesome provides a great set of Icon to use in your application.
- [permission_handler](https://pub.dev/packages/permission_handler) - A package to handle audio/storage permissions from the user.
- [path_provider](https://pub.dev/packages/path_provider) - path_provider provides path to application document and cache storage directories to store application specific data.
- [record](https://pub.dev/packages/record) - Audio recorder from microphone to a given file path with multiple codecs, bit rate and sampling rate options.
- [flutter_vibrate](https://pub.dev/packages/flutter_vibrate) - A simple plugin to control haptic feedback on iOS and android.
- [lottie](https://pub.dev/packages/lottie) - To add lottie animation to the application.
