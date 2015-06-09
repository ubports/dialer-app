project(test_data)

set(AUTOPILOT_DATA
    vcard.vcf
)

install(FILES ${AUTOPILOT_DATA}
    DESTINATION ${PYTHON_PACKAGE_DIR}/dialer_app/testdata/
)

