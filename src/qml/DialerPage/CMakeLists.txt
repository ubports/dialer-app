file(GLOB DIALER_QML_JS_FILES *.qml *.js)

# make the files visible on qtcreator
add_custom_target(dialer_dialer_QMlFiles ALL SOURCES ${DIALER_QML_JS_FILES})

install(FILES ${DIALER_QML_JS_FILES} DESTINATION ${DIALER_APP_DIR}/DialerPage)

