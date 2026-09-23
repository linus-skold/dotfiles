-- Description: Module to check and cache the latest version of Neovim from GitHub

local uv = vim.uv or vim.loop
local M = {} -- module table

local cache_file = vim.fn.stdpath("cache") .. "/.nvim_remote_version"
local one_day = 24 * 60 * 60 -- seconds

-- Read cached version
local function read_cache()
	local fd = uv.fs_open(cache_file, "r", 438)
	if not fd then
		return nil
	end
	local stat = uv.fs_fstat(fd)
	if not stat then
		uv.fs_close(fd)
		return nil
	end

	local age = os.time() - stat.mtime.sec
	if age > one_day then
		uv.fs_close(fd)
		return nil
	end

	local data = uv.fs_read(fd, stat.size, 0)
	uv.fs_close(fd)
	return data
end

-- Write cache
local function write_cache(version)
	local fd = uv.fs_open(cache_file, "w", 438)
	if not fd then
		return
	end
	uv.fs_write(fd, version, 0)
	uv.fs_close(fd)
end

-- Fetch remote version
local function fetch_remote_version()
	local result = vim.system(
		{ "curl", "-s", "https://api.github.com/repos/neovim/neovim/releases/latest" },
		{ text = true }
	)
		:wait()

	if result and result.stdout then
		local version = result.stdout:match('"tag_name":%s*"v([%d%.]+)"')
		if version then
			write_cache(version)
			return version
		end
	end
	return nil
end

-- Parse version string into table

local function parse_version(version)
	local major, minor, patch = version:match("(%d+)%.(%d+)%.(%d+)")
	return {
		major = tonumber(major),
		minor = tonumber(minor),
		patch = tonumber(patch),
	}
end

local function is_version_greater(v1, v2)
	if v1.major ~= v2.major then
		return v1.major > v2.major
	elseif v1.minor ~= v2.minor then
		return v1.minor > v2.minor
	else
		return v1.patch > v2.patch
	end
end

function M.get_latest()
	return read_cache() or fetch_remote_version()
end

function M.get_current()
	local v = vim.version()
	return string.format("%d.%d.%d", v.major, v.minor, v.patch)
end

function M.update_available()
	local remote_version = M.get_latest()
	if not remote_version then
		return false
	end

	local current_version = M.get_current()
	local remote_parsed = parse_version(remote_version)
	local current_parsed = parse_version(current_version)

	return is_version_greater(remote_parsed, current_parsed), remote_version
end

return M
