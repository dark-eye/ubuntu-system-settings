include(../../common-project-config.pri)
include($${TOP_SRC_DIR}/common-vars.pri)

TEMPLATE = lib
TARGET = flight-mode

QML_SOURCES = \
    EntryComponent.qml

OTHER_FILES += \
    $${QML_SOURCES}

settings.files = flight-mode.settings
settings.path = $${PLUGIN_MANIFEST_DIR}
INSTALLS += settings

qml.files = $${QML_SOURCES}
qml.path = $${PLUGIN_QML_DIR}/$${TARGET}
INSTALLS += qml