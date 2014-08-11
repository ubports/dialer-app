file(GLOB DIALOGS_QML_JS_FILES *.qml *.js)

# make the files visible on qtcreator
add_custom_target(dialer_dialogs_QMlFiles ALL SOURCES ${DIALOGS_QML_JS_FILES})

install(FILES ${DIALOGS_QML_JS_FILES} DESTINATION ${DIALER_APP_DIR}/Dialogs)

