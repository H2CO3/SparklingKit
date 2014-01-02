SYSROOT = /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.7.sdk

CC = clang
LD = $(CC)

CFLAGS = -isysroot $(SYSROOT) -c -Wall -Wextra -std=c99 -O2 -flto -mmacosx-version-min=10.7 -D__MAC_OS_X_VERSION_MIN_REQUIRED=MAC_OS_X_VERSION_10_7
LDFLAGS = -isysroot $(SYSROOT) -dynamiclib -w -lobjc -lspn -framework Foundation -framework CoreFoundation -install_name /usr/local/lib/libSparklingKit.dylib

TARGET = libSparklingKit.dylib
OBJECTS = SPNContext.o SPNValue.o
HEADERS = SPNContext.h SPNValue.h SparklingKit.h

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^

%.o: %.m
	$(CC) $(CFLAGS) -o $@ $<

install: $(TARGET)
	mkdir -p $(SYSROOT)/usr/local/include/SparklingKit
	mkdir -p $(SYSROOT)/usr/local/lib
	cp $(HEADERS) $(SYSROOT)/usr/local/include/SparklingKit/
	cp $(TARGET) $(SYSROOT)/usr/local/lib/

clean:
	rm -f $(TARGET) $(OBJECTS)

.PHONY: all clean install
