project(test_data)

set(AUTOPILOT_DATA
    vcard.vcf
)

install(FILES ${AUTOPILOT_DATA}
    DESTINATION ${DIALER_APP_DIR}/vcards
)

