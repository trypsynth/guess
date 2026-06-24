const std = @import("std");
const Self = @This();

const usage =
	\\Guess - quickly guess the type of input data.
	\\
	\\usage: guess [<input>] [<options>...]
	\\
	\\Options:
	\\  -h, --help Show this help and exit
	\\
;

input: []const u8 = "",

pub fn parse(allocator: std.mem.Allocator, raw_args: std.process.Args) !Self {
	var args = try raw_args.iterateAllocator(allocator);
	if (!args.skip()) return error.MissingProgramName;
	var cli = Self{};
	var seen_input = false;
	errdefer if (seen_input) allocator.free(cli.input);
	while (args.next()) |arg| {
		if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
			std.debug.print(usage, .{});
			return error.HelpShown;
		} else {
			if (seen_input) return error.TooManyArguments;
			cli.input = try allocator.dupe(u8, arg);
			seen_input = true;
		}
	}
	return cli;
}

pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
	if (self.input.len > 0) allocator.free(self.input);
}
