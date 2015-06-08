file(GLOB CONTACT_VIEW_QML_JS_FILES *.qml *.js)

# make the files visible on qtcreator
add_custom_target(dialer_contactviewpage_QMlFiles ALL SOURCES ${CONTACT_VIEW_QML_JS_FILES})

install(FILES ${CONTACT_VIEW_QML_JS_FILES} DESTINATION ${DIALER_APP_DIR}/ContactViewPage)

