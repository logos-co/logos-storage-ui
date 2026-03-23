cmake_minimum_required(VERSION 3.16)

project(qml VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

########### DEPENDENCIES ###########

if(NOT DEFINED LOGOS_LIBLOGOS_ROOT AND DEFINED ENV{LOGOS_LIBLOGOS_ROOT})
    set(LOGOS_LIBLOGOS_ROOT "$ENV{LOGOS_LIBLOGOS_ROOT}")
endif()

if(NOT DEFINED LOGOS_CPP_SDK_ROOT AND DEFINED ENV{LOGOS_CPP_SDK_ROOT})
    set(LOGOS_CPP_SDK_ROOT "$ENV{LOGOS_CPP_SDK_ROOT}")
endif()

if(NOT DEFINED LOGOS_STORAGE_ROOT AND DEFINED ENV{LOGOS_STORAGE_ROOT})
    set(LOGOS_STORAGE_ROOT "$ENV{LOGOS_STORAGE_ROOT}")
endif()

if(NOT EXISTS "${LOGOS_LIBLOGOS_ROOT}/include/core/interface.h")
    message(FATAL_ERROR "logos-liblogos not found at ${LOGOS_LIBLOGOS_ROOT}. "
                        "Set LOGOS_LIBLOGOS_ROOT.")
endif()

if(NOT DEFINED LOGOS_DESIGN_SYSTEM_ROOT AND DEFINED ENV{LOGOS_DESIGN_SYSTEM_ROOT})
    set(LOGOS_DESIGN_SYSTEM_ROOT "$ENV{LOGOS_DESIGN_SYSTEM_ROOT}")
endif()

if(NOT EXISTS "${LOGOS_CPP_SDK_ROOT}/include/cpp/logos_api.h")
    message(FATAL_ERROR "logos-cpp-sdk not found at ${LOGOS_CPP_SDK_ROOT}. "
                        "Set LOGOS_CPP_SDK_ROOT.")
endif()

########### DEPENDENCIES END ###########

########### QML DEFINITION ###########

set(METADATA_JSON "${CMAKE_CURRENT_SOURCE_DIR}/../../metadata.json")
set(PLUGIN_UI_BUILD_DIR "${CMAKE_BINARY_DIR}/generated_code")

if(NOT EXISTS "${PLUGIN_UI_BUILD_DIR}/logos_sdk.cpp")
    find_program(LOGOS_CPP_GENERATOR logos-cpp-generator REQUIRED)
    file(MAKE_DIRECTORY "${PLUGIN_UI_BUILD_DIR}")
    execute_process(
        COMMAND env -u LD_LIBRARY_PATH "${LOGOS_CPP_GENERATOR}" --metadata "${METADATA_JSON}" --general-only --output-dir "${PLUGIN_UI_BUILD_DIR}"
        RESULT_VARIABLE _gen_result
    )
    if(NOT _gen_result EQUAL 0)
        message(FATAL_ERROR "logos-cpp-generator failed (exit code ${_gen_result})")
    endif()
endif()

# storage_module_api.cpp comes from the storage module's installed include dir
file(COPY "${LOGOS_STORAGE_ROOT}/include/"
    DESTINATION "${PLUGIN_UI_BUILD_DIR}"
    FILES_MATCHING PATTERN "storage_module_api.*"
)

list(APPEND SOURCES
    ${PLUGIN_UI_BUILD_DIR}/logos_sdk.cpp
)

# Create a library with the Logos SDK and generated sources to keep them separate
add_library(storage_generated STATIC
    ${PLUGIN_UI_BUILD_DIR}/logos_sdk.cpp
    ${PLUGIN_UI_BUILD_DIR}/storage_module_api.cpp
)

# Define the dependencies needed for storage_generated
find_library(LOGOS_SDK_LIB logos_sdk PATHS ${LOGOS_CPP_SDK_ROOT}/lib NO_DEFAULT_PATH REQUIRED)
target_link_libraries(storage_generated PUBLIC
    Qt6::Core
    Qt6::RemoteObjects
    ${LOGOS_SDK_LIB}
)

# Discover the required dependencies
find_package(Qt6 REQUIRED COMPONENTS Quick RemoteObjects)

# Standard project setup for Qt applications
qt_standard_project_setup(REQUIRES 6.8)

# Add the Qt Quick application executable
qt_add_executable(appqml
    main.cpp
)

# Use these required dependencies.
target_link_libraries(appqml PRIVATE
    Qt6::Quick
    Qt6::Qml
    storage_generated
)

# Define the qml module and the StorageBackend sources.
set_source_files_properties(MockBackend.qml PROPERTIES QML_SINGLETON TRUE)

qt_add_qml_module(appqml
    URI StorageBackend
    VERSION 1.0
    SOURCES
        ../StorageBackend.cpp
        ../StorageBackend.h
    QML_FILES
        StorageView.qml
        OnBoarding.qml
        Main.qml
        StartNode.qml
        LogosStorageTextField.qml
        LogosStorageButton.qml
        LogosStorageLayout.qml
        PortForwarding.qml
        ErrorToast.qml
        HealthIndicator.qml
        ModeSelector.qml
        AdvancedSetup.qml
        icons/DotIcon.qml
        icons/NodeStatusIcon.qml
        icons/GuideIcon.qml
        icons/AdvancedIcon.qml
        icons/UpnpIcon.qml
        icons/PortIcon.qml
        icons/StorageIcon.qml
        icons/PlayIcon.qml
        icons/StopIcon.qml
        icons/SettingsIcon.qml
        icons/UploadIcon.qml
        icons/DownloadIcon.qml
        icons/DeleteIcon.qml
        icons/ArcWidget.qml
        Card.qml
        DiskWidget.qml
        UploadWidget.qml
        PeersWidget.qml
        JsonEditor.qml
        SettingsPopup.qml
        ManifestTable.qml
        NodeWidget.qml
        Widgets.qml
        DebugPanel.qml
        Utils.js
        MockBackend.qml
        OnBoardingLayout.qml
        OnBoardingProgress.qml
        OnBoardingCard.qml
        OnBoardingContainer.qml
        VaultText.qml
        ManifestWidget.qml
        DownloadWidget.qml
        DiskActivityGraph.qml

        assets/bg.png
        assets/image.png
        assets/pdf.png
        assets/video.png
        assets/other.png
        assets/badge-alpha.png
        assets/alpha.png
        assets/arrow-right.png
        assets/arrow-left.png
        assets/hard-drive.png
        assets/folder-upload.png
        assets/close-circle.png
        assets/file-copy.png
        assets/file-copy-line.png
        assets/global.png
        assets/node-tree.png
        assets/settings.png
        assets/error.png
        assets/success.png
        assets/download.png
        assets/delete.png
        QML_FILES BottomTitle.qml
        QML_FILES DownloadFolder.qml
)

# Set up QML module directory for runtime
set(QML_THEME_DIR ${CMAKE_CURRENT_BINARY_DIR}/qml/Logos/Theme)
set(QML_CONTROLS_DIR ${CMAKE_CURRENT_BINARY_DIR}/qml/Logos/Controls)

# Copy QML module files to runtime directory
# Pure QML module - no library, just QML files + qmldir
add_custom_command(TARGET storage_generated POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory ${QML_THEME_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${LOGOS_DESIGN_SYSTEM_ROOT}/lib/Logos/Theme/ ${QML_THEME_DIR}/
    COMMAND ${CMAKE_COMMAND} -E make_directory ${QML_CONTROLS_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${LOGOS_DESIGN_SYSTEM_ROOT}/lib/Logos/Controls/ ${QML_CONTROLS_DIR}/
    COMMENT "Setting up Logos.Theme and Logos.Controls QML modules for the app"
)

########### QML DEFINITION END ###########

########### HEADERS ###########

target_include_directories(storage_generated PUBLIC
    "${PLUGIN_UI_BUILD_DIR}"
    "${PLUGIN_UI_BUILD_DIR}/include"
)

# Include directories
target_include_directories(storage_generated PUBLIC
    ${LOGOS_CPP_SDK_ROOT}/include
    ${LOGOS_CPP_SDK_ROOT}/include/cpp
    ${LOGOS_CPP_SDK_ROOT}/include/core
    ${PLUGIN_UI_BUILD_DIR}/include
)

# Import the application headers.
target_include_directories(appqml PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/..
)

########### HEADERS END ###########


message(STATUS "Qt Quick app configured successfully")
