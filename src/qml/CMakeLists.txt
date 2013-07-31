file(GLOB QML_JS_FILES *.qml *.js)

# make the files visible on qtcreator
add_custom_target(dialer_app_QMlFiles ALL SOURCES ${QML_JS_FILES})

set(ASSETS_DIR assets)

install(FILES ${QML_JS_FILES} DESTINATION ${DIALER_APP_DIR})
install(DIRECTORY ${ASSETS_DIR} DESTINATION ${DIALER_APP_DIR})

add_subdirectory(DialerPage)
add_subdirectory(HistoryPage)
add_subdirectory(LiveCallPage)
add_subdirectory(VoicemailPage)
add_subdirectory(ContactsPage)
