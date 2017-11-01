PROJECT = $(notdir $(CURDIR))
# Replace your toolchain directory here
TOOLCHAINDIR ?= /home/toan/Downloads/gcc-arm-none-eabi-5_4-2016q3/bin/
COMPILER ?= $(TOOLCHAINDIR)arm-none-eabi-
CC      = $(COMPILER)gcc
CP      = $(COMPILER)objcopy
AS      = $(COMPILER)as
LD      = $(COMPILER)ld
OD      = $(COMPILER)objdump
DEF+=USE_FULL_ASSERT
DEF+=USE_STDPERIPH_DRIVER
LIBRARY= ../../../
PERIPH_DRIVER= $(LIBRARY)/Libraries/STM32F4xx_StdPeriph_Driver
INC+= $(LIBRARY)/Libraries/CMSIS/Include
INC+= .
INC+= $(PERIPH_DRIVER)/inc
INC+= $(LIBRARY)/Libraries/CMSIS/ST/STM32F4xx/Include
INC+= $(LIBRARY)/Utilities/STM32F4-Discovery
SRC+= system_stm32f4xx.c
SRC+= main.c
SRC+= stm32f4xx_it.c
SRC+= $(PERIPH_DRIVER)/src/misc.c
SRC+= $(PERIPH_DRIVER)/src/stm32f4xx_gpio.c
SRC+= $(PERIPH_DRIVER)/src/stm32f4xx_rcc.c
STARTUP= $(LIBRARY)/Libraries/CMSIS/ST/STM32F4xx/Source/Templates/TrueSTUDIO/startup_stm32f4xx.s
LINKER= -TTrueSTUDIO/IO_Toggle/stm32_flash.ld
INCLUDE= $(patsubst %,-I%,$(INC))
DEFINE= $(patsubst %,-D%,$(DEF))
$(shell mkdir -p Output)
$(shell mkdir -p Deps)
OUTPUT=Output
DEPDIR = Deps
df = $(DEPDIR)/$(*F)
OBJS+=$(patsubst %.c,%.o,$(SRC))
OBJS+=$(patsubst %.s,%.o,$(STARTUP))
OBJECTS = $(addprefix $(OUTPUT)/, $(OBJS))
CFLAGS+=$(INCLUDE)
CFLAGS+=$(DEFINE)
CFLAGS+=-g
CFLAGS+=-mcpu=cortex-m4 -mthumb
CFLAGS+=-MD
LDFLAGS+=$(LINKER)
LDFLAGS+=$(CFLAGS)
LDFLAGS+=-lc
LDFLAGS+=-lrdimon
ASFLAGS+=-g
ASFLAGS+=-mcpu=cortex-m4 -mthumb
$(OUTPUT)/%.o: %.s Makefile
	@mkdir -p $(@D)
	@$(AS) $(ASFLAGS) -mthumb $< -o $@
	@echo "AS ${@}"
$(OUTPUT)/%.o: %.c Makefile
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@
	@echo "CC ${@}"
	@cp $(OUTPUT)/$*.d $(df).P; \
	sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
	-e '/^$$/ d' -e 's/$$/ :/' < $(OUTPUT)/$*.d >> $(df).P; \
	rm -f $(OUTPUT)/$*.d
-include $(SRCS:%.c=$(DEPDIR)/%.P)
all: $(PROJECT).elf $(PROJECT).bin
$(PROJECT).elf : $(OBJECTS)
	@mkdir -p $(@D)
	@$(CC) $^ $(LDFLAGS) $(LIBS) -o $@
	@echo "CC ${@}"
$(PROJECT).bin : $(PROJECT).elf
	@mkdir -p $(@D)
	$(CP) -O binary $(PROJECT).elf $(PROJECT).bin
	
clean: 
	@rm -f $(OBJECTS) $(PROJECT).bin $(DEPDIR)/*.P $(PROJECT).elf
	@rm -R $(OUTPUT) $(DEPDIR)
flash:
	@st-flash write $(PROJECT).bin 0x8000000