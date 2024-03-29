set(DIALER_APP dialer-app)

set(dialer_app_HDRS
    dialerapplication.h
    dialpadsearch.h
    contactutils.h
    )

set(dialer_app_SRCS
    dialerapplication.cpp
    dialpadsearch.cpp
    contactutils.cpp
    main.cpp
    )

add_executable(${DIALER_APP}
    ${dialer_app_SRCS}
    )
qt5_use_modules(${DIALER_APP} Core DBus Gui Qml Quick Contacts)

include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}
    )

install(TARGETS ${DIALER_APP}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )


# Handle i18n in the desktop file
configure_file(${DESKTOP_FILE}.in.in ${DESKTOP_FILE}.in)
add_custom_target(${DESKTOP_FILE} ALL
         COMMENT "Merging translations into ${DESKTOP_FILE}"
         COMMAND LC_ALL=C ${INTLTOOL_MERGE} -d -u ${CMAKE_SOURCE_DIR}/po ${DESKTOP_FILE}.in ${DESKTOP_FILE} >/dev/null
        )

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE}
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
    )

install(FILES "dialer-app.url-dispatcher"
    DESTINATION ${CMAKE_INSTALL_DATADIR}/url-dispatcher/urls
    )

add_subdirectory(qml)
