AR?=		ar
CC?=		clang
CXX?=		clang++

ifeq ("$(TARGET)","")
TARGET:=	$(shell $(CXX) $(CXXFLAGS) -dumpmachine | sed -e 's/[0-9.]*$$//')
endif
SYS:=		$(shell echo "$(TARGET)" | awk -F- '{print $$3}')

CFLAGS+=	--target=$(TARGET)

ifeq ("$(SYS)","darwin")
SDKROOT:=	$(shell xcrun --sdk macosx --show-sdk-path)
AR:=		$(shell xcrun --sdk macosx --find $(AR))
CC:=		$(shell xcrun --sdk macosx --find $(CC))
CXX:=		$(shell xcrun --sdk macosx --find $(CXX))
CPPFLAGS+=	-isysroot $(SDKROOT)
CFLAGS+=	--sysroot=$(SDKROOT)
CXXFLAGS+=	--sysroot=$(SDKROOT)
LDFLAGS+=	--sysroot=$(SDKROOT)
CFLAGS+=	-mmacosx-version-min=10.9
CXXFLAGS+=	-mmacosx-version-min=10.9
LDFLAGS+=	--target=$(TARGET)
endif

ifeq ($(shell uname -s),Darwin)
DYLD_LIBRARY_PATH:=	$(shell pwd)/build/$(TARGET)/lib:$(DYLD_LIBRARY_PATH)
LUA:=				DYLD_LIBRARY_PATH="$(DYLD_LIBRARY_PATH)" luajit
else
LUA:=				luajit
endif
LUA_CPATH:=			$(shell pwd)/build/$(TARGET)/lib/?

.PHONY: lib
lib:
	sh build-mbedtls.sh

.PHONY: srt
srt: lib
	sh build-srt.sh

.PHONY: so
so: srt

.PHONY: check
check: srt.lua
	luacheck srt.lua

.PHONY: test
test: srt.lua so
	LUA_CPATH="$(LUA_CPATH)" $(LUA) srt.lua

.PHONY: cleanup
cleanup:
	rm -rf mbedtls-3.[0-9].[0-9]
	rm -rf srt-[0-9].[0-9].[0-9]

.PHONY: clean
clean: cleanup
	rm -rf build/*
