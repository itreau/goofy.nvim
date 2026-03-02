local M = {}

local function get_editor_dims()
  return vim.o.lines, vim.o.columns
end

local positions = {
  top_left = function(w, h)
    return { row = 1, col = 1 }
  end,
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
  if opts.width then
    return opts.width
  end
  local max_len = 0
  for _, line in ipairs(lines) do
    if #line > max_len then
      max_len = #line
    end
  end
  return max_len
end

function M.open(lines, opts)
  opts = opts or {}

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

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

  if opts.color then
    for i = 0, height - 1 do
      vim.api.nvim_buf_add_highlight(buf, -1, opts.color, i, 0, -1)
    end
  end

  return buf, win
end

return M
