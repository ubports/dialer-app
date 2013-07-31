file(GLOB LIVECALL_QML_JS_FILES *.qml *.js)

# make the files visible on qtcreator
add_custom_target(dialer_livecall_QMlFiles ALL SOURCES ${LIVECALL_QML_JS_FILES})

install(FILES ${LIVECALL_QML_JS_FILES} DESTINATION ${DIALER_APP_DIR}/LiveCallPage)

