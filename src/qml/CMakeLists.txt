file(GLOB QML_JS_FILES *.qml *.js)

# make the files visible on qtcreator
add_custom_target(dialer_app_QMlFiles ALL SOURCES ${QML_JS_FILES})

set(ASSETS_DIR assets)
set(MMI_DIR MMI)

install(FILES ${QML_JS_FILES} DESTINATION ${DIALER_APP_DIR})
install(DIRECTORY ${ASSETS_DIR} DESTINATION ${DIALER_APP_DIR})
install(DIRECTORY ${MMI_DIR} DESTINATION ${DIALER_APP_DIR})

add_subdirectory(DialerPage)
add_subdirectory(HistoryPage)
add_subdirectory(LiveCallPage)
add_subdirectory(ContactsPage)
add_subdirectory(Dialogs)
