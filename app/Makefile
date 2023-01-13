gen.icon:
	flutter pub run flutter_launcher_icons:main

build.deps:
	flutter pub get
	flutter pub run build_runner build --delete-conflicting-outputs

build.android: build.deps
	flutter build appbundle

build.apk: build.deps
	flutter build apk --release

build.ios: build.deps
	flutter build ipa --export-options-plist=ios/exportOptions.plist

build: build.android build.ios

clean:
	flutter clean
