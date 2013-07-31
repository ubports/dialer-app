file(GLOB VOICEMAIL_QML_JS_FILES *.qml *.js)

# make the files visible on qtcreator
add_custom_target(dialer_voicemail_QMlFiles ALL SOURCES ${VOICEMAIL_QML_JS_FILES})

install(FILES ${VOICEMAIL_QML_JS_FILES} DESTINATION ${DIALER_APP_DIR}/VoicemailPage)

