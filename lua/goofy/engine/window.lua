local M = {}

local ns = vim.api.nvim_create_namespace "goofy"
M.ns = ns

local function get_editor_dims()
  local lines = vim.o.lines or 24
  local cols = vim.o.columns or 80
  local usable_rows = lines - (vim.o.cmdheight or 0)
  local laststatus = vim.o.laststatus or 0
  if laststatus > 0 then usable_rows = usable_rows - 1 end
  local showtabline = vim.o.showtabline or 0
  if showtabline == 2 then
    usable_rows = usable_rows - 1
  elseif showtabline == 1 and vim.api.nvim_list_tabpages and #vim.api.nvim_list_tabpages() > 1 then
    usable_rows = usable_rows - 1
  end
  return usable_rows, cols
end

local positions = {
  top_left = function(w, h) return { row = 1, col = 1 } end,
  top_center = function(w, h)
    local _, cols = get_editor_dims()
    return { row = 1, col = math.floor((cols - w) / 2) }
  end,
  top_right = function(w, h)
    local _, cols = get_editor_dims()
    return { row = 1, col = cols - w - 2 }
  end,
  center = function(w, h)
    local rows, cols = get_editor_dims()
    return { row = math.floor((rows - h) / 2), col = math.floor((cols - w) / 2) }
  end,
  left_center = function(w, h)
    local rows, _ = get_editor_dims()
    return { row = math.floor((rows - h) / 2), col = 1 }
  end,
  right_center = function(w, h)
    local rows, cols = get_editor_dims()
    return { row = math.floor((rows - h) / 2), col = cols - w - 2 }
  end,
  bottom_left = function(w, h)
    local rows, _ = get_editor_dims()
    return { row = rows - h - 2, col = 1 }
  end,
  bottom_center = function(w, h)
    local rows, cols = get_editor_dims()
    return { row = rows - h - 2, col = math.floor((cols - w) / 2) }
  end,
  bottom_right = function(w, h)
    local rows, cols = get_editor_dims()
    return { row = rows - h - 2, col = cols - w - 2 }
  end,
}

local function calculate_width(lines, opts)
  if opts.width then return opts.width end
  local max_len = 0
  for _, line in ipairs(lines) do
    local len = vim.fn.strdisplaywidth(line)
    if len > max_len then max_len = len end
  end
  return max_len
end

function M.apply_highlights(buf, color, height)
  if not color then return end
  for i = 0, height - 1 do
    vim.api.nvim_buf_add_highlight(buf, ns, color, i, 0, -1)
  end
end

function M.render_frame(buf, lines, opts)
  opts = opts or {}
  local height = opts.height or #lines
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  M.apply_highlights(buf, opts.color, height)
end

function M.open(lines, opts)
  opts = opts or {}

  if opts.position and not positions[opts.position] then
    vim.notify(
      "Goofy: unknown position '" .. tostring(opts.position) .. "', defaulting to bottom_right",
      vim.log.levels.WARN
    )
  end

  local buf = vim.api.nvim_create_buf(false, true)
  M.render_frame(buf, lines, opts)

  local width = calculate_width(lines, opts)
  local height = opts.height or #lines

  local pos_fn = positions[opts.position] or positions.bottom_right
  local pos = pos_fn(width, height)

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = pos.row,
    col = pos.col,
    width = width,
    height = height,
    style = "minimal",
    border = opts.border or "rounded",
  })

  return buf, win
end

return M
