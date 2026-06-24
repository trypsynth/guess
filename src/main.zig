const std = @import("std");
const Cli = @import("Cli.zig");
const guessers = @import("guessers.zig");

pub fn main(init: std.process.Init) !void {
	const allocator = init.gpa;
	const cli = try Cli.parse(allocator, init.minimal.args);
	const results = try guessers.guess(allocator, cli.input);
	defer allocator.free(results);
	for (results) |result| {
		std.debug.print("{s}, {d}% confidence\n", .{ result.type.displayName(), result.confidence });
	}
}
