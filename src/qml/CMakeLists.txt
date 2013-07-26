file(GLOB QML_JS_FILES *.qml *.js)

set(QML_DIRS
    DialerPage
    HistoryPage
    LiveCallPage
    VoicemailPage
    ContactsPage
    )

set(ASSETS_DIR assets)

install(FILES ${QML_JS_FILES} DESTINATION ${DIALER_APP_DIR})
install(DIRECTORY ${QML_DIRS} DESTINATION ${DIALER_APP_DIR})
install(DIRECTORY ${ASSETS_DIR} DESTINATION ${DIALER_APP_DIR})
