cmake_minimum_required (VERSION 3.15)

project(OpenHomePlayer CXX)

find_program(ACTOOL_EXECUTABLE actool HINTS "/usr/bin" "${OSX_DEVELOPER_ROOT}/usr/bin" REQUIRED)
find_program(IBTOOL ibtool HINTS "/usr/bin" "${OSX_DEVELOPER_ROOT}/usr/bin" REQUIRED)

find_library(AUDIO_TOOLBOX_LIBRARY AudioToolbox)
find_library(FOUNDATION_LIBRARY Foundation)
find_library(SYSTEM_CONFIGURATION_LIBRARY SystemConfiguration)
find_library(IOKIT_LIBRARY IOKit)
find_library(COCOA_LIBRARY Cocoa)

set(CMAKE_OSX_ARCHITECTURES "x86_64")
set(CMAKE_CXX_STANDARD 11)

add_compile_options("-stdlib=libc++")

add_definitions(-DDEFINE_LITTLE_ENDIAN)

enable_language(OBJCXX)

add_executable(OpenHomePlayer MACOSX_BUNDLE)
target_sources(OpenHomePlayer
   PRIVATE
   AppDelegate.mm
   ConfigPersistentStore.mm
   ConfigRamStore.cpp
   ControlPointProxy.cpp
   DriverOsx.cpp
   ExampleMediaPlayer.mm
   MediaPlayerIF.mm
   OpenHomePlayer.xcdatamodeld
   PcmHandler.cpp
   Prefs.mm
   RamStore.cpp
   UpdateCheck.cpp
   Volume.cpp
   main.m
)

set(OPEN_HOME_PLAYER_DEPENDENCIES
   ${AUDIO_TOOLBOX_LIBRARY}
   ${FOUNDATION_LIBRARY}
   ${SYSTEM_CONFIGURATION_LIBRARY}
   ${IOKIT_LIBRARY}
   ${COCOA_LIBRARY}
)

set(RESOURCES
   SoftPlayer
)
set_source_files_properties(
    ${RESOURCES}
    PROPERTIES
        MACOSX_PACKAGE_LOCATION Resources)

set(IMAGESETS
   menu
   menu-hilite
   )
set(LOGO_IMAGESETS
   OpenHomeLogo
   )

set(APPICON_NAME AppIcon)

set(IMAGE_ASSETS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Images.xcassets)
set(APPICONSET_DIR "${IMAGE_ASSETS_DIR}/${APPICON_NAME}.appiconset")

set(IMAGE_ASSETS
    ${APPICONSET_DIR}/Contents.json)

foreach(IMG IN LISTS IMAGESETS)
    set(IMG_DIR "${IMAGE_ASSETS_DIR}/${IMG}.imageset")
    list(APPEND IMAGE_ASSETS
        ${IMG_DIR}/icon_24.png
        ${IMG_DIR}/icon_48.png
        ${IMG_DIR}/Contents.json)
endforeach()

foreach(IMG IN LISTS LOGO_IMAGESETS)
    set(IMG_DIR "${IMAGE_ASSETS_DIR}/${IMG}.imageset")
    list(APPEND IMAGE_ASSETS
        ${IMG_DIR}/openhomelogo@2.png
        ${IMG_DIR}/Contents.json)
endforeach()

list(APPEND IMAGE_ASSETS
    ${APPICONSET_DIR}/openhomelogo@2-1.png
    )

set(COMPILED_IMAGE_ASSETS
    "${CMAKE_CURRENT_BINARY_DIR}/${APPICON_NAME}.icns"
    "${CMAKE_CURRENT_BINARY_DIR}/Assets.car")

add_custom_command(
    OUTPUT
        ${COMPILED_IMAGE_ASSETS}
        ${APPICON_NAME}.Info.plist
    COMMAND
        ${ACTOOL_EXECUTABLE}
        --output-format human-readable-text
        --notices
        --warnings
        --export-dependency-info ${CMAKE_CURRENT_BINARY_DIR}/assetcatalog_dependencies
        --output-partial-info-plist "${CMAKE_CURRENT_BINARY_DIR}/${APPICON_NAME}.Info.plist"
        --app-icon ${APPICON_NAME}
        --enable-on-demand-resources NO
        --development-region en
        --target-device mac
        #--minimum-deployment-target ${CMAKE_OSX_DEPLOYMENT_TARGET}
        --minimum-deployment-target 10.14.6
        --platform macosx
        --compile "${CMAKE_CURRENT_BINARY_DIR}/OpenHomePlayer.app/Contents/Resources"
        ${IMAGE_ASSETS_DIR}
        #--bundle-identifier com.openhome.OpenHomePlayer
        #--generate-objc-asset-symbols ${CMAKE_CURRENT_BINARY_DIR}/GeneratedAssetSymbols.h
        #--generate-asset-symbol-index "${CMAKE_CURRENT_BINARY_DIR}/GeneratedAssetSymbols-Index.plist"
    DEPENDS ${IMAGE_ASSETS}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

list(APPEND RESOURCES
    ${COMPILED_IMAGE_ASSETS})

set_source_files_properties(
    ${COMPILED_IMAGE_ASSETS}
    PROPERTIES
        MACOSX_PACKAGE_LOCATION Resources)

target_sources(OpenHomePlayer
    PRIVATE
        ${RESOURCES})

set(STORYBOARDS
   Base.lproj/Main.storyboard
)
foreach(sb ${STORYBOARDS})
   set(output $<TARGET_BUNDLE_DIR:OpenHomePlayer>/Contents/Resources/${sb}c)
  set(input  ${CMAKE_CURRENT_SOURCE_DIR}/${sb})
  add_custom_command(TARGET OpenHomePlayer POST_BUILD
    COMMAND
        ${IBTOOL}
        --errors
        --warnings
        --notices
        --module OpenHomePlayer
        --output-format
        human-readable-text
        --compile
        ${output}
        ${input}
    DEPENDS ${input}
    COMMENT "Compiling Storyboard ${sb}...")
endforeach()

target_sources(OpenHomePlayer
    PRIVATE
    ${STORYBOARDS})

target_include_directories(OpenHomePlayer PRIVATE ../../dependencies/Mac-x64/ohMediaPlayer/include ../../dependencies/Mac-x64/ohNet-Mac-x64-Release/include/ohnet ../../dependencies/Mac-x64/ohNetGenerated-Mac-x64-Release/include/ohnet ../../dependencies/Mac-x64/libressl/include)
target_link_directories(OpenHomePlayer PRIVATE ../../dependencies/Mac-x64/ohMediaPlayer/lib ../../dependencies/Mac-x64/ohNet-Mac-x64-Release/lib ../../dependencies/Mac-x64/ohNetGenerated-Mac-x64-Release/lib ../../dependencies/Mac-x64/libressl/lib)

target_link_libraries( OpenHomePlayer
   ${OPEN_HOME_PLAYER_DEPENDENCIES}
)

target_link_libraries(OpenHomePlayer
   ConfigUiTestUtils
ConfigUi
SourceUpnpAv
SourcePlaylist
SourceRadio
SourceRaop
SourceScd
SourceSongcast
Podcast
ohMediaPlayer
WebAppFramework
ohNetGeneratedProxies
ohNetCore
CodecAacFdk
CodecAacFdkAdts
CodecAacFdkBase
CodecAacFdkMp4
CodecAifc
CodecAiff
CodecAiffBase
CodecAlacApple
CodecAlacAppleBase
CodecDsdDff
CodecDsdDsf
CodecDsdRaw
CodecFlac
CodecMp3
CodecPcm
CodecVorbis
libOgg
CodecWav
   ohPipeline
   ssl
   crypto
)
set_target_properties( OpenHomePlayer PROPERTIES
   MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist"
)

