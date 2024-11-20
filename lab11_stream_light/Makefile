TOP_MODULE			:=	stream_light
TOP_NAME			:=	V$(TOP_MODULE)

VERILATOR			:=	verilator
VERILATOR_FLAGS		:= -MMD --build -sv -cc -O3 --x-assign fast --x-initial fast --noassert --trace

ROOT_DIR			:=	$(shell pwd)
CSRC_DIR			:=	$(ROOT_DIR)/csrc
VSRC_DIR			:=	$(ROOT_DIR)/vsrc
BUILD_DIR			:=	$(ROOT_DIR)/build
OBJ_DIR				:=	$(BUILD_DIR)/obj_dir

VSRCS				:=	$(shell find $(VSRC_DIR) -type f -name "*.v" -or -name "*.sv")
CSRCS				+=	$(shell find $(CSRC_DIR) -type f -name "*.c" -or -name "*.cc" -or -name "*.cpp")

INC_PATH			+=	$(OBJ_DIR)

INCFLAGS 			:= $(addprefix -I, $(INC_PATH))
CXXFLAGS 			+= $(INCFLAGS)

sim: $(BUILD_DIR)/$(TOP_NAME)
	@echo "Building $@"

$(BUILD_DIR)/$(TOP_NAME): $(VSRCS) $(CSRCS)
	@rm -rf $(OBJ_DIR)
	@mkdir -p $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $(TOP_MODULE) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) \
		-CFLAGS -DTOP_NAME=$(TOP_NAME) \
		--Mdir $(OBJ_DIR) --exe -o $(BUILD_DIR)/$(TOP_NAME)

run: $(BUILD_DIR)/$(TOP_NAME)
	@echo "Running $@"
	$(BUILD_DIR)/$(TOP_NAME)

clean:
	@rm -rf $(BUILD_DIR)

.PHONY: sim trace-run clean

