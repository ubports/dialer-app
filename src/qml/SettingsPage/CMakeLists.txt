file(GLOB SETTINGS_QML_JS_FILES *.qml *.js)

# make the files visible on qtcreator
add_custom_target(dialer_settings_QMlFiles ALL SOURCES ${SETTINGS_QML_JS_FILES})

install(FILES ${SETTINGS_QML_JS_FILES} DESTINATION ${DIALER_APP_DIR}/SettingsPage)

