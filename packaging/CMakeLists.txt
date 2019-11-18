
CMAKE_MINIMUM_REQUIRED(VERSION 3.0 FATAL_ERROR)

PROJECT(DPKG_WRAPPER)

IF (NOT RELEASE_MODE)
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

  IF (NOT PKG_ARCH)
    MESSAGE(FATAL_ERROR "PKG_ARCH must be set")
  ENDIF ()

  SET(TENSORFLOWCPP_VERSION ${GIT_TAG})
  SET(PKG_CONFLICTS "")
  IF (${PKG_SUFFIX} STREQUAL "generic-cuda")
    SET(PKG_CONFLICTS tensorflow-cpp-optimized-cuda,tensorflow-cpp-rpi,tensorflow-cpp-generic,tensorflow-cpp-optimized,tensorflow-cpp-legacy)
  ELSEIF (${PKG_SUFFIX} STREQUAL "optimized-cuda")
    SET(PKG_CONFLICTS tensorflow-cpp-generic-cuda,tensorflow-cpp-rpi,tensorflow-cpp-generic,tensorflow-cpp-optimized,tensorflow-cpp-legacy)
  ELSEIF (${PKG_SUFFIX} STREQUAL "generic")
    SET(PKG_CONFLICTS tensorflow-cpp-optimized,tensorflow-cpp-rpi,tensorflow-cpp-generic-cuda,tensorflow-cpp-optimized-cuda,tensorflow-cpp-legacy)
  ELSEIF (${PKG_SUFFIX} STREQUAL "optimized")
    SET(PKG_CONFLICTS tensorflow-cpp-generic,tensorflow-cpp-rpi,tensorflow-cpp-generic-cuda,tensorflow-cpp-optimized-cuda,tensorflow-cpp-legacy)
  ELSEIF (${PKG_SUFFIX} STREQUAL "rpi")
    SET(PKG_CONFLICTS tensorflow-cpp-generic,tensorflow-cpp-optimized,tensorflow-cpp-generic-cuda,tensorflow-cpp-optimized-cuda,tensorflow-cpp-legacy)
  ELSEIF (${PKG_SUFFIX} STREQUAL "legacy")
    SET(PKG_CONFLICTS tensorflow-cpp-generic,tensorflow-cpp-optimized,tensorflow-cpp-generic-cuda,tensorflow-cpp-optimized-cuda,tensorflow-cpp-rpi)
  ENDIF ()

  IF (${PKG_SUFFIX} STREQUAL "generic" OR ${PKG_SUFFIX} STREQUAL "optimized" OR ${PKG_SUFFIX} STREQUAL "legacy")
    SET(EXTRA_LIBS "-ltf_protos_cc -fopenmp -lpng16 -lsqlite3 -lsnappy -lgif -ldouble-conversion -llmdb -lre2 -ljpeg -lz -lfarmhash -licuuc -ljsoncpp")
    SET(EXTRA_STATIC_LIBS "")
    SET(EXTRA_DEPS ", libdouble-conversion-dev, libfarmhash-dev, libre2-dev, libgif-dev, libpng-dev, libsqlite3-dev, libsnappy-dev, liblmdb-dev, libjpeg-dev, libicu-dev, libjsoncpp-dev")
  ELSEIF (${PKG_SUFFIX} STREQUAL "generic-cuda" OR ${PKG_SUFFIX} STREQUAL "optimized-cuda")
    SET(EXTRA_LIBS "")
    SET(EXTRA_STATIC_LIBS "")
    SET(EXTRA_DEPS ", libdouble-conversion-dev, libfarmhash-dev, libre2-dev, libgif-dev, libpng-dev, libsqlite3-dev, libsnappy-dev, liblmdb-dev, libjpeg-dev, libicu-dev, libjsoncpp-dev, libprotobuf-dev")
  ELSE ()
    SET(EXTRA_LIBS "")
    SET(EXTRA_STATIC_LIBS "${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp/libtf_protos_cc-static.a")
    SET(EXTRA_DEPS "")
  ENDIF ()

  SET(TENSORFLOWCPP_INCLUDE_DIRS ${CMAKE_INSTALL_PREFIX}/include/tensorflow-cpp ${CMAKE_INSTALL_PREFIX}/include/tensorflow-cpp/external/nsync/public)

  SET(ABSL_LIBRARY "")
  IF (NOT ${PKG_SUFFIX} STREQUAL "rpi")
    SET(ABSL_LIBRARY "${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp/libabsl.a")
  ENDIF ()
  SET(NSYNC_CPP_LIBRARY "")
  IF (NOT ${PKG_SUFFIX} STREQUAL "rpi")
    SET(NSYNC_CPP_LIBRARY ${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp/libnsync-cpp-tf.a)
  ENDIF ()

  SET(TENSORFLOWCPP_LIBS -Wl,-rpath=${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp -L${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp
      -ltensorflow-core -Wl,--no-as-needed -lprotobuf-tf ${ABSL_LIBRARY} ${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp/libtf_core_profiler.a
      ${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp/libnsync-tf.a ${NSYNC_CPP_LIBRARY}
      ${EXTRA_LIBS} -Wl,--as-needed -ldl -lpthread)
  SET(TENSORFLOWCPP_STATIC_LIBS -Wl,-rpath=${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp -L${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp
      -Wl,--whole-archive ${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp/libtensorflow-core-static.a ${EXTRA_STATIC_LIBS}
      ${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp/libtf_core_profiler.a
      ${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp/libprotobuf-tf-static.a -Wl,--no-whole-archive -Wl,--allow-multiple-definition
      ${ABSL_LIBRARY}
      ${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp/libnsync-tf.a ${NSYNC_CPP_LIBRARY}
      ${EXTRA_LIBS} -ldl -lpthread)

  # Override TENSORFLOWCPP_LIBS and TENSORFLOWCPP_STATIC_LIBS for CUDA version
  IF (${PKG_SUFFIX} STREQUAL "generic-cuda" OR ${PKG_SUFFIX} STREQUAL "optimized-cuda")
    SET(TENSORFLOWCPP_LIBS -Wl,-rpath=${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp -L${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp
      -ltensorflow_cc -lprotobuf)
    SET(TENSORFLOWCPP_STATIC_LIBS "")
  ENDIF ()

  CONFIGURE_FILE(TensorFlowCppConfig.cmake.in TensorFlowCppConfig.cmake @ONLY)
  CONFIGURE_FILE(TensorFlowCppConfigVersion.cmake.in TensorFlowCppConfigVersion.cmake @ONLY)
  CONFIGURE_FILE(debian/changelog.in debian/changelog @ONLY)
  CONFIGURE_FILE(debian/control.in debian/control @ONLY)
  CONFIGURE_FILE(debian/rules.in debian/rules @ONLY)
ENDIF ()

IF (${PKG_SUFFIX} STREQUAL "rpi")
  SET(EXTRA_INSTALL_LIBS "")
ELSEIF (${PKG_SUFFIX} STREQUAL "generic" OR ${PKG_SUFFIX} STREQUAL "optimized" OR ${PKG_SUFFIX} STREQUAL "legacy")
  SET(EXTRA_INSTALL_LIBS libs/libnsync-cpp-tf.a libs/libtf_protos_cc.so libs/libtf_protos_cc-static.a libs/libabsl.a libs/libtf_core_profiler.a)
ELSE ()
  SET(EXTRA_INSTALL_LIBS libs/libnsync-cpp-tf.a libs/libabsl.a)
ENDIF ()

SET(INSTALL_LIBS libs/libnsync-tf.a libs/libprotobuf-tf.so libs/libprotobuf-tf-static.a libs/libtensorflow-core.so libs/libtensorflow-core-static.a 
    ${EXTRA_INSTALL_LIBS})
IF (${PKG_SUFFIX} STREQUAL "generic-cuda" OR ${PKG_SUFFIX} STREQUAL "optimized-cuda")
  SET(INSTALL_LIBS libs/libtensorflow_cc.so libs/libtensorflow_cc.so.1)
ENDIF ()

INSTALL(DIRECTORY headers/absl headers/Eigen headers/google headers/tensorflow headers/third_party headers/unsupported
        DESTINATION ${CMAKE_INSTALL_PREFIX}/include/tensorflow-cpp)
INSTALL(FILES ${INSTALL_LIBS}
        DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/tensorflow-cpp)
INSTALL(FILES TensorFlowCppConfig.cmake TensorFlowCppConfigVersion.cmake
        DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/cmake/tensorflow-cpp)
