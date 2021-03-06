# CPLUFF

# XBMC expects it to be called libcpluff...
set(CMAKE_SHARED_MODULE_PREFIX "lib")

set(PACKAGE_VERSION "0.1.3")
set(CP_VERSION_MAJOR "0")
set(CP_VERSION_MINOR "1")
set(CP_VERSION_REV "3")

include_directories(BEFORE ${dependdir}/include)

include(CheckIncludeFiles)
include(CheckFunctionExists)
include(CheckSymbolExists)
include(CheckLibraryExists)

if(TARGET_COMMON_DARWIN)
  set(HAVE_CFLOCALECOPYCURRENT 1)
  set(HAVE_CFPREFERENCESCOPYAPPVALUE 1)
endif(TARGET_COMMON_DARWIN)

check_include_files(memory.h HAVE_MEMORY_H)
check_include_files(stdint.h HAVE_STDINT_H)
check_include_files(dlfcn.h HAVE_DLFCN_H)
check_function_exists(gettext HAVE_DCGETTEXT)
check_function_exists(dcgettext HAVE_DCGETTEXT)
check_function_exists(iconv HAVE_ICONV)
check_function_exists(stat HAVE_STAT)
if(TARGET_WIN32)
  find_library(CONFIG_LIBRARY_EXPAT libexpat PATHS ${dependdir}/lib NO_DEFAULT_LIB)
elseif(TARGET_POSIX)
  find_package(EXPAT REQUIRED)
  if(EXPAT_FOUND)
    include_directories(EXPAT_INCLUDE_DIRS)
  endif(EXPAT_FOUND)
endif(TARGET_WIN32)

set(CP_ABI_COMPATIBILITY "\"0.1\"")

# TODO: set these correctly for windows
if(TARGET_POSIX)
  set(CP_FNAMESEP_CHAR "'/'")
  set(CP_FNAMESEP_STR "\"/\"")
  set(CP_THREADS "\"Posix\"")
  set(CP_SHREXT "\"`test .$module = .yes && echo .so || echo .dylib`\"")
  set(DLOPEN_POSIX 1)
  if(TARGET_COMMON_DARWIN)
    set(CP_HOST "darwin")
  else(TARGET_COMMON_DARWIN)
    set(CP_HOST "linux")
  endif(TARGET_COMMON_DARWIN)
endif(TARGET_POSIX)

include_directories(BEFORE ${CMAKE_CURRENT_SOURCE_DIR} libcpluff)

if(TARGET_WIN32)
  add_definitions(-DCP_C_API=CP_EXPORT -DWIN32 -D_DEBUG -D_WINDOWS -D_USRDLL -D_CRT_SECURE_NO_WARNINGS -D_CRT_NONSTDC_NO_DEPRECATE)
  include_directories(lBEFORE libcpluff/win32)
else(TARGET_WIN32)
  add_definitions(-DCP_C_API=CP_EXPORT -DCP_HOST="${CP_HOST}" -DHAVE_CONFIG_H)
  configure_file(libcpluff/cpluffdef.h.in ${root}/lib/cpluff/libcpluff/cpluffdef.h)
  configure_file(config_plex.h.in ${root}/lib/cpluff/config.h)
endif(TARGET_WIN32)

set(libcpluff_srcs
  libcpluff/context.c
  libcpluff/cpluff.c
  kazlib/hash.c
  kazlib/list.c
  libcpluff/logging.c
  libcpluff/psymbol.c
  libcpluff/pscan.c
  libcpluff/ploader.c
  libcpluff/pinfo.c
  libcpluff/pcontrol.c
  libcpluff/serial.c
  libcpluff/util.c
)

if(CMAKE_C_COMPILER_ID STREQUAL "Clang")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-format")
endif(CMAKE_C_COMPILER_ID STREQUAL "Clang")

if(TARGET_WIN32)
  set(libcpluff_srcs ${libcpluff_srcs} libcpluff/thread_windows.c libcpluff/win32/dirent.c)
  add_library(cpluff SHARED ${libcpluff_srcs})
  target_link_libraries(cpluff ${CONFIG_LIBRARY_EXPAT})
  install(TARGETS cpluff RUNTIME DESTINATION ${RESOURCEPATH}/system LIBRARY DESTINATION ${RESOURCEPATH}/system COMPONENT RUNTIME)
else(TARGET_WIN32)
  set(libcpluff_srcs ${libcpluff_srcs} libcpluff/thread_posix.c)
  if(TARGET_COMMON_DARWIN)
    add_library(cpluff-${ARCH} MODULE ${libcpluff_srcs})
    set_target_properties(cpluff-${ARCH} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plex/${RESOURCEPATH}/system)
    if(USING_XCODE)
      set_target_properties(cpluff-${ARCH} PROPERTIES
                            LIBRARY_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR}/plex/Debug/${RESOURCEPATH}/system
                            LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO ${CMAKE_BINARY_DIR}/plex/RelWithDebInfo/${RESOURCEPATH}/system
                            LIBRARY_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR}/plex/Release/${RESOURCEPATH}/system
      )
    endif(USING_XCODE)
  elseif(TARGET_POSIX)
    add_library(cpluff-${ARCH} SHARED ${libcpluff_srcs})
    install(TARGETS cpluff-${ARCH} DESTINATION ${LIBPATH}/system COMPONENT RUNTIME)
  endif(TARGET_COMMON_DARWIN)
  target_link_libraries(cpluff-${ARCH} ${EXPAT_LIBRARIES})
endif(TARGET_WIN32)

