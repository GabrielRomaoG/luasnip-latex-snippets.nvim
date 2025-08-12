--[
-- LuaSnip Conditions
--]

local M = {}

-- math / not math zones

local function _last_occurrence(text, pat, upto)
  local last_s
  local init = 1
  while true do
    local s, e = string.find(text, pat, init)
    if not s or s > upto then break end
    last_s = s
    init = e + 1
  end
  return last_s
end

local function _next_unpaired_dollar_after(text, from_pos)
  local init = from_pos
  while true do
    local s, e = string.find(text, "%$", init)
    if not s then return nil end
    local prev = (s > 1) and text:sub(s-1, s-1) or ""
    local nxt  = text:sub(s+1, s+1)
    -- Skip if part of $$ or escaped \$
    if prev ~= "$" and nxt ~= "$" and prev ~= "\\" then
      return s, e
    end
    init = e + 1
  end
end

local function _last_unpaired_dollar_before(text, upto)
  local last_s
  local init = 1
  while true do
    local s, e = string.find(text, "%$", init)
    if not s or s > upto then break end
    local prev = (s > 1) and text:sub(s-1, s-1) or ""
    local nxt  = text:sub(s+1, s+1)
    if prev ~= "$" and nxt ~= "$" and prev ~= "\\" then
      last_s = s
    end
    init = e + 1
  end
  return last_s
end

local function in_mathzone_markdown()
  local row1, col = unpack(vim.api.nvim_win_get_cursor(0))
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  if not lines or #lines == 0 then return false end

  local buf = table.concat(lines, "\n")

  -- Absolute cursor position in the buffer string (1-based for string.find)
  local pos = 0
  for i = 1, row1 - 1 do
    pos = pos + #lines[i] + 1
  end
  pos = pos + col
  local upto = pos + 1

  -- Check $$...$$
  local last_dbl_before = _last_occurrence(buf, "%$%$", upto)
  if last_dbl_before then
    local next_dbl_after = string.find(buf, "%$%$", upto)
    if next_dbl_after then return true end
  end

  -- Check $...$ (ignore $$ and escaped \$)
  local last_single_before = _last_unpaired_dollar_before(buf, upto)
  if last_single_before then
    local next_single_after = _next_unpaired_dollar_after(buf, upto)
    if next_single_after then return true end
  end

  return false
end


function M.in_math()
    return vim.bo.filetype == "tex" and vim.fn["vimtex#syntax#in_mathzone"]() == 1
     or vim.bo.filetype == "markdown" and in_mathzone_markdown()
end

-- comment detection
function M.in_comment()
	return vim.fn["vimtex#syntax#in_comment"]() == 1
end

-- document class
function M.in_beamer()
	return vim.b.vimtex["documentclass"] == "beamer"
end

-- general env function
local function env(name)
	local is_inside = vim.fn["vimtex#env#is_inside"](name)
	return (is_inside[1] > 0 and is_inside[2] > 0)
end

function M.in_preamble()
	return not env("document")
end

function M.in_text()
	return env("document") and not M.in_math()
end

function M.in_tikz()
	return env("tikzpicture")
end

function M.in_bullets()
	return env("itemize") or env("enumerate")
end

function M.in_align()
	return env("align") or env("align*") or env("aligned")
end

function M.show_line_begin(line_to_cursor)
    return #line_to_cursor <= 3
end

return M
