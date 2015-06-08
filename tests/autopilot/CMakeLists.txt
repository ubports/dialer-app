set(AUTOPILOT_DIR dialer_app)


install(DIRECTORY ${AUTOPILOT_DIR}
    DESTINATION ${PYTHON_PACKAGE_DIR}
    )

add_custom_target(test-autopilot
    BUILD_DIR=${CMAKE_BINARY_DIR} autopilot3 run -v ${AUTOPILOT_DIR}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
