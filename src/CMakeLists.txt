set(DIALER_APP dialer-app)

set(dialer_app_HDRS
    dialerapplication.h
    )

set(dialer_app_SRCS
    dialerapplication.cpp
    main.cpp
    )

add_executable(${DIALER_APP}
    ${dialer_app_SRCS}
    )
qt5_use_modules(${DIALER_APP} Core DBus Gui Qml Quick)

include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}
    )

install(TARGETS ${DIALER_APP}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )

# Handle i18n in the desktop file
set(DESKTOP_FILE ${DIALER_APP}.desktop)
file(REMOVE ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE})
file(STRINGS ${DESKTOP_FILE}.in DESKTOP_FILE_CONTENTS)
foreach(LINE ${DESKTOP_FILE_CONTENTS})
    string(REGEX REPLACE "tr\\\(\"(.*)\"\\\)" "\\1" LINE "${LINE}")
    string(CONFIGURE "${LINE}" LINE)
    file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE} "${LINE}\n")
endforeach(LINE)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE}
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
    )

install(FILES "dialer-app.url-dispatcher"
    DESTINATION ${CMAKE_INSTALL_DATADIR}/url-dispatcher/urls
    )

add_subdirectory(qml)
