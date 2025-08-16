--[
-- LuaSnip Conditions
--]

local M = {}

-- math / not math zones

local function in_mathzone_markdown()
  local row1, col = unpack(vim.api.nvim_win_get_cursor(0))
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  if not lines or #lines == 0 then return false end

  local buf = table.concat(lines, "\n")

  -- Absolute cursor position (1-based for Lua patterns)
  local pos = 0
  for i = 1, row1 - 1 do
    pos = pos + #lines[i] + 1
  end
  pos = pos + col + 1 -- now fully 1-based index

  -- === $$...$$ check ===
  do
    local open_s, open_e = string.find(buf, "%$%$", 1)
    while open_s do
      local close_s, close_e = string.find(buf, "%$%$", open_e + 1)
      if close_s and pos > open_e and pos < close_s then
        return true
      end
      open_s, open_e = string.find(buf, "%$%$", close_e and close_e + 1 or (open_e + 1))
    end
  end

  -- === $...$ check (skip $$ and escaped \$) ===
  do
    local idx = 1
    while true do
      local s, e = string.find(buf, "%$", idx)
      if not s then break end
      local prev = (s > 1) and buf:sub(s-1, s-1) or ""
      local nxt  = buf:sub(e+1, e+1)

      if prev ~= "$" and nxt ~= "$" and prev ~= "\\" then
        -- found an opening $
        local cs, ce = string.find(buf, "%$", e + 1)
        while cs do
          local prev2 = (cs > 1) and buf:sub(cs-1, cs-1) or ""
          local nxt2  = buf:sub(ce+1, ce+1)
          if prev2 ~= "$" and nxt2 ~= "$" and prev2 ~= "\\" then
            -- found a valid closing $
            if pos > e and pos < cs then
              return true
            else
              break -- done with this pair
            end
          end
          cs, ce = string.find(buf, "%$", ce + 1)
        end
      end
      idx = e + 1
    end
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
