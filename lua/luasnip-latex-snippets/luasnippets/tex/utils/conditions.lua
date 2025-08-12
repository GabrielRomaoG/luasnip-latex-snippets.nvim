--[
-- LuaSnip Conditions
--]

local M = {}

-- math / not math zones

local function in_mathzone_markdown()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Count $$ delimiters before current line
  local dollar_block_count = 0
  for i = 1, row do
    local line = lines[i]
    -- match a line with only $$ (possibly with spaces)
    if line:match("^%s*%$%$%s*$") then
      dollar_block_count = dollar_block_count + 1
    end
  end

  -- If odd count, we're inside a $$ ... $$ block
  if dollar_block_count % 2 == 1 then
    return true
  end

  -- Inline math: check current line for odd number of $ before and after cursor
  local line = lines[row]
  local before = line:sub(1, col)
  local after = line:sub(col + 1)
  local before_count = select(2, before:gsub("%$", ""))
  local after_count = select(2, after:gsub("%$", ""))
  return before_count % 2 == 1 and after_count % 2 == 1
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
