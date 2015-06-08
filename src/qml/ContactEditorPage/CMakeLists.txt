file(GLOB CONTACT_EDITOR_QML_JS_FILES *.qml *.js)

# make the files visible on qtcreator
add_custom_target(dialer_contacteditor_QMlFiles ALL SOURCES ${CONTACT_EDITOR_QML_JS_FILES})

install(FILES ${CONTACT_EDITOR_QML_JS_FILES} DESTINATION ${DIALER_APP_DIR}/ContactEditorPage)

