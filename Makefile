
SRC_DIR = Source
BIN_DIR = bin

ASM_SOURCES = $(wildcard $(SRC_DIR)/*.asm)
AVRASM2 = wine ~/bin/AvrAssembler2/avrasm2.exe

SOURCES = $(wildcard $(SRC_DIR)/*.c)
OBJECTS = $(SOURCES:.c=.o)

# Symbols used by the Assembly code but that are implemented in C
EXTERNAL_SYMBOLS = f_main c_main

kk2++.hex: bindir kk2++.elf $(OBJECTS)
	avr-gcc -Os -mmcu=atmega644p -DF_CPU=20000000 -nostartfiles -o $(BIN_DIR)/kk2++.elf $(BIN_DIR)/kk2++.asm.hex.bin.elf $(BIN_DIR)/*.c.o
	avr-objcopy -I elf32-avr -O ihex -j .text -j .data $(BIN_DIR)/kk2++.elf $(BIN_DIR)/kk2++.hex 

.PHONY: bindir
bindir:
	mkdir -p $(BIN_DIR)

kk2++.asm: $(ASM_SOURCES)
	$(AVRASM2) $(SRC_DIR)/$@ -fI -o $(BIN_DIR)/$@.hex -l $(BIN_DIR)/$@.lst -m $(BIN_DIR)/$@.map

kk2++.elf: kk2++.asm
	avr-objcopy -j .sec1 -I ihex -O binary $(BIN_DIR)/kk2++.asm.hex $(BIN_DIR)/kk2++.asm.hex.bin
	avr-objcopy --rename-section .data=.text,contents,alloc,load,readonly,code -I binary -O elf32-avr $(BIN_DIR)/kk2++.asm.hex.bin $(BIN_DIR)/kk2++.asm.hex.bin.elf

	avr-objdump -d $(BIN_DIR)/kk2++.asm.hex.bin.elf | python2 tools/extract-symbols-metadata.py $(BIN_DIR)/kk2++.asm.map $(EXTERNAL_SYMBOLS) > $(BIN_DIR)/kk2++.symtab

	cat $(BIN_DIR)/kk2++.symtab | tools/elf-add-symbol $(BIN_DIR)/kk2++.asm.hex.bin.elf

.c.o:
	avr-gcc -Os -mmcu=atmega644p -DF_CPU=20000000 -c $< -o $(BIN_DIR)/$(<F).o

flash: kk2++.hex
	/usr/share/arduino/hardware/tools/avrdude -C /usr/share/arduino/hardware/tools/avrdude.conf -patmega644p -cusbasp -Uflash:w:$(BIN_DIR)/kk2++.hex:i

.PHONY: clean
clean:
	rm -f bin/*
