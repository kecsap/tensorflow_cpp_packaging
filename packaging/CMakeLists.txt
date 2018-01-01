
CMAKE_MINIMUM_REQUIRED(VERSION 3.0 FATAL_ERROR)

PROJECT(DPKG_WRAPPER)

IF (NOT GIT_TAG)
  MESSAGE(FATAL_ERROR "GIT_TAG must be set")
ENDIF ()

IF (NOT GIT_COMMIT)
  MESSAGE(FATAL_ERROR "GIT_COMMIT must be set")
ENDIF ()

IF (NOT GIT_DATE)
  MESSAGE(FATAL_ERROR "GIT_DATE must be set")
ENDIF ()

IF (NOT PKG_SUFFIX)
  MESSAGE(FATAL_ERROR "PKG_SUFFIX must be set")
ENDIF ()

SET(TENSORFLOWCPP_VERSION ${GIT_TAG})
IF (${PKG_SUFFIX} STREQUAL "generic")
  SET(PKG_CONFLICTS tensorflow-cpp-optimized)
ELSE ()
  SET(PKG_CONFLICTS tensorflow-cpp-generic)
ENDIF ()

SET(TENSORFLOWCPP_INCLUDE_DIRS ${CMAKE_INSTALL_PREFIX}/include/tensorflow-cpp ${CMAKE_INSTALL_PREFIX}/include/tensorflow-cpp/external/nsync/public)

SET(TENSORFLOWCPP_LIBS -Wl,-rpath=${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp -L${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp
    -ltensorflow-core -Wl,--no-as-needed -lprotobuf-tf -Wl,--as-needed ${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp/libnsync-tf.a -ldl -lpthread)
SET(TENSORFLOWCPP_STATIC_LIBS -Wl,-rpath=${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp -L${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp
    -Wl,--whole-archive ${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp/libtensorflow-core-static.a ${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp/libprotobuf-tf-static.a -Wl,--no-whole-archive
    ${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp/libnsync-tf.a -ldl -lpthread)

CONFIGURE_FILE(TensorFlowCppConfig.cmake.in TensorFlowCppConfig.cmake @ONLY)
CONFIGURE_FILE(TensorFlowCppConfigVersion.cmake.in TensorFlowCppConfigVersion.cmake @ONLY)
CONFIGURE_FILE(debian/changelog.in debian/changelog @ONLY)
CONFIGURE_FILE(debian/control.in debian/control @ONLY)

INSTALL(DIRECTORY headers/Eigen headers/external headers/google headers/tensorflow headers/third_party headers/unsupported
        DESTINATION ${CMAKE_INSTALL_PREFIX}/include/tensorflow-cpp)
INSTALL(FILES libs/libnsync-tf.a libs/libprotobuf-tf.so libs/libprotobuf-tf-static.a libs/libtensorflow-core.so libs/libtensorflow-core-static.a
        DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp)
INSTALL(FILES TensorFlowCppConfig.cmake TensorFlowCppConfigVersion.cmake
        DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/cmake/tensorflow-cpp)
