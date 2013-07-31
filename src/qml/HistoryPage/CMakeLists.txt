file(GLOB HISTORY_QML_JS_FILES *.qml *.js)

# make the files visible on qtcreator
add_custom_target(dialer_history_QMlFiles ALL SOURCES ${HISTORY_QML_JS_FILES})

install(FILES ${HISTORY_QML_JS_FILES} DESTINATION ${DIALER_APP_DIR}/HistoryPage)

