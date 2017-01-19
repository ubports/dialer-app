file(GLOB ACCOUNT_SETTINGS_QML_JS_FILES *.qml *.js)

# make the files visible on qtcreator
add_custom_target(dialer__account_settings_QMlFiles ALL SOURCES ${ACCOUNT_SETTINGS_QML_JS_FILES})

install(FILES ${ACCOUNT_SETTINGS_QML_JS_FILES} DESTINATION ${DIALER_APP_DIR}/SettingsPage/AccountSettings)
