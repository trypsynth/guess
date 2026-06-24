const std = @import("std");

pub const Type = enum {
	ipv4,
	ipv6,

	pub fn displayName(self: Type) []const u8 {
		return switch (self) {
			.ipv4 => "IPv4 Address",
			.ipv6 => "IPv6 Address",
		};
	}
};

pub const Result = struct {
	type: Type,
	confidence: u8,
};

const Guesser = *const fn ([]const u8) ?Result;

const guessers = [_]Guesser{
	guessIpv4,
	guessIpv6,
};

fn guessIpv4(input: []const u8) ?Result {
	var port: u16 = 0;
	var confidence: u8 = 100;
	var ip_part = input;
	if (std.mem.findLast(u8, input, ":")) |colon_index| {
		ip_part = input[0..colon_index];
		port = std.fmt.parseUnsigned(u16, input[colon_index + 1 ..], 10) catch blk: {
			confidence = 60;
			break :blk 0;
		};
	}
	_ = std.Io.net.Ip4Address.parse(ip_part, port) catch {
		if (std.mem.countScalar(u8, ip_part, '.') != 3) return null;
		var octet_iter = std.mem.splitScalar(u8, ip_part, '.');
		while (octet_iter.next()) |octet| {
			const val = std.fmt.parseInt(usize, octet, 10) catch |err| switch (err) {
				error.InvalidCharacter => return null,
				error.Overflow => std.math.maxInt(usize),
			};
			if (val > 255) {
				confidence -|= 20;
				if (confidence == 0) return null;
			}
		}
	};
	return Result{ .type = .ipv4, .confidence = confidence };
}

fn guessIpv6(input: []const u8) ?Result {
	var ip_part = input;
	var port: u16 = 0;
	if (std.mem.startsWith(u8, input, "[")) {
		const closing = std.mem.find(u8, input, "]") orelse return null;
		ip_part = input[1..closing];
		if (input.len > closing + 1 and input[closing + 1] == ':') {
			port = std.fmt.parseUnsigned(u16, input[closing + 2 ..], 10) catch return null;
		}
	}
	if (std.mem.find(u8, ip_part, "%")) |pct_index| ip_part = ip_part[0..pct_index];
	_ = std.Io.net.Ip6Address.parse(ip_part, port) catch return null;
	return .{ .type = .ipv6, .confidence = 100 };
}

pub fn guess(allocator: std.mem.Allocator, input: []const u8) ![]Result {
	var results = std.ArrayList(Result).empty;
	errdefer results.deinit(allocator);
	for (guessers) |guesser| {
		if (guesser(input)) |result| try results.append(allocator, result);
	}
	return try results.toOwnedSlice(allocator);
}
