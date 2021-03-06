PURPLE_PLUGIN_DIR=~/.purple/plugins
PIDGIN_DIR=./pidgin-2.11.0
PURPLE_PLUGIN_SRC_DIR=$(PIDGIN_DIR)/libpurple/plugins

LDIR=./lib
BDIR=./build
SDIR=./src
HDIR=./headers

LOMEMO_DIR=$(LDIR)/libomemo
LOMEMO_SRC=$(LOMEMO_DIR)/src
LOMEMO_BUILD=$(LOMEMO_DIR)/build
LOMEMO_FILES=$(LOMEMO_BUILD)/libomemo.o $(LOMEMO_BUILD)/libomemo_storage.o $(LOMEMO_BUILD)/libomemo_crypto.o

AXC_DIR=$(LDIR)/axc
AXC_SRC=$(AXC_DIR)/src
AXC_BUILD=$(AXC_DIR)/build
AXC_FILES=$(AXC_BUILD)/axc.o $(AXC_BUILD)/axc_store.o $(AXC_BUILD)/axc_crypto.o

AX_DIR=$(AXC_DIR)/lib/libaxolotl-c

FILES=$(LOMEMO_FILES) $(AXC_FILES)

HEADERS=-I$(HDIR)/jabber -I$(LOMEMO_SRC) -I$(AXC_SRC) -I$(AX_DIR)/src

PKGCFG_C=$(shell pkg-config --cflags glib-2.0 purple)  $(shell xml2-config --cflags)
PKGCFG_L=$(shell pkg-config --libs purple glib-2.0 sqlite3 mxml) $(shell xml2-config --libs) -L$(shell pkg-config --variable=plugindir purple) $(shell libgcrypt-config --libs)

CFLAGS=-std=c11 -Wall -Wstrict-overflow -D_XOPEN_SOURCE=700 -D_BSD_SOURCE $(PKGCFG_C) $(HEADERS)
LFLAGS=-pthread -ldl -lm $(PKGCFG_L) -ljabber -Wl,--whole-archive $(AX_DIR)/build/src/libaxolotl-c.a -Wl,--no-whole-archive


all: lurch

$(BDIR):
	mkdir -p build
	
axc: $(AXC_SRC)
	cd $(AXC_DIR)/lib/libaxolotl-c/ && mkdir -p build && cd build && cmake -DCMAKE_BUILD_TYPE=Debug .. && make
	cd $(AXC_DIR) && make axc-pic

libomemo: $(LOMEMO_SRC)
	cd $(LOMEMO_DIR) && make libomemo-conversations-pic
	
lurch: $(SDIR)/lurch.c axc libomemo $(BDIR)
	gcc $(CFLAGS) -fPIC -c $(SDIR)/lurch.c -o $(BDIR)/lurch.o
	gcc -fPIC -shared $(CFLAGS) $(BDIR)/lurch.o $(FILES) -o $(BDIR)/lurch.so $(LFLAGS)
	
install: $(BDIR)/lurch.so
	mv $(BDIR)/lurch.so $(PURPLE_PLUGIN_DIR)

.PHONY: clean
clean:
	rm -rf $(LOMEMO_BUILD)
	rm -rf $(AXC_BUILD)
	rm -rf $(AX_DIR)/build
	rm -rf $(BDIR)
